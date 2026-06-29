#!/usr/bin/env python3
"""Apply batch-2 Georgian UI translations to translations/qgc_ka.ts.

Safe chrome only — skips flight-mode names and attitude axes (Roll/Pitch/Yaw).
Fixes partial entries that have text but still carry type="unfinished".
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TS = ROOT / "translations" / "qgc_ka.ts"

# Sources that must stay English (safety-critical identifiers).
SKIP_SOURCES = frozenset({
    "Roll", "Pitch", "Yaw", "Loiter", "Manual", "Stabilize", "Acro", "RTL",
    "Land", "Takeoff", "Hold", "Mission", "Guided", "Auto", "Circle",
    "Training", "FBW A", "FBW B", "Cruise", "Autotune", "QStabilize",
    "QHover", "QLoiter", "QLand", "QRTL", "QAcro", "QAutotune",
    "Autotune: roll", "Autotune: pitch", "Autotune: yaw",
})

# Context name patterns where flight-mode strings live — never auto-translate.
SKIP_CONTEXT_RE = re.compile(
    r"(FlightMode|FirmwarePlugin|APM.*Mode|PX4.*Mode|ModeIndicator)$"
)

# English → Georgian (batch 2). Placeholders (%1, &apos;, etc.) preserved as in source.
BATCH2: dict[str, str] = {
    # FlyView / HUD telemetry (FlyViewCustomLayer when extracted)
    "Altitude": "სიმაღლე",
    "Ground Speed": "სიჩქარე",
    "Climb Rate": "ასვლის სიჩქარე",
    "Distance": "მანძილი",
    "Satellites": "სატელიტები",
    "Battery": "ბატარეა",
    "Flight Time": "ფრენის დრო",
    "Air Speed": "სისრული სიჩქარე",
    "Current": "დენი",
    "Wind": "ქარი",
    "Temperature": "ტემპერატურა",
    "AMSL": "AMSL",
    "Clean map": "სუფთა რუკა",
    "Standard map": "სტანდარტული რუკა",
    "Expand": "გაშლა",
    "Collapse": "ჩაკეცვა",
    # FlyView toolbar / map
    "Actions": "მოქმედებები",
    "Go here": "გადასვლა აქ",
    "Go to location": "გადასვლა ლოკაციაზე",
    "Edit Position": "პოზიციის რედაქტირება",
    "Set home here": "სახლის დაყენება აქ",
    "Set Heading": "კურსის დაყენება",
    "Cancel ROI": "ROI-ის გაუქმება",
    "Orbit": "ორბიტა",
    "Pre-Flight Checklist": "ფრენამდე ჩეკლისტი",
    "Flight Plan complete": "საფრენო გეგმა დასრულდა",
    "Disconnect": "გათიშვა",
    "Downloading": "ჩამოტვირთვა",
    "Click anywhere to hide": "დამალვისთვის დააწკაპუნეთ ნებისმიერ ადგილას",
    "3D View": "3D ხედი",
    "Fly": "ფრენა",
    "Plan": "გეგმა",
    "Setup": "გამართვა",
    "Analyze": "ანალიზი",
    "Settings": "პარამეტრები",
    "Start": "დაწყება",
    # Main menu (MainWindow)
    "Analyze Tools": "ანალიზის ხელსაწყოები",
    "Vehicle Configuration": "აპარატის კონფიგურაცია",
    "Application Settings": "აპლიკაციის პარამეტრები",
    "Plan Flight": "მისიის დაგეგმვა",
    "Exit": "გასვლა",
    "Advanced Mode": "გაფართოებული რეჟიმი",
    "Turn off Advanced Mode?": "გავთიშოთ გაფართოებული რეჟიმი?",
    "Vehicle Error": "აპარატის შეცდომა",
    # Connection / status (MainStatusIndicator)
    "Comms Lost": "კავშირი დაკარგული",
    "Ready To Fly": "მზად ფრენისთვის",
    "Not Ready": "არ არის მზად",
    "Disconnected - Click to manually connect": "გათირთული — დააწკაპუნეთ ხელით დასაკავშირებლად",
    "Armed": "აქტივირებული",
    "Disarmed": "დეაქტივირებული",
    "Flying": "ფრენაში",
    "Landing": "დაშვება",
    "Vehicle Messages": "აპარატის შეტყობინებები",
    "Sensor Status": "სენსორების სტატუსი",
    "Overall Status": "საერთო სტატუსი",
    "Edit Parameter": "პარამეტრის რედაქტირება",
    "Vehicle Parameters": "აპარატის პარამეტრები",
    "Force Arm": "იძულებითი აქტივაცია",
    # Offline / links
    "Select Link to Connect": "აირჩიეთ კავშირი დასაკავშირებლად",
    "No Links Configured": "კავშირები არ არის კონფიგურირებული",
    "Communication Links": "საკომუნიკაციო კავშირები",
    "Comm Links": "კავშირები",
    "Connect": "დაკავშირება",
    "Links": "კავშირები",
    "Name": "სახელი",
    "Delete Link": "კავშირის წაშლა",
    "Edit Link": "კავშირის რედაქტირება",
    "Add New Link": "ახალი კავშირი",
    "Automatically Connect on Start": "ავტომატური დაკავშირება გაშვებაზე",
    "Device": "მოწყობილობა",
    "Enter name": "შეიყვანეთ სახელი",
    "Connect not allowed: %1": "დაკავშირება აკრძალულია: %1",
    "Shutdown": "გამორთვა",
    "Serial": "სერიული",
    "Bluetooth": "ბლუთუზი",
    "Log Replay": "ლოგის გადახეხვა",
    # Plan View
    "Send To Vehicle": "აპარატზე გაგზავნა",
    "Plan Upload": "მისიის ატვირთვა",
    "Save Plan": "მისიის შენახვა",
    "Save KML": "KML-ის შენახვა",
    "Select Plan File": "აირჩიეთ მისიის ფაილი",
    "Rally Point": "შეკრიბილების წერტილი",
    "Pattern": "ნიმუში",
    "Center": "ცენტრი",
    "Fence": "ღობე",
    "Rally": "შეკრიბილება",
    "Discard Unsaved Changes": "შეუნახავი ცვლილებების გადაუდება",
    "Load New Plan From Vehicle": "ახალი მისიის ჩატვირთვა აპარატიდან",
    "Keep Current Plan": "მიმდინარე მისიის შენარჩუნება",
    "Apply new altitude": "ახალი სიმაღლის გამოყენება",
    "Exit Plan": "გეგმიდან გასვლა",
    "Syncing Mission": "მისიის სინქრონიზაცია",
    "Default Mission Altitude": "მისიის საგანვადო სიმაღლე",
    # Toolbar / battery / armed
    "- disabled": "— გათიშული",
    "Vehicle Action": "აპარატის მოქმედება",
    "Low Voltage Failsafe": "დაბალი ძაბვის უსაფრთხოება",
    "Critical Voltage Failsafe": "კრიტიკული ძაბვის უსაფრთხოება",
    "Voltage Trigger": "ძაბვის ტრიგერი",
    "mAh Trigger": "mAh ტრიგერი",
    "Ground Control Comm Loss Failsafe": "სახმელეთის კონტროლის კავშირის დაკარგვის უსაფრთხოება",
    "Loss Timeout": "დაკარგვის ტაიმაუტი",
    "Failsafe Options": "უსაფრთხოების ვარიანტები",
    # Setup common
    "Frame": "ჩარჩო",
    "Frame Type": "ჩარჩოს ტიპი",
    "Frame Class": "ჩარჩოს კლასი",
    "Motors": "ძრავები",
    "Not supported": "არ არის მხარდაჭერილი",
    "One or more vehicle components require setup prior to flight.": "ფრენამდე ერთი ან მეტი კომპონენტის კონფიგურაციაა საჭირო.",
    "Firmware Version": "პროგრამული უზრუნველყოფის ვერსია",
    # Settings / map
    "Offline Maps": "ოფლაინ რუკები",
    "Import": "იმპორტი",
    "Export": "ექსპორტი",
    "Provider": "მიმწოდებელი",
    "Use Preflight Checklist": "ფრენამდე ჩეკლისტის გამოყენება",
    "Enforce Preflight Checklist": "ფრენამდე ჩეკლისტის სავალდებულოება",
    "Instrument Panel": "ინსტრუმენტების პანელი",
    "Select File": "ფაილის არჩევა",
    "Virtual Joystick": "ვირტუალური ჯოისტიკი",
    "Minimum Altitude": "მინიმალური სიმაღლე",
    "Maximum Altitude": "მაქსიმალური სიმაღლე",
    "General": "ზოგადი",
    "Parameters": "პარამეტრები",
    "Reload": "გადატვირთვა",
    "Update": "განახლება",
    "Close": "დახურვა",
    "OK": "კარგი",
    "Ok": "კარგი",
    "Cancel": "გაუქმება",
    "Yes": "დიახ",
    "No": "არა",
    "Warning": "გაფრთხილება",
    "Error": "შეცდომა",
    "Status": "სტატუსი",
    "Settings": "პარამეტრები",
    "Help": "დახმარება",
    "About": "შესახებ",
    "Search": "ძებნა",
    "Refresh": "განახლება",
    "Reset": "გადატვირთვა",
    "Apply": "გამოყენება",
    "Remove": "წაშლა",
    "Copy": "კოპირება",
    "Paste": "ჩასმა",
    "Browse": "დათვალიერება",
    "Open": "გახსნა",
    "Close %1": "%1-ის დახურვა",
    # CustomPlugin (source already Georgian)
    "გაფართოებული რეჟიმი მხოლოდ გამოცდილი ოპერატორებისთვისაა და შეიცავს პარამეტრებს, რომლებიც ფრენის უსაფრთხოებაზე მოქმედებს. გავაგრძელო?":
        "გაფართოებული რეჟიმი მხოლოდ გამოცდილი ოპერატორებისთვისაა და შეიცავს პარამეტრებს, რომლებიც ფრენის უსაფრთხოებაზე მოქმედებს. გავაგრძელო?",
}

MESSAGE_RE = re.compile(
    r"<message>(.*?)</message>",
    re.DOTALL,
)
CONTEXT_RE = re.compile(
    r"<context>\s*<name>([^<]+)</name>(.*?)</context>",
    re.DOTALL,
)
SOURCE_RE = re.compile(r"<source>(.*?)</source>", re.DOTALL)
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


def process_context(context_name: str, body: str) -> tuple[str, int, int]:
    applied = 0
    fixed_partial = 0
    skip_ctx = bool(SKIP_CONTEXT_RE.search(context_name))

    def repl_message(match: re.Match[str]) -> str:
        nonlocal applied, fixed_partial
        block = match.group(0)
        inner = match.group(1)
        src_m = SOURCE_RE.search(inner)
        tr_m = TRANSLATION_RE.search(inner)
        if not src_m or not tr_m:
            return block

        source = normalize_source(src_m.group(1))
        existing = tr_m.group(1)
        is_unfinished = 'type="unfinished"' in tr_m.group(0)

        if is_unfinished and existing.strip() and existing != source:
            new_tr = f"<translation>{existing}</translation>"
            fixed_partial += 1
            return block.replace(tr_m.group(0), new_tr, 1)

        if not is_unfinished:
            return block

        if skip_ctx or source in SKIP_SOURCES:
            return block

        ka = BATCH2.get(source)
        if ka is None:
            return block

        new_tr = f"<translation>{xml_escape(ka)}</translation>"
        applied += 1
        return block.replace(tr_m.group(0), new_tr, 1)

    new_body = MESSAGE_RE.sub(repl_message, body)
    return new_body, applied, fixed_partial


def main() -> int:
    path = TS
    if len(sys.argv) > 1:
        path = Path(sys.argv[1])

    text = path.read_text(encoding="utf-8")
    total_applied = 0
    total_fixed = 0

    def repl_context(match: re.Match[str]) -> str:
        nonlocal total_applied, total_fixed
        name = match.group(1)
        body = match.group(2)
        new_body, applied, fixed = process_context(name, body)
        total_applied += applied
        total_fixed += fixed
        return f"<context>\n    <name>{name}</name>{new_body}</context>"

    new_text = CONTEXT_RE.sub(repl_context, text)
    path.write_text(new_text, encoding="utf-8")

    print(f"Applied new translations: {total_applied}")
    print(f"Fixed partial (removed unfinished): {total_fixed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
