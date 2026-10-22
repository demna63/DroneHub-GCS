#pragma once

#include <QtCore/QMap>
#include <QtCore/QString>

namespace DroneHub {

/// Localized Georgian enum string mappings.
/// Used to translate enums in FactMetaData that bypass Qt Linguist (.ts).
inline const QMap<QString, QString>& enumGeorgianMap()
{
    static const QMap<QString, QString> kEnumMap = {
        // General / common
        { QStringLiteral("Disabled"),                      QStringLiteral("გამორთული") },
        { QStringLiteral("Default"),                       QStringLiteral("ნაგულისხმევი") },
        // App — color scheme, GCS position stream
        { QStringLiteral("Indoor"),                        QStringLiteral("შენობაში") },
        { QStringLiteral("Outdoor"),                       QStringLiteral("გარეთ") },
        { QStringLiteral("Never"),                         QStringLiteral("არასდროს") },
        { QStringLiteral("Always"),                        QStringLiteral("ყოველთვის") },
        { QStringLiteral("When in Follow Me Flight Mode"), QStringLiteral("Follow Me რეჟიმში") },
        // Units — speed (other unit enums are tr()'d upstream already)
        { QStringLiteral("Feet/second"),                   QStringLiteral("ფუტი/წმ") },
        { QStringLiteral("Meters/second"),                 QStringLiteral("მეტრი/წმ") },
        { QStringLiteral("Miles/hour"),                    QStringLiteral("მილი/სთ") },
        { QStringLiteral("Kilometers/hour"),               QStringLiteral("კმ/სთ") },
        // Video — fit mode
        { QStringLiteral("Fit Width"),                     QStringLiteral("სიგანეზე მორგება") },
        { QStringLiteral("Fit Height"),                    QStringLiteral("სიმაღლეზე მორგება") },
        { QStringLiteral("Fill"),                          QStringLiteral("შევსება") },
        { QStringLiteral("No Crop"),                       QStringLiteral("ჭრის გარეშე") },
        // Video — forced decoder backend
        { QStringLiteral("Force software decoder"),        QStringLiteral("პროგრამული დეკოდერი") },
        { QStringLiteral("Force NVIDIA decoder"),          QStringLiteral("NVIDIA დეკოდერი") },
        { QStringLiteral("Force VA-API decoder"),          QStringLiteral("VA-API დეკოდერი") },
        { QStringLiteral("Force DirectX3D 11 decoder"),    QStringLiteral("DirectX3D 11 დეკოდერი") },
        { QStringLiteral("Force VideoToolbox decoder"),    QStringLiteral("VideoToolbox დეკოდერი") },
        { QStringLiteral("Force Intel decoder"),           QStringLiteral("Intel დეკოდერი") },
        { QStringLiteral("Force Vulkan decoder"),          QStringLiteral("Vulkan დეკოდერი") },
        // Battery indicator — value display
        { QStringLiteral("Percentage"),                    QStringLiteral("პროცენტი") },
        { QStringLiteral("Voltage"),                       QStringLiteral("ძაბვა") },
        { QStringLiteral("Percentage and Voltage"),        QStringLiteral("პროცენტი და ძაბვა") },
        // Fly View — instrument widget
        { QStringLiteral("Integrated Compass & Attitude"), QStringLiteral("ინტეგრირებული კომპასი და ჰორიზონტი") },
        { QStringLiteral("Horizontal Compass & Attitude"), QStringLiteral("ჰორიზონტალური კომპასი და ჰორიზონტი") },
        { QStringLiteral("Large Vertical"),                QStringLiteral("დიდი ვერტიკალური") },
        // Offline editing — vehicle class (firmware names kept as-is)
        { QStringLiteral("Fixed Wing"),                    QStringLiteral("ფიქსირებული ფრთა") },
        { QStringLiteral("Multi-Rotor"),                   QStringLiteral("მულტიროტორი") },
        { QStringLiteral("Rover"),                         QStringLiteral("როვერი") },
        { QStringLiteral("Sub"),                           QStringLiteral("წყალქვეშა") },
        { QStringLiteral("Mavlink Generic"),               QStringLiteral("MAVLink ზოგადი") },
        // GStreamer debug level
        { QStringLiteral("Error"),                         QStringLiteral("შეცდომა") },
        { QStringLiteral("Warning"),                       QStringLiteral("გაფრთხილება") },
        { QStringLiteral("Info"),                          QStringLiteral("ინფო") },
        { QStringLiteral("Debug"),                         QStringLiteral("გამართვა") },
        { QStringLiteral("Log"),                           QStringLiteral("ლოგი") },
        { QStringLiteral("Trace"),                         QStringLiteral("ტრასირება") },
        // Remote ID enum values (regulatory codes FAA/CAA/EU/UTM/Class N kept as-is)
        { QStringLiteral("Undefined"),                     QStringLiteral("განუსაზღვრელი") },
        { QStringLiteral("Live GNNS"),                     QStringLiteral("ცოცხალი GNSS") },
        { QStringLiteral("Fixed (not for FAA)"),           QStringLiteral("ფიქსირებული (არა FAA-სთვის)") },
        { QStringLiteral("Takeoff(Not Supported)"),        QStringLiteral("აფრენა (არ არის მხარდაჭერილი)") },
        { QStringLiteral("None"),                          QStringLiteral("არცერთი") },
        // Self ID type
        { QStringLiteral("Flight Purpose"),                QStringLiteral("ფრენის მიზანი") },
        { QStringLiteral("Emergency"),                     QStringLiteral("საგანგებო") },
        { QStringLiteral("Extended Status"),               QStringLiteral("გაფართოებული სტატუსი") },
        // UA type taxonomy
        { QStringLiteral("Airplane/FixedWing"),            QStringLiteral("თვითმფრინავი/ფიქსირებული ფრთა") },
        { QStringLiteral("Helicopter/Multirrotor"),        QStringLiteral("ვერტმფრენი/მულტიროტორი") },
        { QStringLiteral("Gyroplane"),                     QStringLiteral("გიროპლანი") },
        { QStringLiteral("Ornithopter"),                   QStringLiteral("ორნითოპტერი") },
        { QStringLiteral("Glider"),                        QStringLiteral("პლანერი") },
        { QStringLiteral("Kite"),                          QStringLiteral("ფარფატელა") },
        { QStringLiteral("Free Ballon"),                   QStringLiteral("თავისუფალი აეროსტატი") },
        { QStringLiteral("Captive Ballon"),                QStringLiteral("მიბმული აეროსტატი") },
        { QStringLiteral("Airship"),                       QStringLiteral("საჰაერო ხომალდი") },
        { QStringLiteral("Parachute"),                     QStringLiteral("პარაშუტი") },
        { QStringLiteral("Rocket"),                        QStringLiteral("რაკეტა") },
        { QStringLiteral("Tethered powered aircraft"),     QStringLiteral("მიბმული ძრავიანი აპარატი") },
        { QStringLiteral("Ground Obstacle"),               QStringLiteral("მიწისზედა დაბრკოლება") },
        { QStringLiteral("Other"),                         QStringLiteral("სხვა") },
        // Classification (operator category) — EU/Class N codes kept
        { QStringLiteral("Undeclared"),                    QStringLiteral("გაუცხადებელი") },
        { QStringLiteral("Open"),                          QStringLiteral("ღია") },
        { QStringLiteral("Specific"),                      QStringLiteral("სპეციფიკური") },
        { QStringLiteral("Certified"),                     QStringLiteral("სერტიფიცირებული") },
    };
    return kEnumMap;
}

/// Localized Georgian short description strings for FactMetaData fields.
inline const QMap<QString, QString>& shortDescGeorgianMap()
{
    static const QMap<QString, QString> kShortDescMap = {
        // ADSB server
        { QStringLiteral("Connect to ADSB SBS server"), QStringLiteral("ADSB SBS სერვერთან დაკავშირება") },
        { QStringLiteral("Host address"),               QStringLiteral("ჰოსტის მისამართი") },
        { QStringLiteral("Server port"),                QStringLiteral("სერვერის პორტი") },
        // DHGM forwarding
        { QStringLiteral("DHGM-ზე გადაცემა"),           QStringLiteral("DHGM-ზე გადაცემა") },
        { QStringLiteral("CoT multicast"),              QStringLiteral("CoT multicast") },
        { QStringLiteral("Plugin TCP პორტი"),           QStringLiteral("Plugin TCP პორტი") },
        { QStringLiteral("გადაცემის სიხშირე (Hz)"),     QStringLiteral("გადაცემის სიხშირე (Hz)") },
        { QStringLiteral("Stale timeout (წმ)"),         QStringLiteral("Stale timeout (წმ)") },
        // Remote ID — field labels come from JSON shortDesc (not in .ts)
        { QStringLiteral("Region of operation"),        QStringLiteral("ოპერირების რეგიონი") },
        { QStringLiteral("Basic ID Type"),              QStringLiteral("ძირითადი ID-ის ტიპი") },
        { QStringLiteral("Basic ID"),                   QStringLiteral("ძირითადი ID") },
        { QStringLiteral("UA type"),                    QStringLiteral("UA ტიპი") },
        { QStringLiteral("Category"),                   QStringLiteral("კატეგორია") },
        { QStringLiteral("Class"),                      QStringLiteral("კლასი") },
        { QStringLiteral("Classification Type"),        QStringLiteral("კლასიფიკაციის ტიპი") },
        { QStringLiteral("Operator ID"),                QStringLiteral("ოპერატორის ID") },
        { QStringLiteral("Operator ID type"),           QStringLiteral("ოპერატორის ID-ის ტიპი") },
        { QStringLiteral("Operator ID is valid"),       QStringLiteral("ოპერატორის ID სწორია") },
        { QStringLiteral("Self ID type"),               QStringLiteral("თვით ID-ის ტიპი") },
        { QStringLiteral("Flight Purpose"),             QStringLiteral("ფრენის მიზანი") },
        { QStringLiteral("Emergency Text"),             QStringLiteral("საგანგებო ტექსტი") },
        { QStringLiteral("Extended Status"),            QStringLiteral("გაფართოებული სტატუსი") },
        { QStringLiteral("Location Type"),              QStringLiteral("მდებარეობის ტიპი") },
        { QStringLiteral("Latitude Fixed"),             QStringLiteral("ფიქსირებული განედი") },
        { QStringLiteral("Longitude Fixed"),            QStringLiteral("ფიქსირებული გრძედი") },
        { QStringLiteral("Altitude Fixed"),             QStringLiteral("ფიქსირებული სიმაღლე") },
        { QStringLiteral("Send Basic ID"),              QStringLiteral("ძირითადი ID-ის გაგზავნა") },
        { QStringLiteral("Send Operator ID"),           QStringLiteral("ოპერატორის ID-ის გაგზავნა") },
        { QStringLiteral("Send Self ID"),               QStringLiteral("თვით ID-ის გაგზავნა") },
    };
    return kShortDescMap;
}

} // namespace DroneHub
