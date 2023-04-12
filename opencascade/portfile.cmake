vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Open-Cascade-SAS/OCCT
    REF 185d29b92f6764ffa9fc195b7dbe7bba3c4ac855 #V7.7.0
    SHA512 837b8a8d5163647bdd1689c7afbf8774fad8525b411213fc53ee5892336e9f7a02947ef6bf12f86ab09e016e7f96c2f9f9470790e61efc0155f172a05d54cf0f
    HEAD_REF master
    PATCHES
        #fix-pdb-find.patch
        #fix-install-prefix-path.patch
        #install-include-dir.patch
        #fix-depend-freetype.patch
)

if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    set(BUILD_TYPE "Shared")
else()
    set(BUILD_TYPE "Static")
endif()

list(APPEND FEATURE_OPTIONS -DUSE_FREETYPE=ON)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        "freeimage"  USE_FREEIMAGE
        "tbb"        USE_TBB
        "rapidjson"  USE_RAPIDJSON
        "vtk"        USE_VTK
        #"ffmpeg"     USE_FFMPEG # NOt ready for ffmpeg 5
        #"openvr"     USE_OPENVR
        "draco"      USE_DRACO
)

if(VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
  list(APPEND FEATURE_OPTIONS -DUSE_D3D=ON)
endif()

# We turn off BUILD_MODULE_Draw as it requires TCL 8.6 and TK 8.6 specifically which conflicts with vcpkg only having TCL 9.0 
# And pre-built ActiveTCL binaries are behind a marketing wall :(
# We use the Unix install layout for Windows as it matches vcpkg
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DBUILD_LIBRARY_TYPE=${BUILD_TYPE}
        -DBUILD_MODULE_Draw=OFF
        -DINSTALL_DIR_LAYOUT=Unix
        -DBUILD_SAMPLES_MFC=OFF
        -DBUILD_SAMPLES_QT=OFF
        -DBUILD_DOC_Overview=OFF
        -DINSTALL_TEST_CASES=OFF
        -DINSTALL_SAMPLES=OFF
        "-D3RDPARTY_TBB_DIR=${CURRENT_INSTALLED_DIR}/share/tbb"
        #"-D3RDPARTY_VTK_INCLUDE_DIR=${CURRENT_INSTALLED_DIR}/include/vtk-9.2"
        "-D3RDPARTY_VTK_INCLUDE_DIR=${CURRENT_INSTALLED_DIR}/include/draco"
        #--trace-expand
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/opencascade)
#file(READ "${CURRENT_PACKAGES_DIR}/share/opencascade/OpenCASCADEConfig.cmake" contents)
#file(WRITE "${CURRENT_PACKAGES_DIR}/share/opencascade/OpenCASCADEConfig.cmake" "${contents}\nif(OpenCASCADE_WITH_FREETYPE)\nfind_dependency(freetype CONFIG)\nendif()\n")

#make occt includes relative to source_file
list(APPEND ADDITIONAL_HEADERS 
      "ExprIntrp.tab.h"
      "FlexLexer.h"
      "glext.h"
      "igesread.h"
      "NCollection_Haft.h"
      "OSD_PerfMeter.h"
      "Standard_values.h"
    )

file(GLOB files "${CURRENT_PACKAGES_DIR}/include/opencascade/[a-zA-Z0-9_]*\.[hgl]xx")
foreach(file_name IN LISTS files)
    file(READ "${file_name}" filedata)
    string(REGEX REPLACE "# *include \<([a-zA-Z0-9_]*\.[hgl]xx)\>" "#include \"\\1\"" filedata "${filedata}")
    foreach(extra_header IN LISTS ADDITIONAL_HEADERS)
        string(REGEX REPLACE "# *include \<${extra_header}\>" "#include \"${extra_header}\"" filedata "${filedata}")
    endforeach()
    file(WRITE "${file_name}" "${filedata}")
endforeach()

# Remove libd to lib, libd just has cmake files we dont want too
if( WIN32 )
  file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/lib")
  if(NOT VCPKG_BUILD_TYPE)
    file(RENAME "${CURRENT_PACKAGES_DIR}/debug/libd" "${CURRENT_PACKAGES_DIR}/debug/lib")
  endif()
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic AND NOT VCPKG_BUILD_TYPE)
    # debug creates libd and bind directories that need moving
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/bin")
    file(RENAME "${CURRENT_PACKAGES_DIR}/debug/bind" "${CURRENT_PACKAGES_DIR}/debug/bin")
    
    # fix paths in target files
    list(APPEND TARGET_FILES 
        "${CURRENT_PACKAGES_DIR}/share/opencascade/OpenCASCADEApplicationFrameworkTargets-debug.cmake"
        "${CURRENT_PACKAGES_DIR}/share/opencascade/OpenCASCADECompileDefinitionsAndFlags-debug.cmake"
        "${CURRENT_PACKAGES_DIR}/share/opencascade/OpenCASCADEDataExchangeTargets-debug.cmake"
        "${CURRENT_PACKAGES_DIR}/share/opencascade/OpenCASCADEFoundationClassesTargets-debug.cmake"
        "${CURRENT_PACKAGES_DIR}/share/opencascade/OpenCASCADEModelingAlgorithmsTargets-debug.cmake"
        "${CURRENT_PACKAGES_DIR}/share/opencascade/OpenCASCADEModelingDataTargets-debug.cmake"
        "${CURRENT_PACKAGES_DIR}/share/opencascade/OpenCASCADEVisualizationTargets-debug.cmake"
    )
    
    foreach(TARGET_FILE IN LISTS TARGET_FILES)
        file(READ "${TARGET_FILE}" filedata)
        string(REGEX REPLACE "libd" "lib" filedata "${filedata}")
        string(REGEX REPLACE "bind" "bin" filedata "${filedata}")
        file(WRITE "${TARGET_FILE}" "${filedata}")
    endforeach()

    # the bin directory ends up with bat files that are noise, let's clean that up
    file(GLOB BATS "${CURRENT_PACKAGES_DIR}/bin/*.bat")
    file(REMOVE_RECURSE ${BATS})
elseif(VCPKG_LIBRARY_LINKAGE STREQUAL static)
    # remove scripts in bin dir
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()

file(READ "${CURRENT_PACKAGES_DIR}/share/opencascade/OpenCASCADEConfig.cmake" contents)
file(WRITE "${CURRENT_PACKAGES_DIR}/share/opencascade/OpenCASCADEConfig.cmake" "include(CMakeFindDependencyMacro)\n${contents}")

file(INSTALL "${SOURCE_PATH}/OCCT_LGPL_EXCEPTION.txt" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
