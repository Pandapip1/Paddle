# Copyright (c) 2024 PaddlePaddle Authors. All Rights Reserved.
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

# Modern CMake dependency management using find_package
# This file replaces the vendored third_party dependencies with system packages

# Core dependencies that are commonly available
# Note: Git is not required for tarball builds
find_package(PkgConfig REQUIRED)

# Threading support
find_package(Threads REQUIRED)

# Compression libraries
find_package(ZLIB REQUIRED)

# Logging and flags
find_package(gflags REQUIRED)
find_package(glog REQUIRED)

# Protocol buffers
find_package(Protobuf REQUIRED)

# Linear algebra libraries
# Create a dummy cblas target for compatibility
add_library(cblas INTERFACE)

if(WITH_MKL)
  find_package(MKL REQUIRED)
  set(CBLAS_PROVIDER MKL)
  set(CBLAS_LIBRARIES ${MKL_LIBRARIES})
  set(CBLAS_INC_DIR ${MKL_INCLUDE_DIRS})
  add_definitions(-DPADDLE_WITH_MKL)
  add_definitions(-DLAPACK_FOUND)
  target_link_libraries(cblas INTERFACE ${MKL_LIBRARIES})
elseif(WITH_SYSTEM_BLAS)
  find_package(BLAS REQUIRED)
  find_package(LAPACK REQUIRED)
  set(CBLAS_PROVIDER SYSTEM)
  set(CBLAS_LIBRARIES ${BLAS_LIBRARIES} ${LAPACK_LIBRARIES})
  add_definitions(-DPADDLE_USE_SYSTEM_BLAS)
  add_definitions(-DLAPACK_FOUND)
  target_link_libraries(cblas INTERFACE ${BLAS_LIBRARIES} ${LAPACK_LIBRARIES})
else()
  # Try to find OpenBLAS
  find_package(OpenBLAS QUIET)
  if(OpenBLAS_FOUND)
    set(CBLAS_PROVIDER OPENBLAS)
    set(CBLAS_LIBRARIES ${OpenBLAS_LIBRARIES})
    set(CBLAS_INC_DIR ${OpenBLAS_INCLUDE_DIRS})
    add_definitions(-DPADDLE_USE_OPENBLAS)
    add_definitions(-DLAPACK_FOUND)
    target_link_libraries(cblas INTERFACE ${OpenBLAS_LIBRARIES})
  else()
    # Fallback to reference BLAS
    find_package(BLAS REQUIRED)
    find_package(LAPACK REQUIRED)
    set(CBLAS_PROVIDER REFERENCE)
    set(CBLAS_LIBRARIES ${BLAS_LIBRARIES} ${LAPACK_LIBRARIES})
    add_definitions(-DPADDLE_USE_REFERENCE_BLAS)
    add_definitions(-DLAPACK_FOUND)
    target_link_libraries(cblas INTERFACE ${BLAS_LIBRARIES} ${LAPACK_LIBRARIES})
  endif()
endif()

# Include directories for cblas
if(CBLAS_INC_DIR)
  target_include_directories(cblas INTERFACE ${CBLAS_INC_DIR})
endif()

# Eigen3 for linear algebra
find_package(Eigen3 REQUIRED)

# JSON support
find_package(nlohmann_json REQUIRED)

# YAML support
find_package(yaml-cpp REQUIRED)

# Testing framework
if(WITH_TESTING)
  find_package(GTest REQUIRED)
  enable_testing()
endif()

# Python bindings
if(WITH_PYTHON)
  find_package(Python3 COMPONENTS Interpreter Development REQUIRED)
  find_package(pybind11 REQUIRED)
endif()

# CUDA support
if(WITH_GPU)
  find_package(CUDAToolkit REQUIRED)
  if(CUDAToolkit_FOUND)
    enable_language(CUDA)
    add_definitions(-DPADDLE_WITH_CUDA)
  endif()
endif()

# ROCm support
if(WITH_ROCM)
  find_package(hip REQUIRED)
  find_package(rocblas REQUIRED)
  find_package(rocsparse REQUIRED)
  add_definitions(-DPADDLE_WITH_ROCM)
endif()

# MPI support
if(WITH_MPI)
  find_package(MPI REQUIRED)
  add_definitions(-DPADDLE_WITH_MPI)
endif()

# NCCL for multi-GPU communication
if(WITH_NCCL)
  find_package(nccl REQUIRED)
  add_definitions(-DPADDLE_WITH_NCCL)
endif()

# RCCL for ROCm multi-GPU communication
if(WITH_RCCL)
  find_package(rccl REQUIRED)
  add_definitions(-DPADDLE_WITH_RCCL)
endif()

# TensorRT support
if(WITH_TENSORRT)
  find_package(TensorRT REQUIRED)
  add_definitions(-DPADDLE_WITH_TENSORRT)
endif()

