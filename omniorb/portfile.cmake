vcpkg_download_distfile(ARCHIVE
    URLS "https://netcologne.dl.sourceforge.net/project/omniorb/omniORB/omniORB-4.3.0/omniORB-4.3.0.tar.bz2"
    FILENAME "omniORB-${VERSION}.tar.bz2"
    SHA512 b081c1acbea3c7bee619a288fec209a0705b7d436f8e5fd4743675046356ef271a8c75882334fcbde4ff77d15f54d2da55f6cfcd117b01e42919d04fd29bfe2f
)
vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES fix_dependency.patch
            def_gen_fix.patch
            wip.patch
            wip2.patch
            wip5.patch
            wip7.patch
            wip8.patch
)

vcpkg_add_to_path("${CURRENT_HOST_INSTALLED_DIR}/tools/python3") # port ask python distutils for info.
set(ENV{PYTHONPATH} "${CURRENT_HOST_INSTALLED_DIR}/tools/python3/Lib;${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/lib/python;${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/lib/python")

vcpkg_find_acquire_program(FLEX)
cmake_path(GET FLEX PARENT_PATH FLEX_DIR)
vcpkg_add_to_path("${FLEX_DIR}")

vcpkg_find_acquire_program(BISON)
cmake_path(GET BISON PARENT_PATH BISON_DIR)
vcpkg_add_to_path("${BISON_DIR}")

#string(APPEND VCPKG_C_FLAGS_DEBUG " -D_DEBUG") # for python to autolink the correct lib
#string(APPEND VCPKG_CXX_FLAGS_DEBUG " -D_DEBUG")

