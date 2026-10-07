#!/usr/bin/env python3
"""Apply batch-7 Georgian translations — closes the remaining `unfinished` entries in qgc_ka.ts.

Policy (project safety rule, same as batch 6):
  * Flight-mode names, acronyms, protocol/hardware identifiers, numeric values, baud rates,
    `ROTATION_*` enum tokens and sensor model names stay English. Such entries are marked
    finished with translation == source ("intentional English").
  * Everything descriptive is translated into Georgian (DICT below).
  * Anything not covered is left `unfinished` and reported (exit code 1).
Idempotent: only touches messages still marked unfinished.
"""
from __future__ import annotations

import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TS = ROOT / "translations" / "qgc_ka.ts"

# ---- entries kept in English on purpose -------------------------------------------------
KEEP_RE = re.compile(
    r"""^(
        [\d.\s]+(Hz|hz|Kts|8N1)?(\s8N1)?        # 115200, 0.1 Hz, 1000000 8N1
      | 0x[0-9A-Fa-f]+
      | \d+(\.\d+)?\s?(Hz|hz)
      | \d+S\ Battery
      | Over1200Kts | \d+Kts
      | ROTATION_[A-Z0-9_]+
      | (Roll|Pitch|Yaw)(\s\d+°)?(,\s(Roll|Pitch|Yaw)\s\d+°)*
      | Len\d+_Wid\d+
      | (AUX|Aux)\d | RC\ AUX\ \d | TELEM\ \d | TELEM/SERIAL\ 4 | UART\ 6 | GPS\ \d | COM\d | EXT2
      | Tilt\ \d
      | (SF|LW|AUAV|TR)[A-Za-z0-9/ ]*
      | \d+\ degrees\ half\ cone\ angle\.
      | PWM\ \d+\ Hz | DShot\d+ | OneShot | PWM | PPM | SBUS | SUMD | DSM | ST24 | CRSF | GHST
      | MAVLink | NMEA\ \(generic\) | MTK | u-blox | uAvionix | uavionix | Emlid\ Reach | Femtomes
      | Ashtech\ /\ Trimble | XChaCha20 | NTSC | PAL | OSD | osd | I2C | GPIO | INS | GPOS | RAM\ \(not\ persistent\)
      | UAV | 2D | 3D | EV\ noise\ parameters | iridium | extvision | extvisionmin | magic | Magic
      | Acro | Auto | Offboard | Hold | Mission | Terminate | Precision\ Land | Land | Takeoff | Loiter
      | Stabilized | Position | Altitude | Manual | Return | RTL | Follow\ Me | Hold\ mode | Land\ mode
      | Return\ mode | Position\ mode | Position\ Hold\ mode | Altitude\ mode
      | Position\ Slow | Gimbal | GPS | AUX | RC | Gas | Servo | Tailsitter | Tiltrotor | Hexarotor | Octorotor
      | Quadrotor | Tricopter | VTOL.* | Len.* | Lat(Left|Right)\d+M | Space | Step
    )$""",
    re.X,
)

