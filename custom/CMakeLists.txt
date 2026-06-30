# DroneHub GCS — custom build module (QGC Stable_V5.0 API).
#
# QGC core detects custom/ და აკეთებს add_subdirectory(custom) (CMakeLists.txt:261)
# და include(CustomOverrides) (CMakeLists.txt:27 ← custom/cmake/CustomOverrides.cmake).
#
# რეგისტრაცია: CUSTOMHEADER/CUSTOMCLASS compile-defs → core ქმნის CustomPlugin singleton-ს.
# Sources/includes/resources გადაეცემა core target-ს (${CMAKE_PROJECT_NAME}) cache vars-ით
# (იხ. core CMakeLists.txt:526-528, 270/299).

message(STATUS "QGC: Adding DroneHub Custom Plugin")

# ── Pinned app version (portable, engine-git-independent) ───────────────────────
# Core derives the version from `git describe` in qgroundcontrol/cmake/Git.cmake,
# which runs BEFORE project() and falls back to 0.0.0 when the engine repo has no
# v* tag. The qgroundcontrol/ dir is gitignored in this repo, so neither a git tag
# nor a Git.cmake edit survives a fresh clone — the only portable home is custom/.
# This subdirectory is add_subdirectory()'d at core CMakeLists.txt:261, AFTER both
# Git.cmake and project(), but BEFORE every version consumer (macOS bundle plist
# @369-375, the QGC_APP_VERSION_STR compile-def @493, and the digit validation
# @427-434). Re-assigning into PARENT_SCOPE therefore wins for all of them.
set(DRONEHUB_VERSION_MAJOR 1)
set(DRONEHUB_VERSION_MINOR 0)
set(DRONEHUB_VERSION_PATCH 0)
set(DRONEHUB_VERSION "${DRONEHUB_VERSION_MAJOR}.${DRONEHUB_VERSION_MINOR}.${DRONEHUB_VERSION_PATCH}")
set(QGC_APP_VERSION             "${DRONEHUB_VERSION}"   PARENT_SCOPE)
set(QGC_APP_VERSION_STR         "v${DRONEHUB_VERSION}"  PARENT_SCOPE)  # in-app About string
set(CMAKE_PROJECT_VERSION       "${DRONEHUB_VERSION}"   PARENT_SCOPE)
set(CMAKE_PROJECT_VERSION_MAJOR "${DRONEHUB_VERSION_MAJOR}" PARENT_SCOPE)
set(CMAKE_PROJECT_VERSION_MINOR "${DRONEHUB_VERSION_MINOR}" PARENT_SCOPE)
set(CMAKE_PROJECT_VERSION_PATCH "${DRONEHUB_VERSION_PATCH}" PARENT_SCOPE)
message(STATUS "DroneHub: pinned app version ${DRONEHUB_VERSION}")
# ────────────────────────────────────────────────────────────────────────────────

# Upstream Stable_V5.0 patches (e.g. macOS Quit null-guard in QGCApplication::event).
# Windows: CMake cannot execute .sh directly — invoke via Git Bash.
set(_dronehub_patch_script "${CMAKE_CURRENT_SOURCE_DIR}/../tools/apply-qgc-patches.sh")
if(NOT EXISTS "${_dronehub_patch_script}")
    set(_dronehub_patch_script "${CMAKE_SOURCE_DIR}/../tools/apply-qgc-patches.sh")
endif()
if(WIN32)
    find_program(DRONEHUB_BASH NAMES bash bash.exe
        PATHS "$ENV{ProgramFiles}/Git/bin" "C:/Program Files/Git/bin"
        NO_DEFAULT_PATH
    )
    if(NOT DRONEHUB_BASH)
        find_program(DRONEHUB_BASH NAMES bash bash.exe)
    endif()
else()
    find_program(DRONEHUB_BASH NAMES bash)
endif()
if(NOT DRONEHUB_BASH)
    message(FATAL_ERROR "DroneHub: bash not found (required for apply-qgc-patches.sh)")
