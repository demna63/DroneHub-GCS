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
# GStreamer.framework is installed under /Library/Frameworks, so enable the GStreamer backend.
set(QGC_ENABLE_GST_VIDEOSTREAMING ON                       CACHE BOOL "Enable GStreamer Video Backend" FORCE)

# პლატფორმის icon-ები (არსებობისას) — ჯერ placeholder, F1-ის ბოლოს ჩაისმება.
if(EXISTS ${CMAKE_SOURCE_DIR}/custom/deploy/windows/WindowsQGC.ico)
    set(QGC_WINDOWS_ICON_PATH "${CMAKE_SOURCE_DIR}/custom/deploy/windows/WindowsQGC.ico" CACHE FILEPATH "Windows Icon Path" FORCE)
endif()
if(EXISTS ${CMAKE_SOURCE_DIR}/custom/res/macx.icns)
    set(QGC_MACOS_ICON_PATH "${CMAKE_SOURCE_DIR}/custom/res" CACHE PATH "MacOS Icon Path" FORCE)
endif()
