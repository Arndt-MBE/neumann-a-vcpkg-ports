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

set(ext ".tar.gz")
if(VCPKG_TARGET_IS_WINDOWS)
    set(platform windows)
    set(ext ".zip")
    
else()
    set(platform linux)
endif()

set(cuDNN-windows-x86_64_HASH 55e7ddac92bbb1e7354ae7f1a2246da079c1147534357594419dcde740308a49854b79154e91b2970f8746c27f9564636cce955a21360cba003b93a786168e1d)
set(cuDNN-linux-x86_64_HASH 0)

vcpkg_download_distfile(
    cudnn
    URLS https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/${platform}-${target}/cudnn-${platform}-${target}-${VERSION}_cuda12-archive${ext}
    FILENAME cudnn-${platform}-${target}-${VERSION}_cuda12-archive${ext}
    SHA512 ${cuDNN-${platform}-${target}_HASH}
)

vcpkg_extract_source_archive(
    cudnn-src
    ARCHIVE ${cudnn}
    SOURCE_BASE "cudnn"
    #BASE_DIRECTORY "CUDA"
    WORKING_DIRECTORY "${CURRENT_PACKAGES_DIR}"
)

file(COPY "${cudnn-src}/" DESTINATION "${CURRENT_PACKAGES_DIR}")
vcpkg_install_copyright(FILE_LIST "${cudnn-src}/LICENSE")
file(REMOVE_RECURSE "${cudnn-src}" "${CURRENT_PACKAGES_DIR}/LICENSE")

if(VCPKG_TARGET_IS_WINDOWS)
    file(RENAME "${CURRENT_PACKAGES_DIR}/lib/x64/" "${CURRENT_PACKAGES_DIR}/lib-tmp/")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib")
    file(RENAME "${CURRENT_PACKAGES_DIR}/lib-tmp" "${CURRENT_PACKAGES_DIR}/lib")
endif()

if(NOT VCPKG_BUILD_TYPE)
    file(COPY "${CURRENT_PACKAGES_DIR}/bin" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/bin")
    file(COPY "${CURRENT_PACKAGES_DIR}/lib" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib")
endif()

file(INSTALL "${CURRENT_PORT_DIR}/FindCUDNN.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${CURRENT_PORT_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${CURRENT_PORT_DIR}/vcpkg-cmake-wrapper.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")