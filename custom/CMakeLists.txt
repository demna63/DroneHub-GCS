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

# ქართული თარგმანი (qgc_ka.ts) — core ავტომატურად glob-ავს translations/qgc_*.ts-ს
# (core CMakeLists.txt:531). bootstrap.sh symlink-ავს ჩვენს qgc_ka.ts-ს იქ. აქ wiring საჭირო არ არის.
