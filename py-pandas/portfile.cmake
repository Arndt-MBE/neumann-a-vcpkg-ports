vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO pandas-dev/pandas
    REF v${VERSION}
    SHA512 17c481a596d74107b13c5082322e3602f9393e1db9a7950f837cb193cb9e62672904db2662cbbac5e590abd93785459f908c01cfbde19bebe38f6d65956a4763
    HEAD_REF main
)

set(PYTHON3 "${CURRENT_HOST_INSTALLED_DIR}/tools/python3/python${VCPKG_HOST_EXECUTABLE_SUFFIX}")

vcpkg_configure_meson(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS 
    ADDITIONAL_BINARIES
      cython=['${CURRENT_HOST_INSTALLED_DIR}/tools/python3/Scripts/cython${VCPKG_HOST_EXECUTABLE_SUFFIX}']
      python3=['${CURRENT_HOST_INSTALLED_DIR}/tools/python3/python${VCPKG_HOST_EXECUTABLE_SUFFIX}']
      python=['${CURRENT_HOST_INSTALLED_DIR}/tools/python3/python${VCPKG_HOST_EXECUTABLE_SUFFIX}']
    )
vcpkg_install_meson()
vcpkg_fixup_pkgconfig()


if(VCPKG_TARGET_IS_WINDOWS)
    file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/${PYTHON3_SITE}/")
    file(RENAME "${CURRENT_PACKAGES_DIR}/lib/site-packages/pandas" "${CURRENT_PACKAGES_DIR}/${PYTHON3_SITE}/pandas")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib")
endif()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/tools/python3/Lib/site-packages/pandas/tests/io/data"
    "${CURRENT_PACKAGES_DIR}/tools/python3/Lib/site-packages/pandas/tests/io/json/data"
    "${CURRENT_PACKAGES_DIR}/tools/python3/Lib/site-packages/pandas/tests/io/sas/data"
    "${CURRENT_PACKAGES_DIR}/tools/python3/Lib/site-packages/pandas/tests/reshape/data"
    "${CURRENT_PACKAGES_DIR}/tools/python3/Lib/site-packages/pandas/tests/reshape/merge/data"
    "${CURRENT_PACKAGES_DIR}/tools/python3/Lib/site-packages/pandas/tests/tseries/offsets/data"
    "${CURRENT_PACKAGES_DIR}/tools/python3/Lib/site-packages/pandas/tests/io/formats/data/html"
    "${CURRENT_PACKAGES_DIR}/tools/python3/Lib/site-packages/pandas/tests/io/formats/data"
)

file(WRITE "${CURRENT_PACKAGES_DIR}/tools/python3/Lib/site-packages/pandas-${VERSION}.dist-info/METADATA"
"Metadata-Version: 2.1\n\
Name: pandas\n\
Version: ${VERSION}\n"
)

set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

vcpkg_python_test_import(MODULE "pandas")

#warning: File E:\all\vcpkg\installed\x64-windows-release\tools/python3/Lib/site-packages/pandas/core/arrays/arrow/__pycache__/_arrow_utils.cpython-311.pyc was already present and will be overwritten