# DroneHub GCS — custom build module (QGC Stable_V5.0 API).
#
# QGC core detects custom/ და აკეთებს add_subdirectory(custom) (CMakeLists.txt:261)
# და include(CustomOverrides) (CMakeLists.txt:27 ← custom/cmake/CustomOverrides.cmake).
#
# რეგისტრაცია: CUSTOMHEADER/CUSTOMCLASS compile-defs → core ქმნის CustomPlugin singleton-ს.
# Sources/includes/resources გადაეცემა core target-ს (${CMAKE_PROJECT_NAME}) cache vars-ით
# (იხ. core CMakeLists.txt:526-528, 270/299).

message(STATUS "QGC: Adding DroneHub Custom Plugin")

# ჩვენი QGCCorePlugin subclass-ის რეგისტრაცია core-ში.
set_property(DIRECTORY ${CMAKE_SOURCE_DIR}
    APPEND PROPERTY COMPILE_DEFINITIONS
        QGC_CUSTOM_BUILD
        CUSTOMHEADER="CustomPlugin.h"
        CUSTOMCLASS=CustomPlugin
)

# custom resources (logo, font, Theme module) → QGC_RESOURCES.
list(APPEND CUSTOM_RESOURCES ${CMAKE_CURRENT_SOURCE_DIR}/custom.qrc)
set(QGC_RESOURCES ${QGC_RESOURCES} ${CUSTOM_RESOURCES} CACHE STRING "Paths to .qrc Resources" FORCE)

# custom plugin sources → core target.
set(CUSTOM_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/CustomPlugin.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/src/CustomPlugin.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/CustomOptions.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/src/CustomOptions.h
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_INCLUDE_DIRECTORIES
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    CACHE INTERNAL "" FORCE
)

