set(base_url "https://developer.download.nvidia.com/compute/cuda/redist")

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(target x86_64)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64" AND VCPKG_TARGET_IS_LINUX)
    set(target sbsa)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "ppc64" AND VCPKG_TARGET_IS_LINUX)
    set(target ppc64le)
else()
    message(FATAL_ERROR "Unsupported architecture")
endif()

if(VCPKG_TARGET_IS_WINDOWS)
    set(platform windows)
else()
    set(platform linux)
endif()

set(components 
        cccl # < contains cmake files
        cudart
        nvtx
        nvml_dev
        nvrtc
        #opencl # OpenCL port should probably own this. 
        profiler_api
        #sanitizer_api
)

set(libs         
        libcublas
        libcufft
        libcurand
        libcusolver
        libcusparse
        libnpp
        libnvjitlink
        libnvjpeg
)

set(util
        #nsight_compute
        #nsight_systems
)

set(tools 
        cuobjdump 
        cupti 
        cuxxfilt # has some extra API
        nvcc
        nvdisasm
        nvprof
        #nvprune
        
        #nvvp
)

if(VCPKG_TARGET_IS_WINDOWS)
    list(APPEND util 
        #nsight_vse
    )
endif()

if(VCPKG_TARGET_IS_LINUX)
    list(APPEND libs 
            fabricmanager 
            libnvidia_nscq 
            nvidia_driver
            libcufile
    )
    list(APPEND util 
            nvidia_fs
    )
    list(APPEND util 
            cuda_gdb
    )
endif()

if(target STREQUAL "sbsa")
    list(REMOVE_ITEM components "opencl")
    list(REMOVE_ITEM tools "nvprof" "nvvp")
elseif(target STREQUAL "ppc64le")
    list(REMOVE_ITEM components "opencl")
    list(REMOVE_ITEM libs "fabricmanager" "libnvidia_nscq" "libcufile")
    list(REMOVE_ITEM util "nvidia_fs")
endif()

list(TRANSFORM components PREPEND "cuda_")
list(TRANSFORM tools PREPEND "cuda_")



set(update_opt "")
#set(cuda_updating 1)
if(cuda_updating)
    set(VCPKG_USE_HEAD_VERSION 1)
    set(update_opt SKIP_SHA512)

    message(STATUS "Running ${PORT} in update mode!")
else()
    include("${CURRENT_PORT_DIR}/hash-${platform}-${target}.cmake")
endif()

vcpkg_download_distfile(
    cuda_redist_json
    URLS ${base_url}/redistrib_${VERSION}.json
    FILENAME cuda-${VERSION}.json
    SHA512 ${cuda-json_HASH}
    ${update_opt}
)

if(cuda_updating)
    file(SHA512 "${cuda_redist_json}" hash)
    string(APPEND update_hash "set(cuda-json_HASH \"${hash}\")\n")
endif()

file(READ "${cuda_redist_json}" cuda_json)

file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/tools/cuda")

