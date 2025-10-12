# Copyright (c) 2018 PaddlePaddle Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# make package for paddle inference shared and static library
set(PADDLE_INFERENCE_INSTALL_DIR
    "${CMAKE_BINARY_DIR}/paddle_inference_install_dir"
    CACHE STRING "A path setting paddle inference shared and static libraries")

# At present, the size of static lib in Windows is very large,
# so we need to crop the library size.
if(WIN32)
  #todo: remove the option
  option(WITH_STATIC_LIB
         "Compile demo with static/shared library, default use dynamic." OFF)
  if(NOT PYTHON_EXECUTABLE)
    find_package(PythonInterp REQUIRED)
  endif()
endif()

set(COPY_SCRIPT_DIR ${PADDLE_SOURCE_DIR}/cmake)
function(copy TARGET)
  set(options "")
  set(oneValueArgs "")
  set(multiValueArgs SRCS DSTS)
  cmake_parse_arguments(copy_lib "${options}" "${oneValueArgs}"
                        "${multiValueArgs}" ${ARGN})

  list(LENGTH copy_lib_SRCS copy_lib_SRCS_len)
  list(LENGTH copy_lib_DSTS copy_lib_DSTS_len)
  if(NOT ${copy_lib_SRCS_len} EQUAL ${copy_lib_DSTS_len})
    message(
      FATAL_ERROR
        "${TARGET} source numbers are not equal to destination numbers")
  endif()
  math(EXPR len "${copy_lib_SRCS_len} - 1")
  foreach(index RANGE ${len})
    list(GET copy_lib_SRCS ${index} src)
    list(GET copy_lib_DSTS ${index} dst)
    if(WIN32) #windows
      add_custom_command(
        TARGET ${TARGET}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${src} ${dst}
        COMMENT "copy ${src} to ${dst}")
    else() #linux
      add_custom_command(
        TARGET ${TARGET}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${src} ${dst}
        COMMENT "copy ${src} to ${dst}")
    endif()
  endforeach()
endfunction()

# Function to copy system libraries for inference distribution
function(copy_system_libraries TARGET DST)
  # Copy system libraries that are needed for inference
  # This replaces the old third_party copying mechanism
  
  if(WITH_MKL)
    # MKL libraries are handled by the system package
    message(STATUS "MKL libraries will be linked from system installation")
  endif()
  
  if(WITH_GPU)
    # CUDA libraries are handled by the system package
    message(STATUS "CUDA libraries will be linked from system installation")
  endif()
  
  if(WITH_TENSORRT)
    # TensorRT libraries are handled by the system package
    message(STATUS "TensorRT libraries will be linked from system installation")
  endif()
  
  if(WITH_OPENVINO)
    # OpenVINO libraries are handled by the system package
    message(STATUS "OpenVINO libraries will be linked from system installation")
  endif()
  
  if(WITH_ONEDNN)
    # OneDNN libraries are handled by the system package
    message(STATUS "OneDNN libraries will be linked from system installation")
  endif()
  
  if(WITH_ONNXRUNTIME)
    # ONNX Runtime libraries are handled by the system package
    message(STATUS "ONNX Runtime libraries will be linked from system installation")
  endif()
  
  # Copy system libraries that might be needed
  if(WIN32)
    # Windows-specific library copying
    if(WITH_MKL)
      # MKL DLLs might need to be copied on Windows
      find_library(MKL_CORE_LIB mkl_core PATHS ${MKL_LIBRARIES})
      if(MKL_CORE_LIB)
        get_filename_component(MKL_DLL_DIR ${MKL_CORE_LIB} DIRECTORY)
        file(GLOB MKL_DLLS "${MKL_DLL_DIR}/*.dll")
        foreach(dll ${MKL_DLLS})
          copy(${TARGET} SRCS ${dll} DSTS "${DST}/")
        endforeach()
      endif()
    endif()
  endif()
endfunction()

# Set inference library dependencies
set(inference_lib_deps paddle_inference paddle_inference_c
    paddle_inference_shared paddle_inference_static)