# OpenVINO support
if(WITH_OPENVINO)
  find_package(OpenVINO REQUIRED)
  add_definitions(-DPADDLE_WITH_OPENVINO)
endif()

# OneDNN support
if(WITH_ONEDNN)
  find_package(oneDNN REQUIRED)
  add_definitions(-DPADDLE_WITH_ONEDNN)
endif()

# ONNX Runtime support
if(WITH_ONNXRUNTIME)
  find_package(onnxruntime REQUIRED)
  add_definitions(-DPADDLE_WITH_ONNXRUNTIME)
endif()

# Custom device support
if(WITH_CUSTOM_DEVICE)
  add_definitions(-DPADDLE_WITH_CUSTOM_DEVICE)
endif()

# Create interface targets for compatibility
add_library(paddle_dependencies INTERFACE)

# Link all found dependencies
target_link_libraries(paddle_dependencies INTERFACE
  Threads::Threads
  ZLIB::ZLIB
  gflags
  glog::glog
  protobuf::libprotobuf
  Eigen3::Eigen
  nlohmann_json::nlohmann_json
  yaml-cpp
)

if(WITH_TESTING)
  target_link_libraries(paddle_dependencies INTERFACE
    GTest::gtest
    GTest::gtest_main
    GTest::gmock
  )
endif()

if(WITH_PYTHON)
  target_link_libraries(paddle_dependencies INTERFACE
    Python3::Python
    pybind11::pybind11
  )
endif()

if(WITH_GPU)
  target_link_libraries(paddle_dependencies INTERFACE
    CUDA::cudart
    CUDA::cublas
    CUDA::curand
    CUDA::cufft
  )
endif()

if(WITH_ROCM)
  target_link_libraries(paddle_dependencies INTERFACE
    hip::device
    roc::rocblas
    roc::rocsparse
  )
endif()

if(WITH_MPI)
  target_link_libraries(paddle_dependencies INTERFACE
    MPI::MPI_C
    MPI::MPI_CXX
  )
endif()

if(WITH_NCCL)
  target_link_libraries(paddle_dependencies INTERFACE
    nccl::nccl
  )
endif()

if(WITH_RCCL)
  target_link_libraries(paddle_dependencies INTERFACE
    rccl::rccl
  )
endif()

if(WITH_TENSORRT)
  target_link_libraries(paddle_dependencies INTERFACE
    TensorRT::nvinfer
  )
endif()

if(WITH_OPENVINO)
  target_link_libraries(paddle_dependencies INTERFACE
    openvino::runtime
  )
endif()

if(WITH_ONEDNN)
  target_link_libraries(paddle_dependencies INTERFACE
    dnnl::dnnl
  )
endif()

if(WITH_ONNXRUNTIME)
  target_link_libraries(paddle_dependencies INTERFACE
    onnxruntime::onnxruntime
  )
endif()

# Set CBLAS variables for compatibility
if(CBLAS_PROVIDER STREQUAL "MKL")
  target_link_libraries(paddle_dependencies INTERFACE ${MKL_LIBRARIES})
elseif(CBLAS_PROVIDER STREQUAL "OPENBLAS")
  target_link_libraries(paddle_dependencies INTERFACE ${OpenBLAS_LIBRARIES})
elseif(CBLAS_PROVIDER STREQUAL "SYSTEM")
  target_link_libraries(paddle_dependencies INTERFACE ${BLAS_LIBRARIES} ${LAPACK_LIBRARIES})
elseif(CBLAS_PROVIDER STREQUAL "REFERENCE")
  target_link_libraries(paddle_dependencies INTERFACE ${BLAS_LIBRARIES} ${LAPACK_LIBRARIES})
endif()

# Include directories
target_include_directories(paddle_dependencies INTERFACE
  ${CBLAS_INC_DIR}
  ${Eigen3_INCLUDE_DIRS}
  ${nlohmann_json_INCLUDE_DIRS}
  ${yaml-cpp_INCLUDE_DIRS}
)

if(WITH_PYTHON)
  target_include_directories(paddle_dependencies INTERFACE
    ${Python3_INCLUDE_DIRS}
  )
endif()

# Print configuration summary
message(STATUS "=== PaddlePaddle Dependency Configuration ===")
message(STATUS "CBLAS Provider: ${CBLAS_PROVIDER}")
message(STATUS "CUDA Support: ${WITH_GPU}")
message(STATUS "ROCm Support: ${WITH_ROCM}")
message(STATUS "MPI Support: ${WITH_MPI}")
message(STATUS "NCCL Support: ${WITH_NCCL}")
message(STATUS "TensorRT Support: ${WITH_TENSORRT}")
message(STATUS "OpenVINO Support: ${WITH_OPENVINO}")
message(STATUS "OneDNN Support: ${WITH_ONEDNN}")
message(STATUS "Testing Support: ${WITH_TESTING}")
message(STATUS "Python Support: ${WITH_PYTHON}")
message(STATUS "=============================================")
