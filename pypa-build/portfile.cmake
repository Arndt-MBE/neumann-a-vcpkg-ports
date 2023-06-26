vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO pypa/build
    REF cd06da25481b9a610f846fa60cb67b5a5fa9a051
    SHA512 02e7021ec3ddd2fa3d5aa3b34193e858ba35d04d36244f1db2e84efbc37fc1f0e118d8ecd32d54ee1feb276e79d753f69979f430ebec7b3e0a0e85e144d1b692
    HEAD_REF main
)

file(COPY "${SOURCE_PATH}/src/build" DESTINATION "${CURRENT_PACKAGES_DIR}/tools/python3/Lib")