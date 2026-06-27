#!/usr/bin/env python3
"""Apply batch-3 Georgian UI translations to translations/qgc_ka.ts.

Setup, Safety, Links, Analyze, and remaining Plan/Fly chrome.
Skips flight-mode names and attitude axes (Roll/Pitch/Yaw/Loiter/…).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TS = ROOT / "translations" / "qgc_ka.ts"

SKIP_SOURCES = frozenset({
    "Roll", "Pitch", "Yaw", "Loiter", "Manual", "Stabilize", "Acro", "RTL",
    "Land", "Takeoff", "Hold", "Mission", "Guided", "Auto", "Circle",
    "Training", "FBW A", "FBW B", "Cruise", "Autotune", "QStabilize",
    "QHover", "QLoiter", "QLand", "QRTL", "QAcro", "QAutotune",
    "Autotune: roll", "Autotune: pitch", "Autotune: yaw", "AutoTune",
    "Loiter Alt", "RC Roll/Pitch Feel",
})

SKIP_CONTEXT_RE = re.compile(
    r"(FlightMode|FirmwarePlugin|APM.*Mode|PX4.*Mode|ModeIndicator)$"
)

BATCH3: dict[str, str] = {
    # Fly / navigation labels
    "Fly View": "ფრენის ხედი",
    "Comm Lost": "კავშირი დაკარგული",
    "Multi Vehicle Actions": "მრავალაპარატიანი მოქმედებები",
    "Dist prev WP:": "წინა WP-ის მანძილი:",
    "Alt (rel)": "სიმაღ. (rel)",
    # Safety / failsafe
    "GeoFence": "GeoFence",
    "GeoFence:": "GeoFence:",
    "Geofence Failsafe Trigger": "GeoFence-ის უსაფრთხოების ტრიგერი",
    "RC Loss Failsafe": "RC კავშირის დაკარგვის უსაფრთხოება",
    "RC Loss Failsafe Trigger": "RC კავშირის დაკარგვის ტრიგერი",
    "RC Loss Timeout": "RC დაკარგვის ტაიმაუტი",
    "RC Loss Timeout:": "RC დაკარგვის ტაიმაუტი:",
    "RTL Climb To": "RTL ასვლა",
    "RTL min alt:": "RTL მინ. სიმაღლე:",
    # Setup / sensors / tuning
    "Baro/Airspeed": "ბარო/სისრული სიჩქარე",
    "CompassMot": "CompassMot",
    "PID Tuning": "PID მორგება",
    "Swashplate Setup": "Swashplate-ის გამართვა",
    "Gimbal Up": "Gimbal-ის აწევა",
    "Gripper Open": "ციპის გახსნა",
    "Gripper Close": "ციპის დახურვა",
    "Point Vehicle": "აპარატის მიმართვა",
    "Time Lapse": "Time Lapse",
    "RC To Param": "RC → პარამეტრ",
    "Flash ChibiOS Bootloader": "ChibiOS bootloader-ის განახლება",
    "Increment Vehicle Id": "აპარატის ID-ის გაზრდა",
    "Accel 1: %1": "Accel 1: %1",
    "Accel 2: %1": "Accel 2: %1",
    "Accel 3: %1": "Accel 3: %1",
    # Settings / app
    "CrashLogs": "ავარიის ლოგები",
    "MavlinkActions": "MAVLink მოქმედებები",
    "GCS GPS": "GCS GPS",
    "NMEA GPS": "NMEA GPS",
    "NMEA GPS Baudrate": "NMEA GPS baudrate",
    "RID COMMS": "RID კომუნიკაცია",
    "Stop Bits": "სტოპ-ბიტები",
    "SquareMiles": "კვ. მილი",
    "UART Baud Rate": "UART baud rate",
    "WiFi AP SSID": "WiFi AP SSID",
    "WiFi STA SSID": "WiFi STA SSID",
    "&lt;None&gt;": "&lt;არცერთი&gt;",
    "&lt;default location&gt;": "&lt;ნაგულისხმევი ლოკაცია&gt;",
    # Links / video (brands and URLs stay recognizable)
    "AirLink": "AirLink",
    "Syslink": "Syslink",
    "LibrePilot": "LibrePilot",
    "TCP URL": "TCP URL",
    "UDP URL": "UDP URL",
    "RTSP URL": "RTSP URL",
    "Spektrum Bind": "Spektrum Bind",
    "CRSF Bind": "CRSF Bind",
    # Vehicle types (mock / summary)
    "Generic Vehicle": "ზოგადი აპარატი",
    "APM ArduCopter Vehicle": "APM ArduCopter",
    "APM ArduPlane Vehicle": "APM ArduPlane",
    "APM ArduRover Vehicle": "APM ArduRover",
    "APM ArduSub Vehicle": "APM ArduSub",
    "PX4 Pro": "PX4 Pro",
    "ArduPlane": "ArduPlane",
    # VTOL class labels (abbreviations kept)
    "VTOL": "VTOL",
    "VTOL Fixedrotor": "VTOL Fixedrotor",
    "VTOL Tailsitter": "VTOL Tailsitter",
    "VTOL Tiltwing": "VTOL Tiltwing",
    "Tiltrotor VTOL": "Tiltrotor VTOL",
    "FW(vtol)": "FW (vtol)",
    "MR(vtol)": "MR (vtol)",
    "Kite": "Kite",
    "VWorld": "VWorld",
    "GCS": "GCS",
    "EKF:": "EKF:",
    "MGRS": "MGRS",
    "RSSI": "RSSI",
    "VDOP": "VDOP",
    "(AMSL)": "(AMSL)",
    "(CalcT)": "(CalcT)",
    "(TerrF)": "(TerrF)",
    "/TAGGED": "/TAGGED",
    "X (%1)": "X (%1)",
    "Y (%1)": "Y (%1)",
    "Z (%1)": "Z (%1)",
    "%1": "%1",
}

MESSAGE_RE = re.compile(r"<message>(.*?)</message>", re.DOTALL)
CONTEXT_RE = re.compile(
    r"<context>\s*<name>([^<]+)</name>(.*?)</context>",
    re.DOTALL,
)
SOURCE_RE = re.compile(r"<source(?:>(?P<body>.*?)</source>|\s*/>)", re.DOTALL)
TRANSLATION_RE = re.compile(
    r"<translation(?:\s+type=\"unfinished\")?>(.*?)</translation>",
    re.DOTALL,
)


def xml_escape(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def normalize_source(raw: str) -> str:
    return raw.replace("&apos;", "'").replace("&quot;", '"').strip()


def has_georgian(text: str) -> bool:
    return any("\u10a0" <= c <= "\u10ff" for c in text)


def process_context(context_name: str, body: str) -> tuple[str, int, int, int]:
    applied = 0
    fixed_partial = 0
    cleared_empty = 0
    skip_ctx = bool(SKIP_CONTEXT_RE.search(context_name))

    def repl_message(match: re.Match[str]) -> str:
        nonlocal applied, fixed_partial, cleared_empty
        block = match.group(0)
        inner = match.group(1)
        src_m = SOURCE_RE.search(inner)
        tr_m = TRANSLATION_RE.search(inner)
        if not src_m or not tr_m:
            return block

        source = normalize_source(src_m.group("body") or "")
        existing = tr_m.group(1)
        existing_norm = normalize_source(existing)
        is_unfinished = 'type="unfinished"' in tr_m.group(0)

        if not source and is_unfinished:
            new_tr = "<translation></translation>"
            cleared_empty += 1
            return block.replace(tr_m.group(0), new_tr, 1)

        if is_unfinished and existing.strip():
            new_tr = f"<translation>{existing}</translation>"
            fixed_partial += 1
            return block.replace(tr_m.group(0), new_tr, 1)

        if skip_ctx or source in SKIP_SOURCES:
            return block

        ka = BATCH3.get(source)
        if ka is None:
            return block

        if ka == source and not is_unfinished:
            return block

        # Apply to unfinished entries and to finished-but-still-English copies.
        needs_update = is_unfinished or (
            not has_georgian(existing_norm) and existing_norm == source
        )
        if not needs_update:
            return block

        new_tr = f"<translation>{xml_escape(ka)}</translation>"
        applied += 1
        return block.replace(tr_m.group(0), new_tr, 1)

    new_body = MESSAGE_RE.sub(repl_message, body)
    return new_body, applied, fixed_partial, cleared_empty


def main() -> int:
    path = TS
    if len(sys.argv) > 1:
        path = Path(sys.argv[1])

    text = path.read_text(encoding="utf-8")
    total_applied = 0
    total_fixed = 0
    total_cleared = 0

    def repl_context(match: re.Match[str]) -> str:
        nonlocal total_applied, total_fixed, total_cleared
        name = match.group(1)
        body = match.group(2)
        new_body, applied, fixed, cleared = process_context(name, body)
        total_applied += applied
        total_fixed += fixed
        total_cleared += cleared
        return f"<context>\n    <name>{name}</name>{new_body}</context>"

    new_text = CONTEXT_RE.sub(repl_context, text)
    path.write_text(new_text, encoding="utf-8")

    print(f"Applied batch-3 translations: {total_applied}")
    print(f"Fixed partial (removed unfinished): {total_fixed}")
    print(f"Cleared empty unfinished entries: {total_cleared}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
