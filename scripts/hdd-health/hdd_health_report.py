#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Coleta evidências SMART de HDDs para embasar anúncios de venda.

Somente leitura: chama `smartctl -x`, `lsblk`, `lsusb` e `uname`. O único comando que pede algo ao disco além de
leitura é `--start-self-test`, que só aciona o auto-teste do firmware (não altera dados).

Uso no host dos discos:  sudo python3 hdd_health_report.py --out ~/hdd-evidence
Simulação offline:       python3 hdd_health_report.py --dry-run --out /tmp/hdd-evidence
"""
from __future__ import annotations

import argparse
import csv
import dataclasses
import hashlib
import json
import os
import re
import socket
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import hdd_ficha

# HD de 18 TB atrás de bridge USB pode levar mais de um minuto só para girar.
SMARTCTL_TIMEOUT_SECONDS = 180
HOST_COMMAND_TIMEOUT_SECONDS = 20
# A VIA VL711 está no drivedb como "sat"; "sat,12" cobre bridges que rejeitam o CDB de 16 bytes.
# "auto" deixa o smartctl detectar o tipo (sem -d); só roda se os tipos SAT explícitos falharem.
DEVICE_TYPE_CANDIDATES = ("sat", "sat,12", "auto")
# Teste longo mais velho que isso (em horas ligado) deixa de contar como evidência recente para o anúncio.
EXTENDED_TEST_MAX_AGE_HOURS = 24 * 30
LIFETIME_HOURS_WRAP = 65536  # o log de auto-teste guarda as horas em 16 bits
FAILED_STATUS_CODES = range(3, 9)  # nibble alto do status ATA: 3 fatal, 4-8 falhas de teste (0 ok, 1-2 abortado)
EXIT_BIT_DISK_FAILING = 0b1000
EXIT_BIT_SELF_TEST_ERRORS = 0b1000_0000
SELF_TEST_KINDS = ("short", "long")
# Só /dev/sdX: os links by-id de USB colidem quando várias bridges usam o mesmo serial.
DEVICE_PATTERN = re.compile(r"^/dev/sd[a-z]+$")
HOST_COMMANDS = (
    ("uname -a", ("uname", "-a")),
    ("smartctl --version", ("smartctl", "--version")),
    ("lsblk", ("lsblk", "-o", "NAME,SIZE,MODEL,SERIAL,ROTA,TRAN")),
    ("lsusb -t", ("lsusb", "-t")),
)
CSV_FIELDS = (
    "name", "device", "usb_port", "transport", "smart_access", "wwn", "model", "serial", "firmware", "capacity_tb",
    "rpm", "power_on_hours",
    "power_cycles", "temperature_c", "reallocated", "pending", "uncorrectable", "reported_uncorrect", "crc_errors",
    "spin_retry", "load_cycles", "written_tb", "error_log_count", "extended_test_age_hours", "smartctl_exit_status",
    "verdict", "reasons",
)


class CollectionError(Exception):
    """Falha ao executar um comando externo ou ao obter dados SMART de um disco."""


@dataclasses.dataclass(frozen=True)
class SelfTest:
    kind: str
    status_code: int
    status_text: str
    lifetime_hours: int

    @property
    def passed(self) -> bool:
        return self.status_code == 0

    @property
    def failed(self) -> bool:
        # Abortado (1-2) ou em andamento (15) não é falha do disco; só conta o que terminou com erro.
        return self.status_code in FAILED_STATUS_CODES


@dataclasses.dataclass(frozen=True)
class Collection:
    device: str
    transport: str
    device_type: Optional[str]
    smart_json: Optional[dict]
    smart_text: str
    error: str = ""
    usb_port: str = ""


@dataclasses.dataclass(frozen=True)
class DiskReport:
    device: str
    transport: str
    smart_access: Optional[str]
    model: str = ""
    serial: str = ""
    firmware: str = ""
    wwn: str = ""
    usb_port: str = ""
    name: str = ""
    capacity_bytes: Optional[int] = None
    rpm: Optional[int] = None
    smart_passed: Optional[bool] = None
    power_on_hours: Optional[int] = None
    power_cycles: Optional[int] = None
    temperature_c: Optional[int] = None
    reallocated: Optional[int] = None
    pending: Optional[int] = None
    uncorrectable: Optional[int] = None
    reported_uncorrect: Optional[int] = None
    crc_errors: Optional[int] = None
    spin_retry: Optional[int] = None
    load_cycles: Optional[int] = None
    written_tb: Optional[float] = None
    error_log_count: Optional[int] = None
    extended_test_age_hours: Optional[int] = None
    smartctl_exit_status: Optional[int] = None
    failed_self_tests: tuple[str, ...] = ()
    verdict: str = ""
    reasons: tuple[str, ...] = ()


# --- execução de comandos ---

def run_command(args: tuple, timeout_seconds: int) -> subprocess.CompletedProcess:
    # smartctl devolve bitmask não-zero mesmo com dados válidos, então o código de saída não é checado aqui.
    # errors="replace": modelo/serial corrompidos pela bridge não podem derrubar a execução inteira.
    try:
        return subprocess.run(args, capture_output=True, encoding="utf-8", errors="replace",
                              timeout=timeout_seconds, check=False)
    except FileNotFoundError as error:
        raise CollectionError(f"comando não encontrado: {args[0]} (apt install smartmontools)") from error
    except subprocess.TimeoutExpired as error:
        raise CollectionError(f"timeout de {timeout_seconds}s em: {' '.join(args)}") from error


def smartctl_args(device: str, device_type: str, *flags: str) -> tuple:
    if device_type == "auto":
        return ("smartctl", *flags, device)
    return ("smartctl", *flags, "-d", device_type, device)


def discover_rotational_disks(lsblk_json: str) -> list[tuple[str, str]]:
    rows = json.loads(lsblk_json)["blockdevices"]
    return [
        (f"/dev/{row['name']}", row.get("tran") or "desconhecido")
        for row in rows
        if row.get("type") == "disk" and str(row.get("rota")).lower() in ("1", "true")
    ]


def has_smart_payload(smart_json: dict) -> bool:
    # Só a tabela de atributos prova que a bridge repassou o SMART ATA; "smart_status" sozinho engana.
    return bool(smart_json.get("ata_smart_attributes", {}).get("table"))


def smartctl_text(smart_json: dict) -> str:
    return "\n".join(smart_json.get("smartctl", {}).get("output", [])) + "\n"


def describe_attempt(device_type: str, result: Optional[subprocess.CompletedProcess], note: str = "") -> str:
    """Registra o que cada tentativa devolveu, para separar bridge/cabo/hub de disco ruim ao ler o .error.txt."""
    if result is None:
        return f"-d {device_type}: {note}"
    detail = [f"-d {device_type}: exit_status={result.returncode}"]
    try:
        messages = json.loads(result.stdout).get("smartctl", {}).get("messages", [])
        detail += [message.get("string", "") for message in messages]
    except json.JSONDecodeError:
        detail.append("saída não é JSON: " + result.stdout.strip()[:300])
    if result.stderr.strip():
        detail.append("stderr: " + result.stderr.strip()[:300])
    return "; ".join(detail)


def collect_one(device: str, transport: str) -> Collection:
    attempts = []
    for device_type in DEVICE_TYPE_CANDIDATES:
        # Uma chamada só: --json=o embute o texto original, então JSON e texto são do mesmo instante.
        try:
            result = run_command(smartctl_args(device, device_type, "-x", "--json=o"), SMARTCTL_TIMEOUT_SECONDS)
        except CollectionError as error:
            # Timeout num tipo não impede tentar o próximo (a bridge pode travar só com CDB de 16 bytes).
            attempts.append(describe_attempt(device_type, None, str(error)))
            continue
        try:
            smart_json = json.loads(result.stdout)
        except json.JSONDecodeError:
            attempts.append(describe_attempt(device_type, result))
            continue
        if has_smart_payload(smart_json):
            return Collection(device, transport, device_type, smart_json, smartctl_text(smart_json),
                              usb_port=usb_port_of(device))
        attempts.append(describe_attempt(device_type, result))
    return Collection(device, transport, None, None, "", "\n".join(attempts), usb_port_of(device))


def usb_port_of(device: str) -> str:
    sysfs_path = os.path.realpath(f"/sys/block/{Path(os.path.realpath(device)).name}")
    return hdd_ficha.usb_port_from_sysfs_path(sysfs_path)


def start_self_test(collection: Collection, kind: str) -> str:
    args = smartctl_args(collection.device, collection.device_type, "-t", kind)
    output = run_command(args, SMARTCTL_TIMEOUT_SECONDS).stdout
    began = "Testing has begun" in output
    return "teste iniciado" if began else "NÃO iniciou: " + (output.strip().splitlines() or ["sem saída"])[-1]


# --- parsing e veredito (funções puras) ---

def attribute_rows(smart_json: dict) -> list:
    return smart_json.get("ata_smart_attributes", {}).get("table", [])


def attribute_counts(smart_json: dict) -> dict:
    # raw.string já vem formatado pelo drivedb (ex.: "0" ou "8 (0 0 8)"); raw.value pode empacotar bytes altos.
    counts = {}
    for row in attribute_rows(smart_json):
        first_token = str(row.get("raw", {}).get("string", "")).split(" ", 1)[0]
        counts[row["id"]] = int(first_token) if first_token.isdigit() else row["raw"]["value"]
    return counts


def self_test_rows(smart_json: dict) -> list:
    # Com -x o smartctl lê o log estendido (GP log); o padrão só aparece como fallback.
    log = smart_json.get("ata_smart_self_test_log", {})
    return (log.get("extended") or log.get("standard") or {}).get("table", [])


def parse_self_tests(smart_json: dict) -> tuple[SelfTest, ...]:
    return tuple(
        SelfTest(
            kind=row["type"]["string"],
            status_code=row["status"]["value"] >> 4,
            status_text=row["status"]["string"],
            lifetime_hours=row.get("lifetime_hours", 0),
        )
        for row in self_test_rows(smart_json)
    )


def error_log_count(smart_json: dict) -> Optional[int]:
    log = smart_json.get("ata_smart_error_log", {})
    return (log.get("extended") or log.get("summary") or {}).get("count")


def newest_passed_extended_age(tests: tuple, power_on_hours: Optional[int]) -> Optional[int]:
    if power_on_hours is None:
        return None
    ages = [
        (power_on_hours - test.lifetime_hours) % LIFETIME_HOURS_WRAP
        for test in tests
        if "extended" in test.kind.lower() and test.passed
    ]
    return min(ages) if ages else None


def total_written_tb(smart_json: dict, counts: dict) -> Optional[float]:
    # Só o atributo 241 chamado Total_LBAs_Written está em LBAs; outros fabricantes usam GiB ou blocos de 32 MiB.
    names = {row["id"]: row.get("name") for row in attribute_rows(smart_json)}
    block_size = smart_json.get("logical_block_size")
    if names.get(241) != "Total_LBAs_Written" or block_size is None:
        return None
    return round(counts[241] * block_size / 1e12, 2)


def display_name(serial: str, names: dict) -> str:
    """Nome dado pelo dono (names.csv); sem ele, um nome estável derivado do serial."""
    return names.get(serial) or (f"HDD-{serial[-4:]}" if serial else "")


def parse_disk(collection: Collection, names: Optional[dict] = None) -> DiskReport:
    smart_json = collection.smart_json
    if smart_json is None:
        return DiskReport(collection.device, collection.transport, None, usb_port=collection.usb_port,
                          name=Path(collection.device).name, reasons=(collection.error,))
    names = names or {}
    counts = attribute_counts(smart_json)
    tests = parse_self_tests(smart_json)
    power_on_hours = smart_json.get("power_on_time", {}).get("hours")
    return DiskReport(
        device=collection.device,
        transport=collection.transport,
        smart_access=collection.device_type,
        model=smart_json.get("model_name", ""),
        serial=smart_json.get("serial_number", ""),
        firmware=smart_json.get("firmware_version", ""),
        wwn=hdd_ficha.format_wwn(smart_json.get("wwn")),
        usb_port=collection.usb_port,
        name=display_name(smart_json.get("serial_number", ""), names),
        capacity_bytes=smart_json.get("user_capacity", {}).get("bytes"),
        rpm=smart_json.get("rotation_rate"),
        smart_passed=smart_json.get("smart_status", {}).get("passed"),
        power_on_hours=power_on_hours,
        power_cycles=smart_json.get("power_cycle_count"),
        temperature_c=smart_json.get("temperature", {}).get("current"),
        reallocated=counts.get(5),
        pending=counts.get(197),
        uncorrectable=counts.get(198),
        reported_uncorrect=counts.get(187),
        crc_errors=counts.get(199),
        spin_retry=counts.get(10),
        load_cycles=counts.get(193),
        written_tb=total_written_tb(smart_json, counts),
        error_log_count=error_log_count(smart_json),
        extended_test_age_hours=newest_passed_extended_age(tests, power_on_hours),
        smartctl_exit_status=smart_json.get("smartctl", {}).get("exit_status"),
        failed_self_tests=tuple(test.status_text for test in tests if test.failed),
    )


def critical_reasons(report: DiskReport) -> list:
    reasons = []
    exit_status = report.smartctl_exit_status or 0
    if report.smart_passed is False or exit_status & EXIT_BIT_DISK_FAILING:
        reasons.append("SMART geral reprovado (disco reportado como falhando)")
    if (report.pending or 0) > 0:
        reasons.append(f"{report.pending} setores pendentes de realocação")
    if (report.uncorrectable or 0) > 0:
        reasons.append(f"{report.uncorrectable} setores incorrigíveis offline")
    if report.failed_self_tests or exit_status & EXIT_BIT_SELF_TEST_ERRORS:
        reasons.append("auto-teste com falha: " + (", ".join(report.failed_self_tests) or "ver log"))
    return reasons


def warning_reasons(report: DiskReport) -> list:
    reasons = []
    if (report.reallocated or 0) > 0:
        reasons.append(f"{report.reallocated} setores realocados")
    if (report.reported_uncorrect or 0) > 0:
        reasons.append(f"{report.reported_uncorrect} erros incorrigíveis reportados")
    if (report.crc_errors or 0) > 0:
        reasons.append(f"{report.crc_errors} erros de CRC (costuma ser cabo/bridge, não o disco)")
    if (report.error_log_count or 0) > 0:
        reasons.append(f"{report.error_log_count} entradas no log de erros ATA")
    if (report.spin_retry or 0) > 0:
        reasons.append(f"{report.spin_retry} retentativas de spin-up")
    return reasons


def classify(report: DiskReport) -> tuple[str, tuple[str, ...]]:
    if report.smart_access is None:
        return "SEM_DADOS", report.reasons or ("SMART inacessível por este caminho",)
    critical = critical_reasons(report)
    if critical:
        return "REPROVADO", tuple(critical)
    if None in (report.reallocated, report.pending, report.uncorrectable):
        return "SEM_DADOS", ("atributos SMART 5/197/198 ausentes: a bridge não repassou a tabela completa",)
    warnings = warning_reasons(report)
    if warnings:
        return "ATENCAO", tuple(warnings)
    age = report.extended_test_age_hours
    if age is None or age > EXTENDED_TEST_MAX_AGE_HOURS:
        return "APROVADO_SEM_TESTE_LONGO", ("nenhum teste longo recente registrado",)
    return "APROVADO", ()


def with_verdict(report: DiskReport) -> DiskReport:
    verdict, reasons = classify(report)
    return dataclasses.replace(report, verdict=verdict, reasons=reasons)


def mask_serial(serial: str) -> str:
    return "****" + serial[-4:] if serial else "(sem serial)"


def capacity_tb(report: DiskReport) -> Optional[float]:
    return round(report.capacity_bytes / 1e12, 1) if report.capacity_bytes else None


# --- escrita das evidências ---

def safe_filename(text: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]", "_", text)


def evidence_stem(report: DiskReport) -> str:
    # O nome do device entra para dois discos com o mesmo serial não se sobrescreverem.
    return f"{Path(report.device).name}_{safe_filename(report.serial or 'sem-serial')}"


def cell(value: object) -> str:
    return "n/d" if value is None else str(value).replace("|", "/")


def markdown_summary(reports: list, generated_at: datetime, hostname: str, simulated: bool) -> str:
    lines = [
        f"# Saúde dos HDDs — {hostname}",
        f"Gerado em {generated_at.isoformat(timespec='seconds')}",
    ]
    if simulated:
        lines.append("**SIMULAÇÃO (--dry-run): dados fictícios, não usar em anúncio.**")
    lines += [
        "",
        "| Nome | Disco | Modelo | TB | Horas ligado | Realoc. | Pendentes | CRC | Teste longo (h atrás) | Acesso "
        "| Veredito |",
        "|---|---|---|---|---|---|---|---|---|---|---|",
    ]
    for report in reports:
        columns = (report.name, mask_serial(report.serial), report.model, capacity_tb(report), report.power_on_hours,
                   report.reallocated, report.pending, report.crc_errors, report.extended_test_age_hours,
                   report.smart_access, report.verdict)
        lines.append("| " + " | ".join(cell(column) for column in columns) + " |")
    lines += [
        "",
        "## Como reproduzir",
        "`sudo smartctl -x -d <Acesso> /dev/sdX`, com o valor da coluna Acesso. Os arquivos `*.smart.json` e "
        "`*.smart.txt` desta pasta são a saída bruta e trazem o **serial completo**: não os publique inteiros.",
        "Integridade: `sha256sum -c SHA256SUMS`. O arquivo só prova consistência interna; para valer como prova, "
        "publique o hash do próprio `SHA256SUMS` no anúncio.",
        "",
        "## Limites",
        "SMART é indicativo, não garantia: disco aprovado ainda pode falhar. Os números vêm do firmware do disco, "
        "lidos através de uma bridge USB-SATA; quando a bridge não repassa SMART o veredito é SEM_DADOS. Falha de "
        "auto-teste registrada no log (mesmo antiga) mantém o disco REPROVADO.",
    ]
    detailed = [report for report in reports if report.reasons]
    if detailed:
        lines += ["", "## Motivos"]
        lines += [f"- {mask_serial(report.serial)} ({report.device}): {'; '.join(report.reasons)}"
                  for report in detailed]
    return "\n".join(lines) + "\n"


def write_text(path: Path, content: str) -> None:
    with path.open("w", encoding="utf-8") as text_file:
        text_file.write(content)


def write_csv(path: Path, reports: list) -> None:
    with path.open("w", encoding="utf-8-sig", newline="") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=CSV_FIELDS, extrasaction="ignore")
        writer.writeheader()
        for report in reports:
            row = dataclasses.asdict(report)
            row["capacity_tb"] = capacity_tb(report)
            row["reasons"] = "; ".join(report.reasons)
            writer.writerow(row)


def write_checksums(out_dir: Path) -> None:
    lines = [
        f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}"
        for path in sorted(out_dir.iterdir())
        if path.name != "SHA256SUMS"
    ]
    write_text(out_dir / "SHA256SUMS", "\n".join(lines) + "\n")


def write_ficha(out_dir: Path, stem: str, report: DiskReport, collection: Collection, json_digest: str,
                generated_at: datetime, mask_ids: bool) -> None:
    lines = hdd_ficha.ficha_lines(report, collection.smart_json, parse_self_tests(collection.smart_json),
                                  generated_at, socket.gethostname(), json_digest, mask_ids)
    svg_path = out_dir / f"{stem}.ficha.svg"
    write_text(svg_path, hdd_ficha.ficha_svg(lines, report.verdict))
    hdd_ficha.try_convert_to_png(svg_path)


def write_evidence(out_dir: Path, collections: list, reports: list, host_info: str, generated_at: datetime,
                   simulated: bool, mask_ids: bool = False) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for collection, report in zip(collections, reports):
        stem = evidence_stem(report)
        if collection.smart_json is None:
            write_text(out_dir / f"{stem}.error.txt", collection.error + "\n")
            continue
        json_text = json.dumps(collection.smart_json, indent=2)
        write_text(out_dir / f"{stem}.smart.json", json_text)
        write_text(out_dir / f"{stem}.smart.txt", collection.smart_text)
        write_ficha(out_dir, stem, report, collection, hashlib.sha256(json_text.encode("utf-8")).hexdigest(),
                    generated_at, mask_ids)
    write_text(out_dir / "host.txt", host_info)
    write_csv(out_dir / "summary.csv", reports)
    write_text(out_dir / "summary.md", markdown_summary(reports, generated_at, socket.gethostname(), simulated))
    write_checksums(out_dir)


def capture_host_info() -> str:
    sections = []
    for title, args in HOST_COMMANDS:
        try:
            output = run_command(args, HOST_COMMAND_TIMEOUT_SECONDS).stdout
        except CollectionError as error:
            output = f"indisponível: {error}\n"
        sections.append(f"$ {title}\n{output}")
    return "\n".join(sections)


# --- simulação (--dry-run) ---

def simulated_smart(serial: str, power_on_hours: int, pending_sectors: int,
                    test: Optional[tuple[int, int]] = None, log_key: str = "extended") -> dict:
    """`test` = (byte de status ATA, lifetime_hours) de um auto-teste estendido; None = sem teste."""
    names = {5: "Reallocated_Sector_Ct", 197: "Current_Pending_Sector", 198: "Offline_Uncorrectable",
             199: "UDMA_CRC_Error_Count"}
    values = {5: 0, 197: pending_sectors, 198: 0, 199: 0}
    attributes = [{"id": attr_id, "name": names[attr_id], "raw": {"value": values[attr_id],
                                                                    "string": str(values[attr_id])}}
                  for attr_id in names]
    tests = []
    if test is not None:
        status_byte, lifetime_hours = test
        tests.append({
            "type": {"string": "Extended offline"},
            "status": {"value": status_byte, "string": f"status 0x{status_byte:02x}"},
            "lifetime_hours": lifetime_hours,
        })
    return {
        "model_name": "SIMULATED HDD 18TB",
        "serial_number": serial,
        "wwn": {"naa": 5, "oui": 0xCCA, "id": 0x1234ABCD5},
        "firmware_version": "SIM1",
        "user_capacity": {"bytes": 18_000_207_937_536},
        "rotation_rate": 7200,
        "smart_status": {"passed": True},
        "power_on_time": {"hours": power_on_hours},
        "power_cycle_count": 120,
        "temperature": {"current": 34},
        "smartctl": {"exit_status": 0, "output": ["(texto simulado)"]},
        "ata_smart_attributes": {"table": attributes},
        "ata_smart_self_test_log": {log_key: {"table": tests}},
        "ata_smart_error_log": {"extended": {"count": 0}},
    }


def simulated_collections() -> list:
    healthy = simulated_smart("SIMULATED0001", 30_000, 0, test=(0, 29_990))
    degraded = simulated_smart("SIMULATED0002", 42_000, 8)
    return [
        Collection("/dev/sdx", "usb", "sat", healthy, "(texto simulado)\n", usb_port="4-4.1.1"),
        Collection("/dev/sdy", "usb", "sat", degraded, "(texto simulado)\n", usb_port="4-4.1.2"),
        Collection("/dev/sdz", "usb", None, None, "", "-d sat: Unknown USB bridge (simulado)"),
    ]


# --- orquestração ---

def parse_args(argv: list) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", default="hdd-evidence", help="pasta base das evidências (padrão: ./hdd-evidence)")
    parser.add_argument("--dry-run", action="store_true", help="simula com dados fictícios; não toca em disco nenhum")
    parser.add_argument("--limit", type=int, default=0, help="processa só os N primeiros discos (0 = todos)")
    parser.add_argument("--devices", nargs="*", default=[], help="discos explícitos (padrão: todos os rotacionais)")
    parser.add_argument("--names", default="", help="CSV serial,nome com os nomes que você deu aos discos")
    parser.add_argument("--mask-ids", action="store_true",
                        help="mascara serial e WWN nas fichas (use ao postar a imagem; o log bruto segue completo)")
    parser.add_argument("--start-self-test", choices=SELF_TEST_KINDS,
                        help="só dispara o auto-teste do firmware (exige --devices) e sai; rode o relatório depois")
    return parser.parse_args(argv)


def load_names(path: str) -> dict:
    if not path:
        return {}
    try:
        with open(path, encoding="utf-8-sig", newline="") as names_file:
            return {row["serial"].strip(): row["nome"].strip() for row in csv.DictReader(names_file)}
    except (OSError, KeyError) as error:
        raise CollectionError(f"--names inválido (CSV com colunas serial,nome): {error}") from error


def validated_devices(devices: list) -> list[tuple[str, str]]:
    unique = {}
    for device in devices:
        if not DEVICE_PATTERN.match(device) or not Path(device).exists():
            raise CollectionError(f"dispositivo inválido ou inexistente: {device}")
        unique[os.path.realpath(device)] = device
    return [(device, "desconhecido") for device in unique.values()]


def select_devices(args: argparse.Namespace) -> list[tuple[str, str]]:
    if args.devices:
        devices = validated_devices(args.devices)
    else:
        result = run_command(("lsblk", "-J", "-d", "-o", "NAME,TYPE,ROTA,TRAN"), HOST_COMMAND_TIMEOUT_SECONDS)
        if result.returncode != 0:
            raise CollectionError(f"lsblk falhou: {result.stderr.strip()}")
        devices = discover_rotational_disks(result.stdout)
    return devices[: args.limit] if args.limit else devices


def collect_all(devices: list) -> list[Collection]:
    collections = []
    for device, transport in devices:
        try:
            collection = collect_one(device, transport)
        except CollectionError as error:
            collection = Collection(device, transport, None, None, "", str(error))
        access = f"SMART via -d {collection.device_type}" if collection.device_type else collection.error
        print(f"{device}: {access}", flush=True)
        collections.append(collection)
    return collections


def run_self_tests(collections: list, kind: str) -> None:
    for collection in collections:
        if collection.device_type is None:
            print(f"{collection.device}: sem acesso SMART, teste não iniciado", flush=True)
            continue
        try:
            print(f"{collection.device}: {start_self_test(collection, kind)}", flush=True)
        except CollectionError as error:
            print(f"{collection.device}: erro ao iniciar teste: {error}", flush=True)


def main(argv: list) -> int:
    args = parse_args(argv)
    if args.dry_run and args.start_self_test:
        print("--start-self-test não é simulado: não combine com --dry-run", file=sys.stderr)
        return 2
    if args.start_self_test and not args.devices:
        print("--start-self-test exige --devices explícito (evita testar todos os discos sem querer)", file=sys.stderr)
        return 2
    if not args.dry_run and os.geteuid() != 0:
        print("rode como root (sudo): o smartctl precisa de acesso direto ao dispositivo", file=sys.stderr)
        return 2
    try:
        collections = simulated_collections() if args.dry_run else collect_all(select_devices(args))
        if args.start_self_test:
            run_self_tests(collections, args.start_self_test)
            return 0
        host_info = "(simulação)\n" if args.dry_run else capture_host_info()
        names = load_names(args.names)
    except CollectionError as error:
        print(f"erro: {error}", file=sys.stderr)
        return 1
    generated_at = datetime.now(timezone.utc)
    reports = [with_verdict(parse_disk(collection, names)) for collection in collections]
    suffix = "-dryrun" if args.dry_run else ""
    out_dir = Path(args.out) / f"{socket.gethostname()}-{generated_at:%Y%m%d-%H%M%S}{suffix}"
    write_evidence(out_dir, collections, reports, host_info, generated_at, args.dry_run, args.mask_ids)
    print(f"evidências em {out_dir}")
    for report in reports:
        reasons = "; ".join(report.reasons)
        print(f"{report.device} {report.name} {mask_serial(report.serial)} -> {report.verdict} {reasons}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