endif()
execute_process(
    COMMAND "${DRONEHUB_BASH}" "${_dronehub_patch_script}" "${CMAKE_SOURCE_DIR}"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    RESULT_VARIABLE _dronehub_patch_result
    OUTPUT_VARIABLE _dronehub_patch_output
    ERROR_VARIABLE _dronehub_patch_error
)
if(NOT _dronehub_patch_result EQUAL 0)
    message(FATAL_ERROR "DroneHub: apply-qgc-patches.sh failed (${_dronehub_patch_result}):\n${_dronehub_patch_error}\n${_dronehub_patch_output}")
endif()

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
    ${CMAKE_CURRENT_SOURCE_DIR}/src/geo/geo_mag_declination.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/geo/geo_mag_declination.h
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_INCLUDE_DIRECTORIES
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/geo
    CACHE INTERNAL "" FORCE
)

# Qt 6 qt_add_qml_module precompiles src/FlightDisplay/FlyViewCustomLayer.qml via qmlcache.
# CustomOverrideInterceptor does not replace module types — copy our layer before each build.
set(DRONEHUB_FLYVIEW_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/FlightDisplay/FlyView.qml")
set(DRONEHUB_FLYVIEW_DST
    "${CMAKE_SOURCE_DIR}/src/FlightDisplay/FlyView.qml")
set(DRONEHUB_FLYVIEW_LAYER_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml")
set(DRONEHUB_FLYVIEW_LAYER_DST
    "${CMAKE_SOURCE_DIR}/src/FlightDisplay/FlyViewCustomLayer.qml")
set(DRONEHUB_FLYVIEW_WIDGET_LAYER_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/FlightDisplay/FlyViewWidgetLayer.qml")
set(DRONEHUB_FLYVIEW_WIDGET_LAYER_DST
    "${CMAKE_SOURCE_DIR}/src/FlightDisplay/FlyViewWidgetLayer.qml")
set(DRONEHUB_VIDEO_VIEW_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/FlightDisplay/FlightDisplayViewVideo.qml")
set(DRONEHUB_VIDEO_VIEW_DST
    "${CMAKE_SOURCE_DIR}/src/FlightDisplay/FlightDisplayViewVideo.qml")
set(DRONEHUB_FLYVIEW_TOOLBAR_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/FlyViewToolBar.qml")
set(DRONEHUB_FLYVIEW_TOOLBAR_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/FlyViewToolBar.qml")
set(DRONEHUB_FLYVIEW_TOOLBAR_INDICATORS_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/FlyViewToolBarIndicators.qml")
set(DRONEHUB_FLYVIEW_TOOLBAR_INDICATORS_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/FlyViewToolBarIndicators.qml")
set(DRONEHUB_RC_RSSI_INDICATOR_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Toolbar/RCRSSIIndicator.qml")
set(DRONEHUB_RC_RSSI_INDICATOR_DST
    "${CMAKE_SOURCE_DIR}/src/UI/toolbar/RCRSSIIndicator.qml")
set(DRONEHUB_VIDEO_STATUS_INDICATOR_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Toolbar/VideoStatusIndicator.qml")
set(DRONEHUB_VIDEO_STATUS_INDICATOR_DST
    "${CMAKE_SOURCE_DIR}/src/UI/toolbar/VideoStatusIndicator.qml")
set(DRONEHUB_VEHICLE_HEALTH_INDICATOR_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Toolbar/VehicleHealthIndicator.qml")
set(DRONEHUB_VEHICLE_HEALTH_INDICATOR_DST
    "${CMAKE_SOURCE_DIR}/src/UI/toolbar/VehicleHealthIndicator.qml")
set(DRONEHUB_TOOLSTRIP_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/FlightDisplay/FlyViewToolStripActionList.qml")
set(DRONEHUB_TOOLSTRIP_DST
    "${CMAKE_SOURCE_DIR}/src/FlightDisplay/FlyViewToolStripActionList.qml")
set(DRONEHUB_ADDITIONAL_ACTIONS_BTN_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/FlightDisplay/FlyViewAdditionalActionsButton.qml")
set(DRONEHUB_ADDITIONAL_ACTIONS_BTN_DST
    "${CMAKE_SOURCE_DIR}/src/FlightDisplay/FlyViewAdditionalActionsButton.qml")
set(DRONEHUB_ADDITIONAL_ACTIONS_PANEL_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/FlightDisplay/FlyViewAdditionalActionsPanel.qml")
set(DRONEHUB_ADDITIONAL_ACTIONS_PANEL_DST
    "${CMAKE_SOURCE_DIR}/src/FlightDisplay/FlyViewAdditionalActionsPanel.qml")
set(DRONEHUB_MAVLINK_ACTION_CONFIRM_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/FlightDisplay/MavlinkActionConfirm.qml")
set(DRONEHUB_MAVLINK_ACTION_CONFIRM_DST
    "${CMAKE_SOURCE_DIR}/src/FlightDisplay/MavlinkActionConfirm.qml")
set(DRONEHUB_GUIDED_GRIPPER_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/FlightDisplay/GuidedActionGripper.qml")
set(DRONEHUB_GUIDED_GRIPPER_DST
    "${CMAKE_SOURCE_DIR}/src/FlightDisplay/GuidedActionGripper.qml")
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
set(DRONEHUB_POPUP_DIALOG_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/QGCPopupDialog.qml")
set(DRONEHUB_POPUP_DIALOG_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/QGCPopupDialog.qml")
set(DRONEHUB_DROP_PANEL_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/DropPanel.qml")
set(DRONEHUB_DROP_PANEL_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/DropPanel.qml")
set(DRONEHUB_SETTINGS_GROUP_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/SettingsGroupLayout.qml")
set(DRONEHUB_SETTINGS_GROUP_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/SettingsGroupLayout.qml")
set(DRONEHUB_TOOLSTRIP_DROP_PANEL_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/ToolStripDropPanel.qml")
set(DRONEHUB_TOOLSTRIP_DROP_PANEL_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/ToolStripDropPanel.qml")
set(DRONEHUB_PLAN_TOOLBAR_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/PlanViewToolBar.qml")
set(DRONEHUB_PLAN_TOOLBAR_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/PlanViewToolBar.qml")
set(DRONEHUB_APP_SETTINGS_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/AppSettings.qml")
set(DRONEHUB_APP_SETTINGS_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/AppSettings.qml")
set(DRONEHUB_TOOL_INDICATOR_PAGE_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/Controls/ToolIndicatorPage.qml")
set(DRONEHUB_TOOL_INDICATOR_PAGE_DST
    "${CMAKE_SOURCE_DIR}/src/QmlControls/ToolIndicatorPage.qml")
set(DRONEHUB_MAIN_WINDOW_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/res/Custom/qml/QGroundControl/MainWindow/MainWindow.qml")
set(DRONEHUB_MAIN_WINDOW_DST
    "${CMAKE_SOURCE_DIR}/src/UI/MainWindow.qml")

# Configure-time sync for qmlcache-registered files (must exist before qt_add_qml_module generate).
foreach(_dronehub_cfg_sync IN ITEMS
    "${DRONEHUB_VIDEO_STATUS_INDICATOR_SRC}|${DRONEHUB_VIDEO_STATUS_INDICATOR_DST}"
    "${DRONEHUB_VEHICLE_HEALTH_INDICATOR_SRC}|${DRONEHUB_VEHICLE_HEALTH_INDICATOR_DST}"
    "${DRONEHUB_MAVLINK_ACTION_CONFIRM_SRC}|${DRONEHUB_MAVLINK_ACTION_CONFIRM_DST}"
    "${DRONEHUB_ADDITIONAL_ACTIONS_PANEL_SRC}|${DRONEHUB_ADDITIONAL_ACTIONS_PANEL_DST}"
)
    string(REPLACE "|" ";" _pair "${_dronehub_cfg_sync}")
    list(GET _pair 0 _cfg_src)
    list(GET _pair 1 _cfg_dst)
    if(EXISTS "${_cfg_src}")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_cfg_src}" "${_cfg_dst}"
            COMMAND_ERROR_IS_FATAL ANY
        )
    endif()
endforeach()

add_custom_target(DroneHubSyncFlyViewLayer ALL
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_FLYVIEW_SRC}" "${DRONEHUB_FLYVIEW_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_FLYVIEW_LAYER_SRC}" "${DRONEHUB_FLYVIEW_LAYER_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_FLYVIEW_WIDGET_LAYER_SRC}" "${DRONEHUB_FLYVIEW_WIDGET_LAYER_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_VIDEO_VIEW_SRC}" "${DRONEHUB_VIDEO_VIEW_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_FLYVIEW_TOOLBAR_SRC}" "${DRONEHUB_FLYVIEW_TOOLBAR_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_FLYVIEW_TOOLBAR_INDICATORS_SRC}" "${DRONEHUB_FLYVIEW_TOOLBAR_INDICATORS_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_RC_RSSI_INDICATOR_SRC}" "${DRONEHUB_RC_RSSI_INDICATOR_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_VIDEO_STATUS_INDICATOR_SRC}" "${DRONEHUB_VIDEO_STATUS_INDICATOR_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_VEHICLE_HEALTH_INDICATOR_SRC}" "${DRONEHUB_VEHICLE_HEALTH_INDICATOR_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_TOOLSTRIP_SRC}" "${DRONEHUB_TOOLSTRIP_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_ADDITIONAL_ACTIONS_BTN_SRC}" "${DRONEHUB_ADDITIONAL_ACTIONS_BTN_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_ADDITIONAL_ACTIONS_PANEL_SRC}" "${DRONEHUB_ADDITIONAL_ACTIONS_PANEL_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_MAVLINK_ACTION_CONFIRM_SRC}" "${DRONEHUB_MAVLINK_ACTION_CONFIRM_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_GUIDED_GRIPPER_SRC}" "${DRONEHUB_GUIDED_GRIPPER_DST}"
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
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_POPUP_DIALOG_SRC}" "${DRONEHUB_POPUP_DIALOG_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_DROP_PANEL_SRC}" "${DRONEHUB_DROP_PANEL_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_SETTINGS_GROUP_SRC}" "${DRONEHUB_SETTINGS_GROUP_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_TOOLSTRIP_DROP_PANEL_SRC}" "${DRONEHUB_TOOLSTRIP_DROP_PANEL_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_PLAN_TOOLBAR_SRC}" "${DRONEHUB_PLAN_TOOLBAR_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_APP_SETTINGS_SRC}" "${DRONEHUB_APP_SETTINGS_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_TOOL_INDICATOR_PAGE_SRC}" "${DRONEHUB_TOOL_INDICATOR_PAGE_DST}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DRONEHUB_MAIN_WINDOW_SRC}" "${DRONEHUB_MAIN_WINDOW_DST}"
    DEPENDS "${DRONEHUB_FLYVIEW_SRC}" "${DRONEHUB_FLYVIEW_LAYER_SRC}" "${DRONEHUB_FLYVIEW_WIDGET_LAYER_SRC}" "${DRONEHUB_VIDEO_VIEW_SRC}" "${DRONEHUB_FLYVIEW_TOOLBAR_SRC}"
            "${DRONEHUB_FLYVIEW_TOOLBAR_INDICATORS_SRC}" "${DRONEHUB_RC_RSSI_INDICATOR_SRC}"
            "${DRONEHUB_VIDEO_STATUS_INDICATOR_SRC}" "${DRONEHUB_VEHICLE_HEALTH_INDICATOR_SRC}" "${DRONEHUB_TOOLSTRIP_SRC}" "${DRONEHUB_ADDITIONAL_ACTIONS_BTN_SRC}"
            "${DRONEHUB_ADDITIONAL_ACTIONS_PANEL_SRC}" "${DRONEHUB_MAVLINK_ACTION_CONFIRM_SRC}"
            "${DRONEHUB_GUIDED_GRIPPER_SRC}"
            "${DRONEHUB_GUIDED_CONFIRM_SRC}"
            "${DRONEHUB_SLIDER_SWITCH_SRC}" "${DRONEHUB_TOOLSTRIP_PANEL_SRC}"
            "${DRONEHUB_TOOLSTRIP_BUTTON_SRC}" "${DRONEHUB_GPS_INDICATOR_SRC}"
            "${DRONEHUB_BATTERY_INDICATOR_SRC}" "${DRONEHUB_POPUP_DIALOG_SRC}"
            "${DRONEHUB_DROP_PANEL_SRC}" "${DRONEHUB_SETTINGS_GROUP_SRC}"
            "${DRONEHUB_TOOLSTRIP_DROP_PANEL_SRC}" "${DRONEHUB_PLAN_TOOLBAR_SRC}"
            "${DRONEHUB_APP_SETTINGS_SRC}" "${DRONEHUB_TOOL_INDICATOR_PAGE_SRC}"
            "${DRONEHUB_MAIN_WINDOW_SRC}"
    COMMENT "Sync DroneHub custom QML into QGC qmlcache sources"
    VERBATIM
)
if(TARGET FlightDisplayModule)
    add_dependencies(FlightDisplayModule DroneHubSyncFlyViewLayer)
endif()
if(TARGET QGroundControlControlsModule)
    add_dependencies(QGroundControlControlsModule DroneHubSyncFlyViewLayer)
endif()
if(TARGET ToolbarModule)
    add_dependencies(ToolbarModule DroneHubSyncFlyViewLayer)
endif()
if(TARGET MainWindowModule)
    add_dependencies(MainWindowModule DroneHubSyncFlyViewLayer)
endif()
if(TARGET ${CMAKE_PROJECT_NAME})
    add_dependencies(${CMAKE_PROJECT_NAME} DroneHubSyncFlyViewLayer)
endif()

# macOS: one Finder-visible .app (build/DroneHubGCS.app → Release/DroneHubGCS.app).
if(APPLE)
    add_custom_target(DroneHubSyncAppBundle ALL
        COMMAND "${CMAKE_SOURCE_DIR}/../tools/sync-dhgcs-app.sh" "${CMAKE_BINARY_DIR}"
        COMMENT "Symlink build/DroneHubGCS.app to Release bundle"
        VERBATIM
    )
    if(TARGET ${CMAKE_PROJECT_NAME})
        add_dependencies(DroneHubSyncAppBundle ${CMAKE_PROJECT_NAME})
    endif()
endif()
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${DRONEHUB_FLYVIEW_LAYER_SRC}" "${DRONEHUB_FLYVIEW_WIDGET_LAYER_SRC}" "${DRONEHUB_VIDEO_VIEW_SRC}" "${DRONEHUB_FLYVIEW_TOOLBAR_SRC}"
    "${DRONEHUB_FLYVIEW_TOOLBAR_INDICATORS_SRC}" "${DRONEHUB_RC_RSSI_INDICATOR_SRC}"
    "${DRONEHUB_VIDEO_STATUS_INDICATOR_SRC}" "${DRONEHUB_VEHICLE_HEALTH_INDICATOR_SRC}" "${DRONEHUB_TOOLSTRIP_SRC}" "${DRONEHUB_ADDITIONAL_ACTIONS_BTN_SRC}"
    "${DRONEHUB_ADDITIONAL_ACTIONS_PANEL_SRC}" "${DRONEHUB_MAVLINK_ACTION_CONFIRM_SRC}"
    "${DRONEHUB_GUIDED_GRIPPER_SRC}"
    "${DRONEHUB_GUIDED_CONFIRM_SRC}" "${DRONEHUB_SLIDER_SWITCH_SRC}"
    "${DRONEHUB_TOOLSTRIP_PANEL_SRC}" "${DRONEHUB_TOOLSTRIP_BUTTON_SRC}"
    "${DRONEHUB_GPS_INDICATOR_SRC}" "${DRONEHUB_BATTERY_INDICATOR_SRC}"
    "${DRONEHUB_POPUP_DIALOG_SRC}" "${DRONEHUB_DROP_PANEL_SRC}" "${DRONEHUB_SETTINGS_GROUP_SRC}"
    "${DRONEHUB_TOOLSTRIP_DROP_PANEL_SRC}" "${DRONEHUB_PLAN_TOOLBAR_SRC}"
    "${DRONEHUB_APP_SETTINGS_SRC}" "${DRONEHUB_TOOL_INDICATOR_PAGE_SRC}" "${DRONEHUB_MAIN_WINDOW_SRC}")

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
