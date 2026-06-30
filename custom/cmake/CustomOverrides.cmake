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
# Gate on the framework actually being installed: enabling it forces a REQUIRED GStreamer
# find (FindGStreamer.cmake), which fails on hosts without the dev libs. The CI runners
# deliberately build video-less (no GStreamer deps on 3 platforms) and don't pass
# -DQGC_ENABLE_GST_VIDEOSTREAMING=OFF, so an unconditional ON (even non-FORCE) breaks their
# configure. macOS production installs GStreamer.framework under /Library/Frameworks, so
# enable the backend only there; everywhere else inherits the upstream default (OFF).
if(APPLE AND EXISTS "/Library/Frameworks/GStreamer.framework")
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
if(EXISTS ${CMAKE_SOURCE_DIR}/custom/res/icons/macx.icns)
    set(QGC_MACOS_ICON_PATH "${CMAKE_SOURCE_DIR}/custom/res/icons" CACHE PATH "MacOS Icon Path" FORCE)
endif()

# Android application id. Core defaults QGC_ANDROID_PACKAGE_NAME to QGC_PACKAGE_NAME
# ("org.mavlink.qgroundcontrol") in qgroundcontrol/cmake/CustomOptions.cmake:58, which
# runs before this file — so a FORCE override wins. Lowercase per Android convention
# (the macOS bundle id is org.dronehub.GCS). The Android app *label* is already
# "DroneHubGCS" via QGC_APP_NAME → AndroidManifest %%INSERT_APP_NAME%%. The launcher
# *icon* is branded via a merged package source dir assembled in custom/CMakeLists.txt.
set(QGC_ANDROID_PACKAGE_NAME "org.dronehub.gcs" CACHE STRING "Android Package Name" FORCE)

# CFBundleIconFile fix: core sets the MACOSX_BUNDLE_ICON_FILE *target property*
# (qgroundcontrol/CMakeLists.txt:372) from ${MACOSX_BUNDLE_ICON_FILE} BEFORE it assigns
# that variable at line 379 — so the plist key is configured empty and macOS falls back
# to a generic Dock/Finder icon. CustomOverrides is include()'d at line 27, before line 372,
# so seed the variable here to populate CFBundleIconFile correctly.
set(MACOSX_BUNDLE_ICON_FILE "macx.icns")
