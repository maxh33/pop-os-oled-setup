"""Ficha de evidência por disco: identidade física + trecho do log SMART, em SVG (e PNG se houver conversor).

A ficha é a imagem que acompanha o anúncio. O serial e o WWN também estão impressos na etiqueta do disco, então
quem tem o disco na mão confere que a ficha é daquela unidade.
"""
from __future__ import annotations

import re
import shutil
import subprocess
from datetime import datetime
from pathlib import Path
from types import MappingProxyType
from typing import Optional
from xml.sax.saxutils import escape

FONT_SIZE = 15
CHAR_WIDTH = 9.0
LINE_HEIGHT = 20
PADDING = 16
MAX_ATTRIBUTE_ROWS = 30
MAX_SELF_TEST_ROWS = 5
PNG_CONVERT_TIMEOUT_SECONDS = 30
HEADER_TEXT_COLOR = "#ffffff"
VERDICT_COLORS = MappingProxyType({
    "APROVADO": "#1b7f3b",
    "APROVADO_SEM_TESTE_LONGO": "#6f8a1f",
    "ATENCAO": "#b7791f",
    "REPROVADO": "#b3261e",
    "SEM_DADOS": "#555555",
})
# (executável, argumentos); {svg} e {png} são substituídos pelos caminhos.
PNG_CONVERTERS = (
    ("rsvg-convert", ("-o", "{png}", "{svg}")),
    ("inkscape", ("{svg}", "-o", "{png}")),
    ("convert", ("{svg}", "{png}")),
)
# O link do sysfs de um disco USB contém o caminho da porta, ex.: .../usb4/4-4/4-4.1/4-4.1.3/4-4.1.3:1.0/host6/...
USB_PORT_PATTERN = re.compile(r"/(\d+-\d+(?:\.\d+)*):\d+\.\d+/")


def format_wwn(wwn: Optional[dict]) -> str:
    """NAA (4 bits) + OUI (24 bits) + ID (36 bits), igual ao 'LU WWN Device Id' impresso na etiqueta."""
    if not wwn:
        return ""
    return f"0x{wwn['naa']:x}{wwn['oui']:06x}{wwn['id']:09x}"


def usb_port_from_sysfs_path(sysfs_path: str) -> str:
    match = USB_PORT_PATTERN.search(sysfs_path)
    return match.group(1) if match else ""


def mask_value(value: str) -> str:
    return "*" * max(len(value) - 4, 0) + value[-4:]


def attribute_line(row: dict) -> str:
    raw_text = row.get("raw", {}).get("string", "")
    return (f"{row['id']:>3} {str(row.get('name', '?'))[:26]:<26} {row.get('value', ''):>5} "
            f"{row.get('worst', ''):>5} {row.get('thresh', ''):>4}  {raw_text}")


def ficha_lines(report, smart_json: dict, self_tests: tuple, generated_at: datetime, hostname: str,
                json_digest: str, mask_ids: bool) -> list:
    serial = mask_value(report.serial) if mask_ids else report.serial
    wwn = mask_value(report.wwn) if mask_ids and report.wwn else report.wwn
    capacity_tb = round(report.capacity_bytes / 1e12, 1) if report.capacity_bytes else None
    lines = [
        f"{report.name}  -  {report.verdict}",
        "",
        f"Serial (etiqueta): {serial or 'n/d'}",
        f"WWN (etiqueta):    {wwn or 'n/d'}",
        f"Modelo: {report.model}    Firmware: {report.firmware}",
        f"Capacidade: {report.capacity_bytes} bytes (~{capacity_tb} TB)    RPM: {report.rpm}",
        f"Porta USB: {report.usb_port or 'n/d'}    Dispositivo: {report.device}    SMART via -d {report.smart_access}",
        f"Coletado: {generated_at.isoformat(timespec='seconds')}    Host: {hostname}",
        f"SHA-256 do log bruto (16 primeiros): {json_digest[:16]}",
        "",
        f"Horas ligado: {report.power_on_hours}    Ciclos de energia: {report.power_cycles}    "
        f"Temperatura: {report.temperature_c} C",
        f"Realocados: {report.reallocated}    Pendentes: {report.pending}    "
        f"Incorrigiveis: {report.uncorrectable}    CRC: {report.crc_errors}",
        "",
        "ID  ATRIBUTO                    ATUAL  PIOR  LIM  RAW",
    ]
    rows = smart_json.get("ata_smart_attributes", {}).get("table", [])[:MAX_ATTRIBUTE_ROWS]
    lines += [attribute_line(row) for row in rows]
    lines += ["", "Ultimos auto-testes:"]
    lines += [f"  {test.kind}: {test.status_text} (aos {test.lifetime_hours} h)"
              for test in self_tests[:MAX_SELF_TEST_ROWS]] or ["  nenhum registrado"]
    if report.reasons:
        lines += ["", "Motivos: " + "; ".join(report.reasons)]
    lines += ["", "SMART e indicativo, nao garantia. Log completo disponivel sob pedido."]
    return lines


def ficha_svg(lines: list, verdict: str) -> str:
    width = int(max(len(line) for line in lines) * CHAR_WIDTH + 2 * PADDING)
    height = len(lines) * LINE_HEIGHT + 2 * PADDING
    header_color = VERDICT_COLORS.get(verdict, VERDICT_COLORS["SEM_DADOS"])
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect width="100%" height="100%" fill="#ffffff"/>',
        f'<rect width="100%" height="{LINE_HEIGHT + PADDING}" fill="{header_color}"/>',
    ]
    for index, line in enumerate(lines):
        y_position = PADDING + LINE_HEIGHT * (index + 1) - 5
        fill = HEADER_TEXT_COLOR if index == 0 else "#111111"
        weight = "bold" if index == 0 else "normal"
        parts.append(
            f'<text x="{PADDING}" y="{y_position}" xml:space="preserve" fill="{fill}" font-weight="{weight}" '
            f'font-family="DejaVu Sans Mono, Menlo, Consolas, monospace" font-size="{FONT_SIZE}">'
            f'{escape(line)}</text>'
        )
    parts.append("</svg>")
    return "\n".join(parts) + "\n"


def try_convert_to_png(svg_path: Path) -> Optional[Path]:
    """Converte com o primeiro conversor instalado; sem nenhum, devolve None e o SVG continua valendo."""
    png_path = svg_path.with_suffix(".png")
    for executable, argument_templates in PNG_CONVERTERS:
        if shutil.which(executable) is None:
            continue
        arguments = [template.format(svg=svg_path, png=png_path) for template in argument_templates]
        try:
            subprocess.run([executable, *arguments], capture_output=True, timeout=PNG_CONVERT_TIMEOUT_SECONDS,
                           check=True)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired, OSError):
            continue
        return png_path
    return None
