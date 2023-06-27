vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO pypa/wheel
    REF 461f7a3a2d4824009ca4855b3300d61e6d405dc4
    SHA512 05d62636d8fe47d9c00aefb8673ab7e722fc10ae342fd16629340759190e40878a208d9bf4601e58534870c49398767269595a457d8b29d966101cf8da769e4a
    HEAD_REF main
)

pypa_build_and_install_wheel(SOURCE_PATH "${SOURCE_PATH}")