# ---- Georgian translations (keys are the *unescaped* English sources) -------------------
DICT: dict[str, str] = {
    # FlyViewCustomLayer / misc UI
    "Other": "სხვა",
    "Speed": "სიჩქარე",
    "MGRS": "MGRS",
    "Lat": "განედი",
    "Lon": "გრძედი",
    "HDOP": "HDOP",
    "Voltage": "ძაბვა",
    "Time Remaining": "დარჩენილი დრო",
    "Mag": "მაგნ.",
    "True": "ჭეშმარიტი",
    "WP Distance": "WP მანძილი",
    "WP Heading": "WP მიმართულება",
    "Flight & Navigation": "ფრენა და ნავიგაცია",
    "Power & Environment": "კვება და გარემო",
    'Action "%1" requires slide confirmation. Use Fly View → Actions.':
        "მოქმედება „%1“ საჭიროებს სლაიდით დადასტურებას. გამოიყენე Fly View → Actions.",
    "Slide to confirm": "გადაასრიალე დასადასტურებლად",
    "Slide or hold spacebar": "გადაასრიალე ან დააჭირე Space-ს",
    "Mock Link Settings": "Mock Link-ის პარამეტრები",
    "No data": "მონაცემები არ არის",
    # VehicleHealthIndicator
    "OK": "OK", "Warn": "გაფრთხ.", "Crit": "კრიტ.", "No vehicle": "აპარატი არ არის",
    "No GPS lock": "GPS ფიქსაცია არ არის", "sats": "თანამგზ.", "Locked": "ფიქსირებულია",
    "Link lost": "კავშირი დაკარგულია", "Link OK": "კავშირი OK", "Not supported": "არ არის მხარდაჭერილი",
    "Disabled": "გამორთულია", "Not compiled": "build-ში ჩართული არ არის", "Live": "პირდაპირი",
    "Waiting": "ლოდინი", "Vehicle health": "აპარატის მდგომარეობა", "Link": "კავშირი",
    "Flight mode": "ფრენის რეჟიმი", "Armed": "Armed", "Yes": "დიახ", "No": "არა",
    "RC link": "RC კავშირი", "Battery": "ბატარეა", "Video": "ვიდეო",
    # VideoStatusIndicator
    "Off": "გამორთ.", "N/A": "N/A", "Wait": "ლოდინი", "Video off": "ვიდეო გამორთულია",
    "No video backend": "ვიდეო backend არ არის", "Video waiting": "ვიდეოს ლოდინი",
    "Video live": "ვიდეო პირდაპირია", "Video status": "ვიდეოს სტატუსი", "Stream": "ნაკადი",
    "Enabled": "ჩართულია", "Backend": "Backend", "Available": "ხელმისაწვდომია", "State": "მდგომარეობა",
    # MissionCommands
    "Altitude wait": "სიმაღლის ლოდინი", "Arm/Disarm": "Arm/Disarm",
    "AutoTune Enable": "AutoTune-ის ჩართვა", "Bind Spektrum receiver": "Spektrum მიმღების დაკავშირება",
    "Calibration": "კალიბრაცია", "Camera config": "კამერის კონფიგურაცია",
    "Camera control": "კამერის მართვა", "Camera trigger distance": "კამერის გამოწვევის მანძილი",
    "Cancel ROI": "ROI-ის გაუქმება", "Change Altitude": "სიმაღლის შეცვლა",
    "Change speed": "სიჩქარის შეცვლა", "Condition Gate": "Gate-ის პირობა",
    "Configure Mount": "Mount-ის კონფიგურაცია", "Control Mount": "Mount-ის მართვა",
    "Control high latency link": "მაღალი დაყოვნების არხის მართვა", "Control video": "ვიდეოს მართვა",
    "Create panorama": "პანორამის შექმნა", "Cycle relay": "რელეს ციკლი", "Cycle servo": "სერვოს ციკლი",
    "Delay": "დაყოვნება", "Delay until": "დაყოვნება სანამ", "Enable geofence": "Geofence-ის ჩართვა",
    "Flight termination": "ფრენის შეწყვეტა", "Get capabilities": "შესაძლებლობების მიღება",
    "Get launch position": "გაშვების პოზიციის მიღება", "Get message interval": "შეტყობინების ინტერვალის მიღება",
    "Gimbal Manager PitchYaw": "Gimbal Manager PitchYaw", "Go around": "ხელახალი მიდგომა (Go around)",
    "Gripper Mechanism": "გრიპერის მექანიზმი", "Guided enable": "Guided-ის ჩართვა",
    "Guided limits": "Guided-ის ლიმიტები", "Home Position": "Home პოზიცია",
    "Inverted flight": "ინვერსიული ფრენა", "Jump to item": "გადასვლა პუნქტზე",
    "Land local": "ლოკალური Land", "Land start": "Land-ის დაწყება", "Loiter (altitude)": "Loiter (სიმაღლე)",
    "Loiter (time)": "Loiter (დრო)", "Loiter (turns)": "Loiter (ბრუნები)", "Mission start": "მისიის დაწყება",
    "Motor test": "მოტორის ტესტი", "Nav follow": "Nav follow", "Override goto": "Goto-ს გადაფარვა",
    "Path planning": "გზის დაგეგმვა", "Pause/Continue": "პაუზა/გაგრძელება",
    "Payload control deploy": "Payload-ის დაშვების მართვა", "Payload prepare deploy": "Payload-ის დაშვების მომზადება",
    "ROI to next waypoint": "ROI შემდეგ waypoint-ზე", "Rally land": "Rally Land",
    "Reboot/Shutdown vehicle": "აპარატის გადატვირთვა/გამორთვა", "Region of interest": "ინტერესის რეგიონი",
    "Region of interest (ROI)": "ინტერესის რეგიონი (ROI)", "Reposition": "გადაადგილება",
    "Return To Launch": "Return To Launch", "Set Parameter": "პარამეტრის დაყენება",
    "Set actuator": "აქტუატორის დაყენება", "Set camera modes": "კამერის რეჟიმების დაყენება",
    "Set flight mode": "ფრენის რეჟიმის დაყენება", "Set launch location": "გაშვების ადგილის დაყენება",
    "Set message interval": "შეტყობინების ინტერვალის დაყენება", "Set mode": "რეჟიმის დაყენება",
    "Set moving direction": "მოძრაობის მიმართულების დაყენება", "Set relay": "რელეს დაყენება",
    "Set sensor offsets": "სენსორის offset-ების დაყენება", "Set servo": "სერვოს დაყენება",
    "Spline waypoint": "Spline waypoint", "Start image capture": "ფოტოგადაღების დაწყება",
    "Start video capture": "ვიდეოჩაწერის დაწყება", "Stop image capture": "ფოტოგადაღების შეჩერება",
    "Stop video capture": "ვიდეოჩაწერის შეჩერება", "Store parameters": "პარამეტრების შენახვა",
    "Takeoff local": "ლოკალური Takeoff", "Trigger control": "Trigger-ის მართვა",
    "Trigger parachute": "პარაშუტის გააქტიურება", "UAVCAN configure": "UAVCAN-ის კონფიგურაცია",
    "VTOL Transition": "VTOL გადასვლა", "VTOL land": "VTOL Land", "VTOL takeoff": "VTOL Takeoff",
    "Vehicle reposition": "აპარატის გადაადგილება", "Wait for Yaw": "Yaw-ს ლოდინი",
    "Wait for altitude": "სიმაღლის ლოდინი", "Wait for distance": "მანძილის ლოდინი", "Waypoint": "Waypoint",
    "Loiter": "Loiter", "Land": "Land", "Takeoff": "Takeoff",
    # FactEnum — generic
    "No change": "ცვლილების გარეშე", "Take photo": "ფოტოს გადაღება",
    "Take photos (time)": "ფოტოები (დროით)", "Take photos (distance)": "ფოტოები (მანძილით)",
    "Stop taking photos": "ფოტოგადაღების შეჩერება", "Start recording video": "ვიდეოჩაწერის დაწყება",
    "Stop recording video": "ვიდეოჩაწერის შეჩერება", "Photo": "ფოტო", "Survey": "Survey",
    "(Not set)": "(არ არის დაყენებული)", "- Default": "- ნაგულისხმევი", "- Disabled": "- გამორთული",
    "- Enabled": "- ჩართული", "- None": "- არცერთი", "- Reverse": "- უკუ",
    "- Turtle Mode enabled via AUX1": "- Turtle Mode ჩართულია AUX1-ით",
    "- Turtle Mode enabled via AUX2": "- Turtle Mode ჩართულია AUX2-ით",
    "- UART Passthrough Mode": "- UART Passthrough რეჟიმი", "- VOXL ESC": "- VOXL ESC",
    "2 sample averaging": "2 ნიმუშის გასაშუალოება", "4 sample averaging": "4 ნიმუშის გასაშუალოება",
    "8 sample averaging": "8 ნიმუშის გასაშუალოება", "No averaging": "გასაშუალოების გარეშე",
    "25 degrees half cone angle.": "25° ნახევარ-კონუსის კუთხე.",
    "45 degrees half cone angle.": "45° ნახევარ-კონუსის კუთხე.",
    "65 degrees half cone angle.": "65° ნახევარ-კონუსის კუთხე.",
    "80 degrees half cone angle.": "80° ნახევარ-კონუსის კუთხე.",
    "2D + Terrain: Maintain constant altitude relative to terrain below and track XY position":
        "2D + რელიეფი: მუდმივი სიმაღლე ქვემოთ არსებული რელიეფის მიმართ და XY პოზიციის თვალყურის დევნება",
    "2D Clockwise": "2D საათის ისრის მიმართულებით", "2D Counter Clockwise": "2D საათის ისრის საწინააღმდეგოდ",
    "2D Tracking: Maintain constant altitude relative to home and track XY position only":
        "2D თვალყურის დევნება: მუდმივი სიმაღლე home-ის მიმართ, მხოლოდ XY პოზიციის თვალყურით",
    "3D Clockwise": "3D საათის ისრის მიმართულებით", "3D Counter Clockwise": "3D საათის ისრის საწინააღმდეგოდ",
    "3D Tracking: Track target's altitude (be aware that GPS altitude bias usually makes this useless)":
        "3D თვალყურის დევნება: სამიზნის სიმაღლის თვალყურით (გაითვალისწინე: GPS სიმაღლის წანაცვლება ხშირად ამას უსარგებლოს ხდის)",
    "Acceleration based": "აჩქარებაზე დაფუძნებული", "Active high": "აქტიური მაღალი", "Active low": "აქტიური დაბალი",
    "Airborne": "ჰაერში", "Airbrake": "საჰაერო მუხრუჭი", "Airframe": "ფიუზელაჟი",
    "Airship, controlled": "დირიჟაბლი, მართვადი", "All mission messages": "მისიის ყველა შეტყობინება",
    "All sensors": "ყველა სენსორი", "All sensors except mag": "ყველა სენსორი მაგნიტომეტრის გარდა",
    "Allow arming": "Arming-ის დაშვება", "Alt": "სიმ.", "Altitude following": "სიმაღლის მიყოლა",
    "Always": "ყოველთვის", "Always broadcast": "ყოველთვის broadcast", "Always off": "ყოველთვის გამორთული",
    "Always on": "ყოველთვის ჩართული", "Always use version 1": "ყოველთვის ვერსია 1",
    "Always use version 2": "ყოველთვის ვერსია 2", "Angle": "კუთხე", "Angular rate": "კუთხური სიჩქარე",
    "AppliedBySensor": "სენსორის მიერ გამოყენებული",
    "Apply the estimated scale after disarm": "შეფასებული მასშტაბის გამოყენება disarm-ის შემდეგ",
    "Apply the estimated scale in air": "შეფასებული მასშტაბის გამოყენება ჰაერში",
    "Apply the new gains after disarm": "ახალი gain-ების გამოყენება disarm-ის შემდეგ",
    "Apply the new gains in air": "ახალი gain-ების გამოყენება ჰაერში",
    "Auto (RC and MAVLink gimbal protocol v2)": "Auto (RC და MAVLink gimbal protocol v2)",
    "Auto detect": "ავტომატური აღმოჩენა", "Auto-detect": "ავტომატური აღმოჩენა",
    "Auto-detected": "ავტომატურად აღმოჩენილი", "AutoDetect": "ავტომატური აღმოჩენა",
    "Autodetect": "ავტომატური აღმოჩენა", "Autodetect I2C address (TODO)": "I2C მისამართის ავტომატური აღმოჩენა",
    "Automatic": "ავტომატური", "Automotive": "საავტომობილო", "automotive": "საავტომობილო",
    "BQ40Z50 based": "BQ40Z50-ზე დაფუძნებული", "BQ40Z80 based": "BQ40Z80-ზე დაფუძნებული",
    "Barometric pressure": "ბარომეტრული წნევა", "Basic": "ძირითადი", "Both": "ორივე",
    "Calculate landing glide slope relative to the terrain estimate":
        "დაშვების გლისადის გამოთვლა რელიეფის შეფასების მიმართ",
    "Camera Capture": "კამერით გადაღება", "Camera Trigger": "კამერის Trigger",
    "Coast Motors": "მოტორების ინერციით ბრუნვა", "Coaxial helicopter": "კოაქსიალური ვერტმფრენი",
    "Config": "კონფიგურაცია", "config": "კონფიგურაცია", "Constant Max": "მუდმივი მაქს.",
    "Constant Min": "მუდმივი მინ.",
    "Current-based compensation (battery_status instance 0)": "დენზე დაფუძნებული კომპენსაცია (battery_status instance 0)",
    "Current-based compensation (battery_status instance 1)": "დენზე დაფუძნებული კომპენსაცია (battery_status instance 1)",
    "Custom": "მორგებული", "custom": "მორგებული", "Custom Euler Angle": "მორგებული Euler-ის კუთხე",
    "Custom participant": "მორგებული მონაწილე", "DISABLED": "გამორთულია", "Default": "ნაგულისხმევი",
    "default (SD card)": "ნაგულისხმევი (SD ბარათი)",
    "Default to 1, switch to 2 if GCS sends version 2": "ნაგულისხმევად 1, გადადის 2-ზე თუ GCS გააგზავნის ვერსიას 2",
    "Deny arming": "Arming-ის აკრძალვა", "Developer": "დეველოპერი", "Direct Feedthrough": "პირდაპირი Feedthrough",
    "Direct velocity": "პირდაპირი სიჩქარე", "Disable": "გამორთვა", "disabled": "გამორთულია",
    "Disable fallback to sensor-less estimation": "სენსორის გარეშე შეფასებაზე გადასვლის გამორთვა",
    "Disable nudging": "Nudging-ის გამორთვა", "Disable range fusion": "Range fusion-ის გამორთვა",
    "Disable the terrain estimate": "რელიეფის შეფასების გამორთვა", "Disallow arming": "Arming-ის აკრძალვა",
    "disables the feature": "ფუნქციას თიშავს", "Disarm": "Disarm",
    "Distance based, always on": "მანძილზე დაფუძნებული, ყოველთვის ჩართული",
    "Distance based, on command (Survey mode)": "მანძილზე დაფუძნებული, ბრძანებით (Survey რეჟიმი)",
    "Do not apply the new gains (logging only)": "ახალი gain-ები არ გამოიყენო (მხოლოდ ლოგირება)",
    "Do not automatically apply the estimated scale": "შეფასებული მასშტაბი ავტომატურად არ გამოიყენო",
    "Downed": "დაცემული", "ESCs": "ESC-ები", "EV reported variance (parameter lower bound)":
        "EV-ის დეკლარირებული დისპერსია (პარამეტრის ქვედა ზღვარი)",
    "Elevator": "სიმაღლის საჭე", "EmergencySurf": "EmergencySurf", "Enable": "ჩართვა",
    "Enable fallback to sensor-less estimation": "სენსორის გარეშე შეფასებაზე გადასვლის ჩართვა",
    "Enabled (conditional mode)": "ჩართულია (პირობითი რეჟიმი)", "Enabled (except LANDING)": "ჩართულია (LANDING-ის გარდა)",
    "Enabled constantly": "მუდმივად ჩართულია",
    "Enabled if distance to ground above MPC_LAND_ALT1": "ჩართულია, თუ მიწამდე მანძილი MPC_LAND_ALT1-ზე მეტია",
    "Enabled if distance to ground above MPC_LAND_ALT1 (except LANDING)":
        "ჩართულია, თუ მიწამდე მანძილი MPC_LAND_ALT1-ზე მეტია (LANDING-ის გარდა)",
    "Enabled if distance to ground above MPC_LAND_ALT2": "ჩართულია, თუ მიწამდე მანძილი MPC_LAND_ALT2-ზე მეტია",
    "Enabled if distance to ground above MPC_LAND_ALT2 (except LANDING)":
        "ჩართულია, თუ მიწამდე მანძილი MPC_LAND_ALT2-ზე მეტია (LANDING-ის გარდა)",
    "Enabled in VTOL MC mode, listen to request from system in FW mode":
        "ჩართულია VTOL MC რეჟიმში; FW რეჟიმში ისმენს სისტემის მოთხოვნას",
    "Eneabled": "ჩართულია", "Enforce Open Drone ID system presence": "Open Drone ID სისტემის არსებობის მოთხოვნა",
    "Enforce SD card presence": "SD ბარათის არსებობის მოთხოვნა", "Ethernet": "Ethernet", "External": "გარე",
    "External Mode 1": "გარე რეჟიმი 1", "External Mode 2": "გარე რეჟიმი 2", "External Mode 3": "გარე რეჟიმი 3",
    "External Mode 4": "გარე რეჟიმი 4", "External Mode 5": "გარე რეჟიმი 5", "External Mode 6": "გარე რეჟიმი 6",
    "External Mode 7": "გარე რეჟიმი 7", "External Mode 8": "გარე რეჟიმი 8", "external HITL": "გარე HITL",
    "External Vision": "გარე ვიზუალური სისტემა", "Falling edge": "ვარდნის ფრონტი",
    "Filter data": "მონაცემების ფილტრაცია", "First airspeed sensor": "პირველი airspeed სენსორი",
    "Fix and Fix2": "Fix და Fix2", "Fix2": "Fix2", "Fixed wing aircraft": "ფიქსირებულფრთიანი საფრენი აპარატი",
    "Fixed-Wing": "ფიქსირებული ფრთა", "Fixed-wing": "ფიქსირებული ფრთა", "Flaps channel": "ფლაპების არხი",
    "Flight Tester": "ფრენის ტესტერი", "Force off": "იძულებით გამორთვა", "Force on": "იძულებით ჩართვა",
    "Free balloon, uncontrolled": "თავისუფალი ბუშტი, უმართავი", "From receiver": "მიმღებიდან",
    "Front to Circle Center": "წინა მხარე წრის ცენტრისკენ", "Full": "სრული", "full (3D) solution": "სრული (3D) ამონახსნი",
    "Full communication": "სრული კომუნიკაცია", "GHST": "GHST", "Gas": "Gas",
    "General": "ზოგადი", "Generic PWM (IR trigger, servo)": "ზოგადი PWM (IR trigger, სერვო)",
    "Generic micro air vehicle": "ზოგადი მიკრო საფრენი აპარატი", "Geotagging messages": "გეომარკირების შეტყობინებები",
    "Get absolute timestamp": "აბსოლუტური დროის ნიშნულის მიღება",
    "Get timestamp of mid exposure (active high)": "ექსპოზიციის შუა წერტილის დროის ნიშნულის მიღება (აქტიური მაღალი)",
    "Get timestamp of mid exposure (active low)": "ექსპოზიციის შუა წერტილის დროის ნიშნულის მიღება (აქტიური დაბალი)",
    "Gimbal Pitch": "Gimbal Pitch", "Gimbal Roll": "Gimbal Roll", "Gimbal Yaw": "Gimbal Yaw",
    "gimbal": "gimbal", "Glider": "პლანერი", "Gripper": "გრიპერი", "Ground rover": "მიწისზედა როვერი",
    "Groundspeed minus windspeed": "მიწისპირა სიჩქარე მინუს ქარის სიჩქარე", "HITL and SIH disabled": "HITL და SIH გამორთულია",
    "HITL enabled": "HITL ჩართულია", "SIH enabled": "SIH ჩართულია",
    "Heading (Rover With Moving Base UART1 Connected To Autopilot, UART2 Connected To Moving Base)":
        "Heading (Rover მოძრავი ბაზით: UART1 ავტოპილოტზე, UART2 მოძრავ ბაზაზე)",
    "Heading (Rover With Moving Base UART1 Connected to Autopilot Or Can Node At 921600)":
        "Heading (Rover მოძრავი ბაზით: UART1 ავტოპილოტზე ან CAN node-ზე, 921600)",
    "Heavy": "მძიმე", "Helicopter (Coaxial)": "ვერტმფრენი (კოაქსიალური)",
    "Helicopter (tail ESC)": "ვერტმფრენი (კუდის ESC)", "Helicopter (tail Servo)": "ვერტმფრენი (კუდის სერვო)",
    "High": "მაღალი", "High Speed Long Range Mode": "მაღალსიჩქარიანი შორ მანძილის რეჟიმი",
    "High Speed Short Range Mode": "მაღალსიჩქარიანი მოკლე მანძილის რეჟიმი", "HighVortex": "HighVortex",
    "Hold Front Tangent to Circle": "წინა მხარე წრის მხების გასწვრივ", "Hold Initial Heading": "საწყისი Heading-ის შენარჩუნება",
    "Ignore": "იგნორირება", "Init": "ინიციალიზაცია", "Interference": "ხელშეშლა", "Internal": "შიდა",
    "Joystick only": "მხოლოდ Joystick", "Keep parameters": "პარამეტრების შენარჩუნება",
    "Land mode (descend)": "Land რეჟიმი (დაშვება)", "Landing Gear": "შასი", "Landing Gear Wheel": "შასის ბორბალი",
    "Large": "დიდი", "Left A-tail": "მარცხენა A-კუდი", "Left Aileron": "მარცხენა ელერონი",
    "Left Elevon": "მარცხენა ელევონი", "Left Flap": "მარცხენა ფლაპი", "Left Spoiler": "მარცხენა სპოილერი",
    "Left V-Tail": "მარცხენა V-კუდი", "Right A-tail": "მარჯვენა A-კუდი", "Right Aileron": "მარჯვენა ელერონი",
    "Right Elevon": "მარჯვენა ელევონი", "Right Flap": "მარჯვენა ფლაპი", "Right Spoiler": "მარჯვენა სპოილერი",
    "Right V-Tail": "მარჯვენა V-კუდი", "Light": "მსუბუქი", "LightAir": "LightAir",
    "Linear sine sweep": "წრფივი სინუსოიდური გაწმენდა", "Logarithmic sine sweep": "ლოგარითმული სინუსოიდური გაწმენდა",
    "Liquid": "თხევადი", "Lite": "Lite", "Localhost-only": "მხოლოდ localhost", "Long Range Mode": "შორ მანძილის რეჟიმი",
    "Low": "დაბალი", "LowFuel": "LowFuel",
    "MAVLINK_DO_MOUNT (protocol v1, to be deprecated)": "MAVLINK_DO_MOUNT (protocol v1, მომავალში მოიხსნება)",
    "MAVLINK_ROI (protocol v1, to be deprecated)": "MAVLINK_ROI (protocol v1, მომავალში მოიხსნება)",
    "MAVLink (Camera Protocol v1)": "MAVLink (Camera Protocol v1)", "MAVLink gimbal protocol v1": "MAVLink gimbal protocol v1",
    "MAVLink gimbal protocol v2": "MAVLink gimbal protocol v2", "MAVlink gimbal protocol v2": "MAVLink gimbal protocol v2",
    "Magnetic heading": "მაგნიტური მიმართულება", "Max": "მაქს.", "Min": "მინ.", "Medical": "სამედიცინო",
    "Medium (Default)": "საშუალო (ნაგულისხმევი)", "Minimal": "მინიმალური", "minimal": "მინიმალური",
    "Mission (if valid)": "Mission (თუ სწორია)", "Model with Pitot": "მოდელი Pitot-ით",
    "Model without Pitot (1.5 mm tubes)": "მოდელი Pitot-ის გარეშე (1.5 მმ მილები)",
    "Motion Capture": "Motion Capture", "Motors (6DOF)": "მოტორები (6DOF)", "Moving": "მოძრავი",
    "Moving Base (Moving Base UART1 Connected to Autopilot Or Can Node At 921600)":
        "მოძრავი ბაზა (UART1 ავტოპილოტზე ან CAN node-ზე, 921600)",
    "Moving Base (UART1 Connected To Autopilot, UART2 Connected To Rover)":
        "მოძრავი ბაზა (UART1 ავტოპილოტზე, UART2 როვერზე)",
    "Moving base": "მოძრავი ბაზა", "Multicopter": "მულტიკოპტერი", "Multirotor": "მულტიროტორი",
    "Multirotor with Tilt": "მულტიროტორი Tilt-ით", "Never broadcast": "არასდროს broadcast",
    "No cone, always climb to RTL_RETURN_ALT above destination.":
        "კონუსის გარეშე; ყოველთვის ადის RTL_RETURN_ALT-მდე დანიშნულების წერტილის ზემოთ.",
    "No filter": "ფილტრის გარეშე", "No precision landing": "ზუსტი დაშვების გარეშე", "No requirements": "მოთხოვნების გარეშე",
    "No Rescale": "მასშტაბირების გარეშე", "No rescaling": "მასშტაბირების გარეშე", "No rotation": "ბრუნვის გარეშე",
    "NoCommunications": "კომუნიკაცია არ არის", "NoData": "მონაცემები არ არის", "NoEmergency": "საგანგებო სიტუაცია არ არის",
    "None": "არცერთი", "Normal": "ნორმალური", "normal": "ნორმალური",
    "Normal helicopter with tail rotor": "ჩვეულებრივი ვერტმფრენი კუდის როტორით", "Nudge approach angle": "მიდგომის კუთხის Nudge",
    "Nudge approach path": "მიდგომის ტრაექტორიის Nudge", "Nudging disabled": "Nudging გამორთულია",
    "Nudging enabled": "Nudging ჩართულია", "Off": "გამორთულია", "On": "ჩართულია", "Onboard": "Onboard",
    "onboard": "onboard", "Onboard Low Bandwidth": "Onboard დაბალი გამტარუნარიანობა", "onboard_low_bandwidth": "onboard_low_bandwidth",
    "Only climb to at least RTL_DESCEND_ALT above destination.":
        "ადის მხოლოდ დანიშნულების წერტილის ზემოთ მინიმუმ RTL_DESCEND_ALT-მდე.",
    "Only multicast": "მხოლოდ multicast", "Opportunistic precision landing": "შესაძლებლობისამებრ ზუსტი დაშვება",
    "Parachute": "პარაშუტი", "Performance": "წარმადობა",
    "Peripheral via Actuator Set 1": "პერიფერია Actuator Set 1-ით", "Peripheral via Actuator Set 2": "პერიფერია Actuator Set 2-ით",
    "Peripheral via Actuator Set 3": "პერიფერია Actuator Set 3-ით", "Peripheral via Actuator Set 4": "პერიფერია Actuator Set 4-ით",
    "Peripheral via Actuator Set 5": "პერიფერია Actuator Set 5-ით", "Peripheral via Actuator Set 6": "პერიფერია Actuator Set 6-ით",
    "PointObstacle": "წერტილოვანი დაბრკოლება", "Position Control": "პოზიციის მართვა", "Power Module": "ძალის მოდული",
    "Pro User": "პროფესიონალი მომხმარებელი", "Pseudo-inverse with output clipping": "Pseudo-inverse გამოსავლის შეზღუდვით",
    "Pseudo-inverse with sequential desaturation technique": "Pseudo-inverse თანმიმდევრული desaturation-ით",
    "PPS Input": "PPS შეყვანა", "Publish all magnetometers": "ყველა მაგნიტომეტრის გამოქვეყნება",
    "Publish primary IMU selection": "ძირითადი IMU-ს არჩევანის გამოქვეყნება", "Publish primary magnetometer": "ძირითადი მაგნიტომეტრის გამოქვეყნება",
    "RC Controlled": "RC-ით მართვადი", "RC Flaps": "RC ფლაპები", "RC Pitch": "RC Pitch", "RC Roll": "RC Roll",
    "RC Throttle": "RC Throttle", "RC Yaw": "RC Yaw", "RC Transmitter only": "მხოლოდ RC გადამცემი",
    "RC and Joystick with fallback": "RC და Joystick fallback-ით", "RC or Joystick keep first": "RC ან Joystick, პირველი რჩება",
    "RESERVED": "რეზერვირებული", "RTCM output (PPK)": "RTCM გამოსავალი (PPK)", "Radio Controller": "რადიო კონტროლერი",
    "Range sensor": "დისტანციის სენსორი", "Raw data": "ნედლი მონაცემები",
    "Remove first failed motor from effectiveness": "პირველი გაუმართავი მოტორის ეფექტურობიდან ამოღება",
    "Require a landing": "დაშვების მოთხოვნა", "Require a takeoff": "აფრენის მოთხოვნა",
    "Require a takeoff and a landing": "აფრენისა და დაშვების მოთხოვნა",
    "Require both a takeoff and a landing, or neither": "ან აფრენაც და დაშვებაც, ან არცერთი",
    "Required precision landing": "ზუსტი დაშვება სავალდებულოა", "Rescale to hover thrust": "Hover thrust-ზე გადამასშტაბირება",
    "Reset parameters to airframe defaults": "პარამეტრების დაბრუნება airframe-ის ნაგულისხმევზე",
    "Return at critical level, land at emergency level": "კრიტიკულ დონეზე Return, საგანგებო დონეზე Land",
    "Return to a planned mission landing, if available, using the mission path, else return to home via the reverse mission path. Do not consider rally points.":
        "დაბრუნება დაგეგმილ მისიის დაშვების წერტილზე (თუ არსებობს) მისიის გზით, წინააღმდეგ შემთხვევაში home-ზე მისიის უკუ გზით. Rally წერტილები არ განიხილება.",
    "Return to closest safe point (home or rally point) via direct path.":
        "დაბრუნება უახლოეს უსაფრთხო წერტილზე (home ან rally) პირდაპირი გზით.",
    "Return to closest safe point other than home (mission landing pattern or rally point), via direct path. If no mission landing or rally points are defined return home via direct path. Always chose closest safe landing point if vehicle is a VTOL in hover mode.":
        "დაბრუნება უახლოეს უსაფრთხო წერტილზე home-ის გარდა (მისიის დაშვების სქემა ან rally წერტილი) პირდაპირი გზით. თუ ასეთი წერტილები განსაზღვრული არ არის, დაბრუნება home-ზე პირდაპირი გზით. თუ აპარატი VTOL-ია hover რეჟიმში, ყოველთვის უახლოესი უსაფრთხო წერტილი არჩევა.",
    "Return via direct path to closest destination: home, start of mission landing pattern or safe point. If the destination is a mission landing pattern, follow the pattern to land.":
        "პირდაპირი გზით დაბრუნება უახლოეს დანიშნულებაზე: home, მისიის დაშვების სქემის დასაწყისი ან უსაფრთხო წერტილი. თუ დანიშნულება დაშვების სქემაა, დაშვებისთვის სქემას მიყევი.",
    "Reverse": "უკუ", "Rising edge": "ზრდის ფრონტი", "Roll/Pitch": "Roll/Pitch", "Roll/Pitch/Yaw": "Roll/Pitch/Yaw",
    "Rotation backward": "ბრუნვა უკან", "Rotation downward": "ბრუნვა ქვემოთ", "Rotation forward": "ბრუნვა წინ",
    "Rotation left": "ბრუნვა მარცხნივ", "Rotation right": "ბრუნვა მარჯვნივ", "Rotation upward": "ბრუნვა ზემოთ",
    "Rotorcraft": "როტორული აპარატი", "Rover (Ackermann)": "Rover (Ackermann)", "Rover (Differential)": "Rover (დიფერენციალური)",
    "Rover (Mecanum)": "Rover (Mecanum)",
    "Rover with Static Base on UART2 (similar to Default, except coming in on UART2)":
        "Rover სტატიკური ბაზით UART2-ზე (ნაგულისხმევის მსგავსი, მხოლოდ UART2-ით)",
    "Rudder": "ხელმძღვანელი საჭე", "Runway": "ასაფრენი ბილიკი", "Safety button": "უსაფრთხოების ღილაკი",
    "Same as previous when landed, in-air require landing only if no valid VTOL approach is present":
        "მიწაზე წინას იდენტური; ჰაერში დაშვებას მოითხოვს მხოლოდ თუ ვალიდური VTOL მიდგომა არ არის",
    "Sea": "ზღვა", "Seagull MAP2 (over PWM)": "Seagull MAP2 (PWM-ით)", "Second airspeed sensor": "მეორე airspeed სენსორი",
    "Send Explicit Arm Command": "ცალსახა Arm ბრძანების გაგზავნა", "Send Explicit Disarm": "ცალსახა Disarm-ის გაგზავნა",
    "Sensor disabled, when explicitly started treated as AUAV L05D": "სენსორი გამორთულია; ცალსახად გაშვებისას განიხილება როგორც AUAV L05D",
    "Sensors Automatic Config": "სენსორები, ავტომატური კონფიგურაცია", "Sensors Manual Config": "სენსორები, ხელით კონფიგურაცია",
    "Sensors Only (default)": "მხოლოდ სენსორები (ნაგულისხმევი)",
    "Sensors and Actuators (ESCs) Automatic Config": "სენსორები და აქტუატორები (ESC-ები), ავტომატური კონფიგურაცია",
    "ServiceSurf": "ServiceSurf", "Set Predefined Velocity Setpoint": "წინასწარ განსაზღვრული სიჩქარის Setpoint-ის დაყენება",
    "Short Range Mode": "მოკლე მანძილის რეჟიმი", "Single Channel Aileron": "ერთარხიანი ელერონი",
    "Six side calibration": "ექვსმხრივი კალიბრაცია", "Three side calibration": "სამმხრივი კალიბრაცია",
    "Two side calibration": "ორმხრივი კალიბრაცია", "SizeUnknown": "ზომა უცნობია", "Small": "პატარა",
    "Stabilization Mode": "სტაბილიზაციის რეჟიმი", "Stabilize all axis": "ყველა ღერძის სტაბილიზაცია",
    "Stabilize yaw for absolute/lock mode.": "Yaw-ს სტაბილიზაცია absolute/lock რეჟიმისთვის.",
    "Standard": "სტანდარტული", "Standard VTOL": "სტანდარტული VTOL", "Standby": "მოლოდინის რეჟიმი",
    "Start on default I2C addr(BATMON_ADDR_DFLT)": "გაშვება ნაგულისხმევ I2C მისამართზე (BATMON_ADDR_DFLT)",
    "Stationary": "უძრავი", "stationary": "უძრავი", "Steering Wheel": "საჭე", "Stick input disabled": "Stick-ის შეყვანა გამორთულია",
    "Submarine": "წყალქვეშა აპარატი", "Supply Voltage Mode": "კვების ძაბვის რეჟიმი",
    "Surface vessel, boat, ship": "ზედაპირული ხომალდი, ნავი, გემი", "Tailsitter VTOL": "Tailsitter VTOL",
    "Terrain following": "რელიეფის მიყოლა", "Terrain hold": "რელიეფზე შენარჩუნება",
    "Thermal control enabled": "თერმული კონტროლი ჩართულია", "Thermal control off": "თერმული კონტროლი გამორთულია",
    "Thermal control unavailable": "თერმული კონტროლი მიუწვდომელია", "Third airspeed sensor": "მესამე airspeed სენსორი",
    "Throttle-based compensation": "Throttle-ზე დაფუძნებული კომპენსაცია", "Tiltrotor VTOL": "Tiltrotor VTOL",
    "Time based, always on": "დროზე დაფუძნებული, ყოველთვის ჩართული", "Time based, on command": "დროზე დაფუძნებული, ბრძანებით",
    "To receiver": "მიმღებისკენ", "Towards Front": "წინისკენ", "Towards Right": "მარჯვნივ", "Tube Pressure Drop": "მილში წნევის ვარდნა",
    "UltraLight": "UltraLight", "Unassigned": "მიუნიჭებელი", "Unconfigured": "დაუკონფიგურირებელი", "Uncontrolled": "უმართავი",
    "Undefined": "განუსაზღვრელი", "Uninitialized": "ინიციალიზებული არ არის", "Unknown": "უცნობი", "UnknownMaxSpeed": "მაქს. სიჩქარე უცნობია",
    "Use Motor Arm Behavior": "მოტორის Arm ქცევის გამოყენება",
    "Use the terrain estimate to trigger the flare (only)": "რელიეფის შეფასების გამოყენება flare-ის გასააქტიურებლად (მხოლოდ)",
    "VTOL Quad-rotor Tailsitter": "VTOL ოთხროტორიანი Tailsitter",
    "VTOL Standard (separate fixed rotors for hover and cruise flight)": "VTOL სტანდარტული (ცალკე ფიქსირებული როტორები hover-ისა და კრუიზისთვის)",
    "VTOL Tailsitter": "VTOL Tailsitter", "VTOL Tiltrotor": "VTOL Tiltrotor", "VTOL Two-rotor Tailsitter": "VTOL ორროტორიანი Tailsitter",
    "Velocity": "სიჩქარე", "Vision": "ვიზუალური სისტემა", "Voltage Limit Mode": "ძაბვის ლიმიტის რეჟიმი",
    "WARNING Apply the new gains in air": "გაფრთხილება: ახალი gain-ების გამოყენება ჰაერში",
    "Warn only": "მხოლოდ გაფრთხილება", "Warning": "გაფრთხილება", "Warning only": "მხოლოდ გაფრთხილება",
    "When autopilot is armed": "როცა ავტოპილოტი Armed-ია", "When autopilot is prearmed": "როცა ავტოპილოტი Prearmed-ია",
    "Wifi Port": "Wifi პორტი", "Yaw and Pitch": "Yaw და Pitch",
    "airborne with <1g acceleration": "ჰაერში <1g აჩქარებით", "airborne with <2g acceleration": "ჰაერში <2g აჩქარებით",
    "airborne with <4g acceleration": "ჰაერში <4g აჩქარებით", "along trajectory": "ტრაექტორიის გასწვრივ",
    "away from home": "home-იდან მოშორებით", "close the loop with gps speed": "კონტურის დახურვა GPS სიჩქარით",
    "from 1st armed until shutdown": "პირველი Arm-იდან გამორთვამდე", "from boot until disarm": "ჩატვირთვიდან Disarm-მდე",
    "from boot until shutdown": "ჩატვირთვიდან გამორთვამდე", "iridium": "iridium", "one arm": "ერთი ნაბიჯით Arm",
    "open loop control": "ღია კონტურით მართვა", "planar (2D) solution": "ბრტყელი (2D) ამონახსნი",
    "skip the controller and feedthrough the setpoints": "კონტროლერის გამოტოვება და setpoint-ების პირდაპირ გატარება",
    "time-only solution": "მხოლოდ დროის ამონახსნი", "towards home": "home-ისკენ", "towards waypoint": "waypoint-ისკენ",
    "towards waypoint (yaw first)": "waypoint-ისკენ (ჯერ yaw)", "two step arm": "ორნაბიჯიანი Arm",
    "use Attitude Setpoints": "Attitude Setpoint-ების გამოყენება", "use the module's controller": "მოდულის კონტროლერის გამოყენება",
    "when armed until disarm (default)": "Arm-იდან Disarm-მდე (ნაგულისხმევი)",
    "while manual input AUX1 >30%": "სანამ ხელით შეყვანა AUX1 >30%", "yaw fixed": "yaw ფიქსირებულია",
    "Yaw 135°": "Yaw 135°",
}

