pragma Singleton
import QtQuick

/// DroneHub design tokens — ერთადერთი წყარო ფერებისა და spacing-ისთვის.
/// UI QML არასოდეს hardcode-ავს ფერს; ყველაფერი აქედან მოდის.
QtObject {
    id: theme

    // ---- ბრენდი (asset paths — UI არასოდეს hardcode-ავს resource path-ს) ----
    readonly property string logoSource:    "qrc:/custom/img/DroneHubLogo.svg"
    readonly property string appName:       "DroneHub GCS"

    // ---- ბრენდის პალიტრა ----
    readonly property color brandPrimary:   "#0A84FF"   // DroneHub blue
    readonly property color brandAccent:    "#30D158"   // armed/ok green
    readonly property color warning:        "#FF9F0A"
    readonly property color danger:         "#FF453A"

    // ---- ფონები (dark-first, field readability) ----
    readonly property color bgBase:         "#0B0E14"
    readonly property color bgSurface:      "#151A23"
    readonly property color bgElevated:     "#1E2530"
    readonly property color divider:        "#2A323F"

    // ---- ტექსტი ----
    readonly property color textPrimary:    "#F2F4F8"
    readonly property color textSecondary:  "#A0AAB8"
    readonly property color textDisabled:   "#5A6473"

    // ---- ფორმა ----
    readonly property real  radiusSm:       6
    readonly property real  radiusMd:       12
    readonly property real  radiusLg:       18
    readonly property real  spacingUnit:    8     // 8px grid

    // ---- ტიპოგრაფია (ქართული ფონტი register-დება CustomPlugin.cc-ში) ----
    readonly property string fontFamily:    "Noto Sans Georgian"
    readonly property real  fontH1:         24
    readonly property real  fontBody:       14
    readonly property real  fontCaption:    12

    // ---- elevation ----
    readonly property var   shadowCard: ({ radius: 16, color: "#000000", opacity: 0.35, y: 4 })
}
