vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO pypa/hatch
    REF 46a2118ba39c00ca102cf463bdc829301402d05b
    SHA512 82cd572e01c8380e938477c2f9588f1e1c172b10e7b85a99715cd299446c9de96973def85f75b868f2458d216582bf6c1120ce005f3bac4a68404c714648214b
    HEAD_REF master
)


pypa_build_and_install_wheel(SOURCE_PATH "${SOURCE_PATH}")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")