# regex-driven translations (key -> template)
RULES: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"^Motor (\d+)$"), "მოტორი \\1"),
    (re.compile(r"^Channel (\d+)$"), "არხი \\1"),
    (re.compile(r"^Servo (\d+)$"), "სერვო \\1"),
    (re.compile(r"^(\d+)S Battery$"), "\\1S ბატარეა"),
]

MSG_RE = re.compile(r"<message>(.*?)</message>", re.S)
SRC_RE = re.compile(r"<source>(.*?)</source>", re.S)
TR_RE = re.compile(r"<translation type=\"unfinished\"[^>]*?(?:/>|>(.*?)</translation>)", re.S)


def esc(t: str) -> str:
    return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def lookup(src: str) -> str | None:
    if src in DICT:
        return DICT[src]
    for pat, tpl in RULES:
        if pat.match(src):
            return pat.sub(tpl, src)
    if KEEP_RE.match(src):
        return src
    return None


def unescape_src(raw: str) -> str:
    """Handle double-escaped sources (&amp;gt;) found in the .ts as well as single escaping."""
    s = html.unescape(raw)
    return html.unescape(s) if "&" in s and re.search(r"&(amp|lt|gt|quot|apos);", s) else s


def main() -> int:
    text = TS.read_text(encoding="utf-8")
    done = kept = left = 0
    missing: list[str] = []

    def repl(m: re.Match[str]) -> str:
        nonlocal done, kept, left
        block = m.group(0)
        if 'type="unfinished"' not in block:
            return block
        sm = SRC_RE.search(block)
        if not sm or not sm.group(1).strip():
            left += 1
            return block
        src_raw = sm.group(1)
        src = unescape_src(src_raw)
        ka = lookup(src)
        if ka is None:
            left += 1
            missing.append(src)
            return block
        if ka == src:
            kept += 1
            new_tr = f"<translation>{src_raw}</translation>"
        else:
            done += 1
            new_tr = f"<translation>{esc(ka)}</translation>"
        return TR_RE.sub(lambda _m: new_tr, block, count=1)

    out = MSG_RE.sub(repl, text)
    TS.write_text(out, encoding="utf-8")
    print(f"translated: {done}, intentional English: {kept}, still unfinished: {left}")
    for s in missing:
        print("  MISSING:", repr(s))
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