if(VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
  set(z_vcpkg_org_linkage "${VCPKG_LIBRARY_LINKAGE}") 
  # convoluted build system; shared builds requires 
  # static library to create def file for symbol export
  # tools seem to only dynamically link on windows due to make rules!
  set(VCPKG_LIBRARY_LINKAGE dynamic)
  #string(APPEND " -DHAVE_VPRINTF")
  #string(APPEND VCPKG_LINKER_FLAGS " -v -fuse-ld=lld-link")
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
  configure_file("${CMAKE_CURRENT_LIST_DIR}/vcpkg.mk" "${SOURCE_PATH}/mk/platforms/vcpkg.mk" @ONLY NEWLINE_STYLE UNIX)
  file(GLOB_RECURSE wrappers "${SOURCE_PATH}/bin/x86_win32/*")
  file(COPY ${wrappers} DESTINATION "${SOURCE_PATH}/bin")
endif()

vcpkg_configure_make(
  SOURCE_PATH "${SOURCE_PATH}"
  AUTOCONFIG
  NO_WRAPPERS
  COPY_SOURCE
  OPTIONS
    ac_cv_prog_cc_g=yes
    ac_cv_prog_cxx_11=no
    ac_cv_prog_cxx_g=yes
    omni_cv_sync_add_and_fetch=no
)

vcpkg_replace_string("${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel//mk/platforms/vcpkg.mk" "replace-with-per-config-text" "NoDebugBuild=1")
if(NOT VCPKG_BUILD_TYPE)
  vcpkg_replace_string("${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/mk/platforms/vcpkg.mk" "replace-with-per-config-text" "NoReleaseBuild=1\nBuildDebugBinary=1")
  vcpkg_replace_string("${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/src/tool/omniidl/cxx/dir.mk" "python$(subst .,,$(PYVERSION)).lib" "python$(subst .,,$(PYVERSION))_d.lib")
endif()

vcpkg_install_make(
  MAKEFILE "GNUMakefile"
  ADD_BIN_TO_PATH
)

vcpkg_fixup_pkgconfig()

if(VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
  file(COPY "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/lib/msvcstub.lib" DESTINATION "${CURRENT_PACKAGES_DIR}/lib")
  file(GLOB all_libs "${CURRENT_PACKAGES_DIR}/lib/*.lib")
  set(import_libs "${all_libs}")
  list(FILTER import_libs INCLUDE REGEX "(_rt.lib$|msvcstub)")
  if(z_vcpkg_org_linkage STREQUAL "static")
    file(REMOVE ${import_libs})
  else()
    list(REMOVE_ITEM all_libs ${import_libs})
    file(REMOVE ${all_libs}) # remove installed static libs
    set(to_copy_and_rename ${import_libs})
    list(FILTER to_copy_and_rename INCLUDE REGEX "3(0)?_rt.lib")
    foreach(cp IN LISTS to_copy_and_rename)
      string(REGEX REPLACE "3(0)?_rt" "" new_name "${cp}")
      string(REGEX REPLACE "thread4" "thread" new_name "${new_name}")
      configure_file("${cp}" "${new_name}" COPYONLY)
    endforeach()
    file(GLOB dll_files "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bin/*.dll")
    file(COPY ${dll_files} DESTINATION "${CURRENT_PACKAGES_DIR}/bin")
    file(GLOB pc_files "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/*.pc")
    foreach(pc_file IN LISTS pc_files)
      get_filename_component(filename "${pc_file}" NAME_WE)
      if(filename STREQUAL "omnithread3")
        vcpkg_replace_string("${pc_file}" "-lomnithread" "-lomnithread_rt")
      else()
        vcpkg_replace_string("${pc_file}" "-l${filename}" "-l${filename}_rt")
      endif()
    endforeach()
  endif()

  if(NOT VCPKG_BUILD_TYPE) # dbg libs have no install rules so manually copy them.
    file(GLOB all_libs "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/lib/*.lib")
    set(install_libs "${all_libs}")
    if(z_vcpkg_org_linkage STREQUAL "static")
      list(FILTER install_libs EXCLUDE REGEX "(_rtd.lib$|msvcstub)")
    else() # dynamic lib
      list(FILTER install_libs INCLUDE REGEX "(_rtd.lib$|msvcstub)")
      set(to_copy_and_rename ${install_libs})
      list(FILTER to_copy_and_rename INCLUDE REGEX "3(0)?_rtd.lib")
      #list(REMOVE_ITEM install_libs ${to_copy_and_rename})
      foreach(cp IN LISTS to_copy_and_rename)
        string(REGEX REPLACE "3(0)?_rt" "" new_name "${cp}")
        string(REGEX REPLACE "thread4" "thread" new_name "${new_name}")
        configure_file("${cp}" "${new_name}" COPYONLY)
        list(APPEND install_libs "${new_name}")
      endforeach()
      file(GLOB dll_files "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/bin/*.dll")
      file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/debug/bin")
      file(COPY ${dll_files} DESTINATION "${CURRENT_PACKAGES_DIR}/debug/bin")
      file(GLOB pc_files "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/*.pc")
      foreach(pc_file IN LISTS pc_files)
        get_filename_component(filename "${pc_file}" NAME_WE)
        if(filename STREQUAL "omnithread3")
          vcpkg_replace_string("${pc_file}" "-lomnithread" "-lomnithread_rtd")
        else()
          vcpkg_replace_string("${pc_file}" "-l${filename}" "-l${filename}_rtd")
        endif()
      endforeach()
    endif()
    file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/debug/lib")
    file(COPY ${install_libs} DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib")
  endif()
endif()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.LIB") # Lib is LGPL
file(INSTALL "${SOURCE_PATH}/COPYING" DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin" RENAME copyright) # Tools etc are GPL

vcpkg_copy_pdbs()

file(COPY
      "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bin/omnicpp${VCPKG_TARGET_EXECUTABLE_SUFFIX}"
      "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bin/omniidl${VCPKG_TARGET_EXECUTABLE_SUFFIX}"
    DESTINATION
      "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin"
    )

vcpkg_copy_tool_dependencies("${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin")

# Restore old linkage info. 
if(VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
   set(VCPKG_LIBRARY_LINKAGE ${z_vcpkg_org_linkage})
endif()


file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
