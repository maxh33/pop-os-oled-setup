#!/usr/bin/env python3
"""Checagem mínima do hdd_health_report: rode `python3 test_hdd_health_report.py` (falha com AssertionError)."""
import hashlib
import tempfile
from pathlib import Path

import hdd_ficha
import hdd_health_report as report_module

COMPLETED_OK = 0x00
READ_FAILURE = 0x70
IN_PROGRESS = 0xF9


def verdict_of(smart_json: dict) -> str:
    collection = report_module.Collection("/dev/sdw", "usb", "sat", smart_json, "")
    return report_module.with_verdict(report_module.parse_disk(collection)).verdict


def test_simulated_verdicts() -> None:
    collections = report_module.simulated_collections()
    verdicts = {
        item.device: report_module.with_verdict(report_module.parse_disk(item)).verdict for item in collections
    }
    assert verdicts == {"/dev/sdx": "APROVADO", "/dev/sdy": "REPROVADO", "/dev/sdz": "SEM_DADOS"}, verdicts


def test_standard_log_is_a_valid_fallback() -> None:
    smart_json = report_module.simulated_smart("S1", 30_000, 0, test=(COMPLETED_OK, 29_990), log_key="standard")
    assert verdict_of(smart_json) == "APROVADO"


def test_old_extended_test_does_not_count() -> None:
    smart_json = report_module.simulated_smart("S2", 50_000, 0, test=(COMPLETED_OK, 1_000))
    assert verdict_of(smart_json) == "APROVADO_SEM_TESTE_LONGO"


def test_self_test_status_codes() -> None:
    in_progress = report_module.simulated_smart("S3", 30_000, 0, test=(IN_PROGRESS, 30_000))
    assert verdict_of(in_progress) == "APROVADO_SEM_TESTE_LONGO", "teste em andamento não é aprovação"
    read_failure = report_module.simulated_smart("S4", 30_000, 0, test=(READ_FAILURE, 29_990))
    assert verdict_of(read_failure) == "REPROVADO", "falha de leitura no auto-teste reprova"


def test_missing_attribute_table_is_no_data() -> None:
    smart_json = report_module.simulated_smart("S5", 30_000, 0, test=(COMPLETED_OK, 29_990))
    smart_json["ata_smart_attributes"]["table"] = [
        row for row in smart_json["ata_smart_attributes"]["table"] if row["id"] != 197
    ]
    assert verdict_of(smart_json) == "SEM_DADOS"


def test_packed_raw_value_uses_formatted_string() -> None:
    smart_json = report_module.simulated_smart("S6", 30_000, 0, test=(COMPLETED_OK, 29_990))
    smart_json["ata_smart_attributes"]["table"][0]["raw"] = {"value": 1 << 32, "string": "0"}
    assert verdict_of(smart_json) == "APROVADO", "contador empacotado não pode virar falso ATENCAO"


def test_dry_run_writes_verifiable_evidence() -> None:
    with tempfile.TemporaryDirectory() as base_dir:
        assert report_module.main(["--dry-run", "--out", base_dir]) == 0
        out_dir = next(Path(base_dir).iterdir())
        for line in (out_dir / "SHA256SUMS").read_text().splitlines():
            expected, name = line.split("  ", 1)
            assert hashlib.sha256((out_dir / name).read_bytes()).hexdigest() == expected, name
        assert "SIMULAÇÃO" in (out_dir / "summary.md").read_text(encoding="utf-8")


def test_wwn_and_usb_port_parsing() -> None:
    assert hdd_ficha.format_wwn({"naa": 5, "oui": 0xCCA, "id": 0x1234ABCD5}) == "0x5000cca1234abcd5"
    sysfs = "/sys/devices/pci0000:00/0000:00:14.0/usb4/4-4/4-4.1/4-4.1.3/4-4.1.3:1.0/host6/block/sdb"
    assert hdd_ficha.usb_port_from_sysfs_path(sysfs) == "4-4.1.3"
    assert hdd_ficha.usb_port_from_sysfs_path("/sys/devices/pci0000:00/ata1/host0/block/sda") == ""


def test_ficha_identifies_the_unit_and_can_mask() -> None:
    with tempfile.TemporaryDirectory() as base_dir:
        names_file = Path(base_dir) / "names.csv"
        names_file.write_text("serial,nome\nSIMULATED0001,Disco Azul 03\n", encoding="utf-8")
        assert report_module.main(["--dry-run", "--out", base_dir, "--names", str(names_file)]) == 0
        out_dir = next(path for path in Path(base_dir).iterdir() if path.is_dir())
        svg = (out_dir / "sdx_SIMULATED0001.ficha.svg").read_text(encoding="utf-8")
        for expected in ("Disco Azul 03", "SIMULATED0001", "0x5000cca1234abcd5", "4-4.1.1"):
            assert expected in svg, expected
        assert (out_dir / "sdy_SIMULATED0002.ficha.svg").exists(), "uma ficha por disco"
    with tempfile.TemporaryDirectory() as base_dir:
        assert report_module.main(["--dry-run", "--out", base_dir, "--mask-ids"]) == 0
        out_dir = next(path for path in Path(base_dir).iterdir() if path.is_dir())
        masked = (out_dir / "sdx_SIMULATED0001.ficha.svg").read_text(encoding="utf-8")
        assert "SIMULATED0001" not in masked and "0001" in masked and "0x5000cca1234abcd5" not in masked


if __name__ == "__main__":
    test_simulated_verdicts()
    test_standard_log_is_a_valid_fallback()
    test_old_extended_test_does_not_count()
    test_self_test_status_codes()
    test_missing_attribute_table_is_no_data()
    test_packed_raw_value_uses_formatted_string()
    test_dry_run_writes_verifiable_evidence()
    test_wwn_and_usb_port_parsing()
    test_ficha_identifies_the_unit_and_can_mask()
    print("ok")
