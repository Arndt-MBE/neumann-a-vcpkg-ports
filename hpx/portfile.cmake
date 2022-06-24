

#vcpkg_check_linkage(ONLY_DYNAMIC_CRT)
vcpkg_check_linkage(ONLY_DYNAMIC_LIBRARY)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" HPX_WITH_STATIC_LINKING)
set(VCPKG_POLICY_DLLS_IN_STATIC_LIBRARY "enabled")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO STEllAR-GROUP/hpx
    REF f48c81865800ae72618b40b4e79d4168cfb0bd56
    SHA512 06d1384615b327194d871145c1899317bd350c43a072be2cbfdc773f7869b71aafce3e9cabf835a8fe902a13d7050d5e0400a76f74023985575347a645196b1d
    HEAD_REF stable
    PATCHES
        fix-dependency-hwloc.patch
        #fix_pkg_generation.patch
        format.patch
        tbb.patch
        fix-export.patch
        fix-debug.patch
        fix_output_name_clash.patch
        #fix-dup-symbols.patch
        #fix-static-definition.patch
)
vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
    "zlib"              HPX_WITH_COMPRESSION_ZLIB
    "snappy"            HPX_WITH_COMPRESSION_SNAPPY
    "bzip2"             HPX_WITH_COMPRESSION_BZIP2
    "cuda"              HPX_WITH_CUDA
    "mpi"               HPX_WITH_PARCELPORT_MPI
    "mpi"               HPX_WITH_PARCELPORT_MPI_MULTITHREADED
)

if("jemalloc" IN_LIST FEATURES)
    # jemalloc is preferred to tcmalloc according to the tutorial materials
    # and since it supports more platforms. 
    list(APPEND FEATURE_OPTIONS "-DHPX_WITH_MALLOC:STRING=jemalloc")
endif()

if(NOT VCPKG_TARGET_ARCHITECTURE MATCHES "(x64|x86)")
    list(APPEND FEATURE_OPTIONS "-DHPX_WITH_GENERIC_CONTEXT_COROUTINES=ON")
endif()

file(REMOVE "${SOURCE_PATH}/cmake/FindBZip2.cmake")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DHPX_WITH_VCPKG=ON
        -DHPX_WITH_TESTS=OFF
        -DHPX_WITH_EXAMPLES=OFF
        -DHPX_WITH_TOOLS=OFF
        -DHPX_WITH_RUNTIME=OFF
        -DHPX_USE_CMAKE_CXX_STANDARD=ON
        ${FEATURE_OPTIONS}
        -DHPX_WITH_PKGCONFIG=OFF
        -DHPX_WITH_STATIC_LINKING=${HPX_WITH_STATIC_LINKING}
        #-DHPX_WITH_APEX=ON
        -DHPX_WITH_PARCELPORT_TCP=ON
        -DHPX_WITH_THREAD_TARGET_ADDRESS=ON
        -DHPX_WITH_CHECK_MODULE_DEPENDENCIES=ON
#    OPTIONS_DEBUG
        #-DHPX_WITH_THREAD_LOCAL_STORAGE=ON
        #-DHPX_WITH_THREAD_IDLE_RATES=ON
        #-DHPX_WITH_COROUTINE_COUNTERS=ON
        #-DHPX_WITH_SPINLOCK_DEADLOCK_DETECTION=ON
)
# 
# HPX_WITH_MODULES_AS_STATIC_LIBRARIES ON by default
# HPX_WITH_APEX
vcpkg_cmake_install()

# post build cleanup
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/HPX)

#
file(GLOB_RECURSE CMAKE_FILES "${CURRENT_PACKAGES_DIR}/share/hpx/*.cmake")
foreach(CMAKE_FILE IN LISTS CMAKE_FILES)
    file(READ ${CMAKE_FILE} _contents)
    string(REGEX REPLACE
        "lib/([A-Za-z0-9_.-]+\\.dll)"
        "bin/\\1"
        _contents "${_contents}")
    string(REGEX REPLACE
        "lib/hpx/([A-Za-z0-9_.-]+\\.dll)"
        "bin/hpx/\\1"
        _contents "${_contents}")
    file(WRITE ${CMAKE_FILE} "${_contents}")
endforeach()

vcpkg_replace_string(
    "${CURRENT_PACKAGES_DIR}/share/${PORT}/HPXConfig.cmake"
    "set(HPX_BUILD_TYPE \"Release\")"
    "set(HPX_BUILD_TYPE \"\${CMAKE_BUILD_TYPE}\")")

vcpkg_replace_string(
    "${CURRENT_PACKAGES_DIR}/share/${PORT}/HPXMacros.cmake"
    "set(CMAKE_MODULE_PATH \${CMAKE_MODULE_PATH}"
    "list(APPEND CMAKE_MODULE_PATH")

file(INSTALL
    "${SOURCE_PATH}/LICENSE_1_0.txt"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

vcpkg_fixup_pkgconfig()

vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/bin/hpxcxx" "\"${CURRENT_PACKAGES_DIR}\"" "os.path.dirname(os.path.dirname(os.path.realpath(__file__)))")
vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/bin/hpxcxx" "\"${CURRENT_PACKAGES_DIR}/debug\"" "os.path.dirname(os.path.dirname(os.path.realpath(__file__)))")

file(REMOVE "${CURRENT_PACKAGES_DIR}/bin/hpxcxx" "${CURRENT_PACKAGES_DIR}/debug/bin/hpxcxx")

file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/tools/${PORT}")
file(RENAME "${CURRENT_PACKAGES_DIR}/bin/hpxrun.py" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/hpxrun.py")