# Copy system libraries for inference distribution
copy_system_libraries(inference_lib_dist ${PADDLE_INFERENCE_INSTALL_DIR})

# Create inference library distribution target
add_custom_target(inference_lib_dist ALL)

# Copy paddle inference libraries
copy(inference_lib_dist
     SRCS ${CMAKE_BINARY_DIR}/paddle/fluid/inference/libpaddle_fluid.so
          ${CMAKE_BINARY_DIR}/paddle/fluid/inference/libpaddle_fluid.a
     DSTS ${PADDLE_INFERENCE_INSTALL_DIR}/paddle/lib/
          ${PADDLE_INFERENCE_INSTALL_DIR}/paddle/lib/)

# Copy headers
copy(inference_lib_dist
     SRCS ${PADDLE_SOURCE_DIR}/paddle/fluid/inference/api.h
          ${PADDLE_SOURCE_DIR}/paddle/fluid/inference/api.cc
     DSTS ${PADDLE_INFERENCE_INSTALL_DIR}/paddle/include/
          ${PADDLE_INFERENCE_INSTALL_DIR}/paddle/include/)

# Copy CMake configuration files
copy(inference_lib_dist
     SRCS ${CMAKE_BINARY_DIR}/PaddleConfig.cmake
          ${CMAKE_BINARY_DIR}/PaddleConfigVersion.cmake
     DSTS ${PADDLE_INFERENCE_INSTALL_DIR}/cmake/
          ${PADDLE_INFERENCE_INSTALL_DIR}/cmake/)

# Copy system libraries for C API
copy_system_libraries(inference_lib_dist ${PADDLE_INFERENCE_INSTALL_DIR})

# Create C API distribution
add_custom_target(inference_lib_c_dist ALL)
copy(inference_lib_c_dist
     SRCS ${CMAKE_BINARY_DIR}/paddle/fluid/inference/capi_exp/libpaddle_fluid_c.so
          ${CMAKE_BINARY_DIR}/paddle/fluid/inference/capi_exp/libpaddle_fluid_c.a
     DSTS ${PADDLE_INFERENCE_INSTALL_DIR}/paddle/lib/
          ${PADDLE_INFERENCE_INSTALL_DIR}/paddle/lib/)

# Copy C API headers
copy(inference_lib_c_dist
     SRCS ${PADDLE_SOURCE_DIR}/paddle/fluid/inference/capi_exp/pd_inference_api.h
     DSTS ${PADDLE_INFERENCE_INSTALL_DIR}/paddle/include/)

# Create installation package
if(WIN32)
  # Windows-specific packaging
  set(CPACK_GENERATOR "ZIP")
  set(CPACK_PACKAGE_NAME "paddle_inference")
  set(CPACK_PACKAGE_VERSION ${PADDLE_VERSION})
  set(CPACK_PACKAGE_DIRECTORY ${PADDLE_INFERENCE_INSTALL_DIR})
  include(CPack)
else()
  # Linux/macOS packaging
  set(CPACK_GENERATOR "TGZ")
  set(CPACK_PACKAGE_NAME "paddle_inference")
  set(CPACK_PACKAGE_VERSION ${PADDLE_VERSION})
  set(CPACK_PACKAGE_DIRECTORY ${PADDLE_INFERENCE_INSTALL_DIR})
  include(CPack)
endif()

# Print configuration summary
message(STATUS "=== PaddlePaddle Inference Library Configuration ===")
message(STATUS "Install Directory: ${PADDLE_INFERENCE_INSTALL_DIR}")
message(STATUS "MKL Support: ${WITH_MKL}")
message(STATUS "GPU Support: ${WITH_GPU}")
message(STATUS "TensorRT Support: ${WITH_TENSORRT}")
message(STATUS "OpenVINO Support: ${WITH_OPENVINO}")
message(STATUS "OneDNN Support: ${WITH_ONEDNN}")
message(STATUS "ONNX Runtime Support: ${WITH_ONNXRUNTIME}")
message(STATUS "=====================================================")