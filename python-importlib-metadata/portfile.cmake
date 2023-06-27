vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO python/importlib_metadata
    REF f604d3e462cd11ee071bfcb78b827fb67cc2e537
    SHA512 ea6c3c630deb8aea4fc487f3c2540bd58d2d0b66d828565a8e3e977ec41143c24ef4bc5c39c06c46c9e6efd9f837b090f0d33722471b557d398170ec2ac4cb4d
    HEAD_REF main
)

file(COPY "${SOURCE_PATH}/importlib_metadata" DESTINATION "${CURRENT_PACKAGES_DIR}/tools/python3/Lib/site-packages")