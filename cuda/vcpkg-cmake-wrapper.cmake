set(CUDA_TOOLKIT_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/../../tools/cuda" CACHE "FILEPATH" "" FORCE)
set(CUDAToolkit_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../tools/cuda")
_find_package(${ARGS})