# Qt 6 qt_add_qml_module precompiles src/FlightDisplay/FlyViewCustomLayer.qml via qmlcache.
# CustomOverrideInterceptor does not replace module types — copy our layer before each build.
set(DRONEHUB_FLYVIEW_LAYER_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml")
set(DRONEHUB_FLYVIEW_LAYER_DST
    "${CMAKE_SOURCE_DIR}/src/FlightDisplay/FlyViewCustomLayer.qml")
set(DRONEHUB_FLYVIEW_TOOLBAR_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/FlyViewToolBar.qml")
set(DRONEHUB_FLYVIEW_TOOLBAR_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/FlyViewToolBar.qml")
set(DRONEHUB_TOOLSTRIP_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/FlightDisplay/FlyViewToolStripActionList.qml")
set(DRONEHUB_TOOLSTRIP_DST
    "${CMAKE_SOURCE_DIR}/src/FlightDisplay/FlyViewToolStripActionList.qml")
set(DRONEHUB_GUIDED_CONFIRM_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/FlightDisplay/GuidedActionConfirm.qml")
set(DRONEHUB_GUIDED_CONFIRM_DST
    "${CMAKE_SOURCE_DIR}/src/FlightDisplay/GuidedActionConfirm.qml")
set(DRONEHUB_SLIDER_SWITCH_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/SliderSwitch.qml")
set(DRONEHUB_SLIDER_SWITCH_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/SliderSwitch.qml")
set(DRONEHUB_TOOLSTRIP_PANEL_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/ToolStrip.qml")
set(DRONEHUB_TOOLSTRIP_PANEL_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/ToolStrip.qml")
set(DRONEHUB_TOOLSTRIP_BUTTON_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/ToolStripHoverButton.qml")
set(DRONEHUB_TOOLSTRIP_BUTTON_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/ToolStripHoverButton.qml")
set(DRONEHUB_GPS_INDICATOR_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/GPSIndicator.qml")
set(DRONEHUB_GPS_INDICATOR_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/GPSIndicator.qml")
set(DRONEHUB_BATTERY_INDICATOR_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/BatteryIndicator.qml")
set(DRONEHUB_BATTERY_INDICATOR_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/BatteryIndicator.qml")

add_custom_target(DroneHubSyncFlyViewLayer ALL
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_FLYVIEW_LAYER_SRC}" "${DRONEHUB_FLYVIEW_LAYER_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_FLYVIEW_TOOLBAR_SRC}" "${DRONEHUB_FLYVIEW_TOOLBAR_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_TOOLSTRIP_SRC}" "${DRONEHUB_TOOLSTRIP_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_GUIDED_CONFIRM_SRC}" "${DRONEHUB_GUIDED_CONFIRM_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_SLIDER_SWITCH_SRC}" "${DRONEHUB_SLIDER_SWITCH_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_TOOLSTRIP_PANEL_SRC}" "${DRONEHUB_TOOLSTRIP_PANEL_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_TOOLSTRIP_BUTTON_SRC}" "${DRONEHUB_TOOLSTRIP_BUTTON_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_GPS_INDICATOR_SRC}" "${DRONEHUB_GPS_INDICATOR_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_BATTERY_INDICATOR_SRC}" "${DRONEHUB_BATTERY_INDICATOR_DST}"
    DEPENDS "${DRONEHUB_FLYVIEW_LAYER_SRC}" "${DRONEHUB_FLYVIEW_TOOLBAR_SRC}"
            "${DRONEHUB_TOOLSTRIP_SRC}" "${DRONEHUB_GUIDED_CONFIRM_SRC}"
            "${DRONEHUB_SLIDER_SWITCH_SRC}" "${DRONEHUB_TOOLSTRIP_PANEL_SRC}"
            "${DRONEHUB_TOOLSTRIP_BUTTON_SRC}" "${DRONEHUB_GPS_INDICATOR_SRC}"
            "${DRONEHUB_BATTERY_INDICATOR_SRC}"
    COMMENT "Sync DroneHub custom QML into QGC qmlcache sources"
    VERBATIM
)
if(TARGET FlightDisplayModule)
    add_dependencies(FlightDisplayModule DroneHubSyncFlyViewLayer)
endif()
if(TARGET QGroundControlControlsModule)
    add_dependencies(QGroundControlControlsModule DroneHubSyncFlyViewLayer)
endif()
if(TARGET ${CMAKE_PROJECT_NAME})
    add_dependencies(${CMAKE_PROJECT_NAME} DroneHubSyncFlyViewLayer)
endif()
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${DRONEHUB_FLYVIEW_LAYER_SRC}" "${DRONEHUB_FLYVIEW_TOOLBAR_SRC}"
    "${DRONEHUB_TOOLSTRIP_SRC}" "${DRONEHUB_GUIDED_CONFIRM_SRC}" "${DRONEHUB_SLIDER_SWITCH_SRC}"
    "${DRONEHUB_TOOLSTRIP_PANEL_SRC}" "${DRONEHUB_TOOLSTRIP_BUTTON_SRC}"
    "${DRONEHUB_GPS_INDICATOR_SRC}" "${DRONEHUB_BATTERY_INDICATOR_SRC}")

# ქართული თარგმანი (qgc_ka.ts) — core ავტომატურად glob-ავს translations/qgc_*.ts-ს
# (core CMakeLists.txt:531). bootstrap.sh symlink-ავს ჩვენს qgc_ka.ts-ს იქ. აქ wiring საჭირო არ არის.

if(APPLE)
    message(STATUS "DroneHub GCS: Removing missing AGL framework from Qt6 targets to prevent link failure on modern macOS SDKs")
    set(qt_targets_to_patch
        Qt6::Gui
        Qt6::OpenGL
        Qt6::Quick
        Qt6::QuickWidgets
        Qt6::QuickControls2
        Qt6::QuickTemplates2
        Qt6::Core
        Qt6::Widgets
        Qt6::Location
        Qt6::Positioning
    )
    foreach(qt_target ${qt_targets_to_patch})
        if(TARGET ${qt_target})
            get_target_property(link_libs ${qt_target} INTERFACE_LINK_LIBRARIES)
            if(link_libs)
                set(new_link_libs "")
                set(patched FALSE)
                foreach(lib ${link_libs})
                    if(lib MATCHES "AGL")
                        set(patched TRUE)
                    else()
                        list(APPEND new_link_libs "${lib}")
                    endif()
                endforeach()
                if(patched)
                    message(STATUS "  Patched ${qt_target} to remove AGL dependency")
                    set_target_properties(${qt_target} PROPERTIES INTERFACE_LINK_LIBRARIES "${new_link_libs}")
                endif()
            endif()
        endif()
    endforeach()
endif()
