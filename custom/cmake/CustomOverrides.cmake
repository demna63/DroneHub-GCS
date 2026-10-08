# DroneHub GCS — configure-time overrides.
# QGC core აკეთებს include(CustomOverrides)-ს custom/ აღმოჩენისთანავე
# (qgroundcontrol/CMakeLists.txt:27, CMAKE_MODULE_PATH-ში custom/cmake ემატება).
# ↑ ეს ფაილი სავალდებულოა — მის გარეშე configure ჩავარდება.

# ⚠️ QGC_APP_NAME ხდება CMake target name-იც (core: project(${QGC_APP_NAME}) +
#    qt_add_executable) — space აკრძალულია. spaced ბრენდი UI-ში Theme.appName-დან მოდის.
set(QGC_APP_NAME        "DroneHubGCS"                       CACHE STRING "App Name"        FORCE)
set(QGC_ORG_NAME        "DroneHub Georgia"                  CACHE STRING "Org Name"        FORCE)
set(QGC_ORG_DOMAIN      "dronehub.ge"                       CACHE STRING "Org Domain"      FORCE)
set(QGC_APP_DESCRIPTION "DroneHub Ground Control Station"   CACHE STRING "App Description" FORCE)

# Own bundle identifier — avoids the LaunchServices collision with stock QGroundControl
# (both previously claimed org.qgroundcontrol.QGroundControl, so `open` could launch the wrong app).
set(QGC_MACOS_BUNDLE_ID "org.dronehub.GCS"                  CACHE STRING "MacOS Bundle ID" FORCE)

# Video backend — REQUIRED for drone video reception (UDP/RTSP) and the Fly View PiP window.
# Without this the videoManager has no backend, hasVideo is always false, and the PiP never shows.
# Upstream Stable_V5.0 defaults QGC_ENABLE_GST_VIDEOSTREAMING to ON, but DroneHub CI intentionally
# builds video-less (no GStreamer SDK on hosted runners). Force it OFF under CI so configure never
# reaches FindGStreamer.cmake there. For local production builds, auto-enable only on macOS when
# the framework is actually installed under /Library/Frameworks.
if(DEFINED ENV{CI})
    set(QGC_ENABLE_GST_VIDEOSTREAMING OFF CACHE BOOL "Enable GStreamer Video Backend" FORCE)
elseif(APPLE AND EXISTS "/Library/Frameworks/GStreamer.framework")
    set(QGC_ENABLE_GST_VIDEOSTREAMING ON CACHE BOOL "Enable GStreamer Video Backend" FORCE)
endif()

# Branding: copyright line. Core default is the upstream QGroundControl string,
# set NON-FORCE in qgroundcontrol/cmake/CustomOptions.cmake:13 — we run after it,
# so a plain FORCE override wins.
set(QGC_APP_COPYRIGHT "Copyright (c) 2026 DroneHub Georgia. All rights reserved." CACHE STRING "Copyright" FORCE)

# Platform app icons — point the core icon paths at the isolated custom/ assets.
if(EXISTS ${CMAKE_SOURCE_DIR}/custom/deploy/windows/WindowsQGC.ico)
    set(QGC_WINDOWS_ICON_PATH "${CMAKE_SOURCE_DIR}/custom/deploy/windows/WindowsQGC.ico" CACHE FILEPATH "Windows Icon Path" FORCE)
endif()
# QGC 5.1: QGC_MACOS_ICON_PATH is the .icns FILE (cmake/platform/Apple.cmake derives
# CFBundleIconFile from its filename and bundles it into Resources/).
if(EXISTS ${CMAKE_SOURCE_DIR}/custom/res/icons/macx.icns)
    set(QGC_MACOS_ICON_PATH "${CMAKE_SOURCE_DIR}/custom/res/icons/macx.icns" CACHE FILEPATH "macOS application icon path" FORCE)
endif()

# Android application id. Core defaults QGC_ANDROID_PACKAGE_NAME to QGC_PACKAGE_NAME
# ("org.mavlink.qgroundcontrol") in qgroundcontrol/cmake/CustomOptions.cmake:58, which
# runs before this file — so a FORCE override wins. Lowercase per Android convention
# (the macOS bundle id is org.dronehub.GCS). The Android app *label* is already
# "DroneHubGCS" via QGC_APP_NAME → AndroidManifest %%INSERT_APP_NAME%%. The launcher
# *icon* is branded via a merged package source dir assembled in custom/CMakeLists.txt.
set(QGC_ANDROID_PACKAGE_NAME "org.dronehub.gcs" CACHE STRING "Android Package Name" FORCE)
