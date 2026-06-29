pragma Singleton
import QtQuick

/// DroneHub design tokens — ერთადერთი წყარო ფერებისა და spacing-ისთვის.
QtObject {
    id: theme

    readonly property string logoSource:           "qrc:/custom/img/dggcs-logo-original.png"
    readonly property string videoPlaceholderLogo: "qrc:/custom/img/dhg-logo.png"
    readonly property string appName:       "DroneHub GCS"

    /// Fly View მარცხენა tool strip — ლოგოზე დაჭერით იკეცება/იშლება.
    property bool flyToolStripExpanded:     true

    /// Fly View მარჯვენა კამერის პანელი — ზედა პანელის კამერის ხატულაზე დაჭერით.
    property bool flyCameraPanelExpanded:   true

    /// Toolbar ლოგო — master artwork-ის ცარიელი ველის კომპენსაცია (წაკითხვადობა).
    readonly property real toolbarLogoVisualScale: 1.32

    readonly property color brandPrimary:   "#0A84FF"
    readonly property color brandAccent:    "#30D158"
    readonly property color warning:        "#FF9F0A"
    readonly property color danger:         "#FF453A"
    readonly property color telemetryAccent: "#64D2FF"

    readonly property color bgBase:         "#0B0E14"
    readonly property color bgSurface:      "#151A23"
    readonly property color bgElevated:     "#1E2530"
    readonly property color divider:        "#2A323F"

    readonly property color hudGlass:           "#28000000"
    readonly property color hudGlassStrong:   "#44000000"
    readonly property color instrumentGlass:    "#18000000"
    readonly property color toolbarGlass:     "#D1151A23"
    readonly property color chromeGlass:      Qt.rgba(0.08, 0.11, 0.14, 0.82)
    readonly property color hudBorder:              "#55FFFFFF"
    readonly property color instrumentBorder:       "#66FFFFFF"
    readonly property color hudControlActive:       "#660A84FF"
    readonly property color hudControlBorder:       "#880A84FF"
    readonly property color hudMetricBackground:    "#FF1E2530"

    /// Toast / modal / drop-panel glass (QGCPopupDialog, DropPanel, vehicle alerts).
    readonly property color toastFill:          Qt.rgba(0.08, 0.11, 0.14, 0.92)
    readonly property string toastFillHex:      "#EB141923"
    readonly property color toastBorder:        hudBorder
    readonly property color toastDivider:       "#33FFFFFF"
    readonly property real  toastRadius:        radiusLg
    readonly property color toastDangerFill:      Qt.rgba(0.14, 0.08, 0.09, 0.94)
    readonly property color toastDangerBorder:  "#88FF453A"

    /// Slide-to-confirm track + circular action buttons.
    readonly property color sliderTrackFill:    "#442A323F"
    readonly property color sliderTrackBorder:  "#44FFFFFF"
    readonly property color sliderThumbBorder:  Qt.rgba(1, 1, 1, 0.25)

    readonly property color textPrimary:    "#FFFFFF"
    readonly property color textSecondary:  "#D0D8E4"
    readonly property color textDisabled:   "#9AA6B8"

    readonly property real  radiusSm:       6
    readonly property real  radiusMd:       12
    readonly property real  radiusLg:       18
    readonly property real  spacingUnit:    8

    readonly property real  instrumentSizeCompact:  100
    readonly property real  instrumentSizeExpanded: 128

    /// Fly View HUD compact row — validated for Georgian labels (არ შემცირდეს re-test-ის გარეშე).
    readonly property real hudMetricCellWidthEm:       12.5  // × ScreenTools.defaultFontPixelWidth
    readonly property real hudMetricColumnGapUnits:     1.5  // × spacingUnit
    readonly property real hudCompactWidthPadUnits:     2.0  // × spacingUnit (horizontal pad)
    readonly property real hudExpandedMaxWidthEm:      58    // × defaultFontPixelWidth
    readonly property int  hudMetricLabelMaxLines:      2
    readonly property real hudMetricLabelLineHeight:  1.05

    readonly property string fontFamily:    "Noto Sans Georgian"
    readonly property real  fontH1:         24
    readonly property real  fontHero:       24
    readonly property real  fontBody:       17
    readonly property real  fontCaption:    13
    readonly property real  fontMicro:      12

    readonly property string emptyValue:    "—"
}
