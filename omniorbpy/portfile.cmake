vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_download_distfile(ARCHIVE
    URLS "https://netcologne.dl.sourceforge.net/project/omniorb/omniORBpy/omniORBpy-4.3.0/omniORBpy-4.3.0.tar.bz2"
    FILENAME "omniORBpy-${VERSION}.tar.bz2"
    SHA512 473db7085267ba9d014ec768e6fdd8fce04aa6e30ca3d9bd5f97a2eb504e12b78e3d4fde2d7bc5dc3df5a3ca062a9a8426689554bec707fa4732657a594ade38
)
vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES wip.patch
)


vcpkg_add_to_path("${CURRENT_HOST_INSTALLED_DIR}/tools/python3") # port ask python distutils for info.
vcpkg_add_to_path("${CURRENT_HOST_INSTALLED_DIR}/tools/omniorb/bin")
set(ENV{PYTHONPATH} "${CURRENT_HOST_INSTALLED_DIR}/${PYTHON3_SITE};${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/lib/python;${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/lib/python")

file(COPY "${CURRENT_INSTALLED_DIR}/share/omniorb/idl/omniORB/" DESTINATION "${SOURCE_PATH}/idl")

if(VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
  set(z_vcpkg_org_linkage "${VCPKG_LIBRARY_LINKAGE}") 
  # convoluted build system; shared builds requires 
  # static library to create def file for symbol export
  # tools seem to only dynamically link on windows due to make rules!
  set(VCPKG_LIBRARY_LINKAGE dynamic)
  z_vcpkg_get_cmake_vars(cmake_vars_file)
  include("${cmake_vars_file}")
  if(VCPKG_BUILD_TYPE)
    string(APPEND build_info "NoDebugBuild=1\n")
  endif()
  string(APPEND build_info "replace-with-per-config-text\n")
  set(progs C_COMPILER CXX_COMPILER AR
            LINKER RANLIB OBJDUMP MT
            STRIP NM DLLTOOL RC_COMPILER)
  list(TRANSFORM progs PREPEND "VCPKG_DETECTED_CMAKE_")
  foreach(prog IN LISTS progs)
      if(${prog})
          set(path "${${prog}}")
          unset(prog_found CACHE)
          get_filename_component(${prog} "${${prog}}" NAME)
          find_program(prog_found ${${prog}} PATHS ENV PATH NO_DEFAULT_PATH)
          if(NOT path STREQUAL prog_found)
              get_filename_component(path "${path}" DIRECTORY)
              vcpkg_add_to_path(PREPEND ${path})
          endif()
      endif()
  endforeach()
  configure_file("${CMAKE_CURRENT_LIST_DIR}/vcpkg.mk" "${SOURCE_PATH}/mk/vcpkg.mk" @ONLY NEWLINE_STYLE UNIX)
endif()

vcpkg_configure_make(
  SOURCE_PATH "${SOURCE_PATH}"
  AUTOCONFIG
  NO_WRAPPERS
  COPY_SOURCE
  OPTIONS
    --with-omniorb=${CURRENT_INSTALLED_DIR}/tools/omniorb
)

vcpkg_install_make(
  MAKEFILE "GNUMakefile"
  ADD_BIN_TO_PATH
)

file(GLOB_RECURSE pyd_files "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/*.pyd" "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/*.pdb")
file(COPY ${pyd_files}  DESTINATION "${CURRENT_PACKAGES_DIR}/bin")
file(GLOB_RECURSE pyd_files "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/*.lib")
file(COPY ${pyd_files}  DESTINATION "${CURRENT_PACKAGES_DIR}/lib" PATTERN EXCLUDE "COPYING.lib")

if(NOT VCPKG_BUILD_TYPE)
  file(GLOB_RECURSE pyd_files "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/*.pyd" "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/*.pdb")
  file(COPY ${pyd_files}  DESTINATION "${CURRENT_PACKAGES_DIR}/debug/bin")
  file(GLOB_RECURSE pyd_files "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/*.lib")
  file(COPY ${pyd_files}  DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib" PATTERN EXCLUDE "COPYING.lib")
endif()

vcpkg_fixup_pkgconfig()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.LIB") # Lib is LGPL

#file(REMOVE lib/python3.11/site-packages)



file(REMOVE_RECURSE 
      "${CURRENT_PACKAGES_DIR}/debug/share"
      "${CURRENT_PACKAGES_DIR}/debug/tools/python3/lib/site-packages/omniidl_be/__init__.py"
      "${CURRENT_PACKAGES_DIR}/debug/tools/python3/lib/site-packages/omniidl_be/__pycache__"
      "${CURRENT_PACKAGES_DIR}/tools/python3/lib/site-packages/omniidl_be/__init__.py"
      "${CURRENT_PACKAGES_DIR}/tools/python3/lib/site-packages/omniidl_be/__pycache__"
    )