set(licenses "")
foreach(comp IN LISTS components libs util tools)
    string(JSON comp_json GET "${cuda_json}" "${comp}")
    string(JSON lic_rel_url GET   "${comp_json}" "license_path")
    string(JSON comp_plat_json GET "${comp_json}" "${platform}-${target}")
    string(JSON comp_plat_rel_url GET "${comp_plat_json}" "relative_path")

    set(lic_url "${base_url}/${lic_rel_url}")
    set(comp_url "${base_url}/${comp_plat_rel_url}")

    vcpkg_download_distfile(
        lic_${comp}
        URLS ${lic_url}
        FILENAME ${lic_rel_url}
        SHA512 ${lic_${comp}_HASH}
        ${update_opt}
    )
    list(APPEND licenses "${lic_${comp}}")
    if(cuda_updating)
        file(SHA512 "${lic_${comp}}" hash)
        string(APPEND update_hash "set(lic_${comp}_HASH \"${hash}\")\n")
    endif()

    cmake_path(GET comp_plat_rel_url FILENAME comp_filename)

    vcpkg_download_distfile(
        ${comp}
        URLS ${comp_url}
        FILENAME ${comp_filename}
        SHA512 ${${comp}_HASH}
        ${update_opt}
    )
    if(cuda_updating)
        file(SHA512 "${${comp}}" hash)
        string(APPEND update_hash "set(${comp}_HASH \"${hash}\")\n")
        continue()
    endif()

    vcpkg_extract_source_archive(
        comp-src
        ARCHIVE ${${comp}}
        SOURCE_BASE "${comp}"
        #BASE_DIRECTORY "CUDA"
        WORKING_DIRECTORY "${CURRENT_PACKAGES_DIR}/tools"
    )

    if("${comp}" IN_LIST components OR "${comp}" IN_LIST libs)
        file(COPY "${comp-src}/" DESTINATION "${CURRENT_PACKAGES_DIR}"
            PATTERN "*docs*" EXCLUDE
            PATTERN "*samples*" EXCLUDE
            PATTERN "*exsample*" EXCLUDE
            PATTERN "src/*" EXCLUDE
            PATTERN "LICENSE" EXCLUDE
        )
        # Need a duplicate since nvcc won't magically add new unknown search paths for stuff
        file(COPY "${comp-src}/" DESTINATION "${CURRENT_PACKAGES_DIR}/tools/cuda"
            PATTERN "*docs*" EXCLUDE
            PATTERN "*samples*" EXCLUDE
            PATTERN "*exsample*" EXCLUDE
            PATTERN "LICENSE" EXCLUDE
        )
    else()
        file(COPY "${comp-src}/" DESTINATION "${CURRENT_PACKAGES_DIR}/tools/cuda"
            PATTERN "*docs*" EXCLUDE
            PATTERN "*samples*" EXCLUDE
            PATTERN "*exsample*" EXCLUDE
            PATTERN "LICENSE" EXCLUDE
        )
    endif()
    file(REMOVE_RECURSE "${comp-src}")
endforeach()

if(cuda_updating)
    file(WRITE "${CURRENT_PORT_DIR}/new_hash-${platform}-${target}.cmake" "${update_hash}\n")
    message(FATAL_ERROR "New hashes obtained!")
endif()

file(COPY "${CURRENT_PACKAGES_DIR}/lib/cmake/" DESTINATION "${CURRENT_PACKAGES_DIR}/share/")
vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/cub/cub-header-search.cmake" "lib/cmake/cub" "share/cub")
vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/thrust/thrust-header-search.cmake" "lib/cmake/thrust" "share/thrust")
vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/libcudacxx/libcudacxx-header-search.cmake" "../../../" "../../")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib/cmake/")

if(VCPKG_TARGET_IS_WINDOWS)
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib/Win32")
    file(RENAME "${CURRENT_PACKAGES_DIR}/lib/x64/" "${CURRENT_PACKAGES_DIR}/lib-tmp/")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib")
    file(RENAME "${CURRENT_PACKAGES_DIR}/lib-tmp" "${CURRENT_PACKAGES_DIR}/lib")
endif()

if(NOT VCPKG_BUILD_TYPE)
    file(COPY "${CURRENT_PACKAGES_DIR}/bin" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/bin")
    file(COPY "${CURRENT_PACKAGES_DIR}/lib" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib")
endif()

file(REMOVE_RECURSE 
    "${CURRENT_PACKAGES_DIR}/include/cub/cmake"
    "${CURRENT_PACKAGES_DIR}/include/thrust/cmake"
    "${CURRENT_PACKAGES_DIR}/src"
)

file(REMOVE_RECURSE 
    "${CURRENT_PACKAGES_DIR}/tools/cuda/include/cub/cmake"
    "${CURRENT_PACKAGES_DIR}/tools/cuda/include/thrust/cmake"
)

vcpkg_install_copyright(FILE_LIST ${licenses})

file(COPY "${CMAKE_CURRENT_LIST_DIR}/vcpkg-port-config.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
configure_file("${CMAKE_CURRENT_LIST_DIR}/vcpkg_find_cuda.cmake" "${CURRENT_PACKAGES_DIR}/share/${PORT}//vcpkg_find_cuda.cmake" @ONLY)
