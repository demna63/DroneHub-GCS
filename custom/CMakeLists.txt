# DroneHub GCS — custom build module.
# Picked up automatically when configured with -DQGC_CUSTOM_BUILD=ON.

set(QGC_APP_NAME            "DroneHub GCS"        CACHE STRING "" FORCE)
set(QGC_ORG_NAME           "DroneHub Georgia"     CACHE STRING "" FORCE)
set(QGC_ORG_DOMAIN         "dronehub.ge"          CACHE STRING "" FORCE)
set(QGC_APP_DESCRIPTION    "DroneHub Ground Control Station" CACHE STRING "" FORCE)

target_sources(QGCResources INTERFACE)

# Custom plugin sources merged into the QGC target.
target_sources(${QGC_TARGET_NAME}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/CustomPlugin.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/src/CustomPlugin.h
        ${CMAKE_CURRENT_SOURCE_DIR}/src/CustomOptions.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/src/CustomOptions.h
)

target_include_directories(${QGC_TARGET_NAME}
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

# Resource override (logo, theme, fonts, QML view overrides).
qt_add_resources(${QGC_TARGET_NAME} "custom_resources"
    PREFIX "/"
    FILES
        res/DroneHubLogo.svg
        res/fonts/NotoSansGeorgian.ttf
        res/Custom/Theme.qml
)

# Georgian translation compiled into the binary.
qt_add_translations(${QGC_TARGET_NAME}
    TS_FILES ${CMAKE_SOURCE_DIR}/translations/qgc_ka.ts)
