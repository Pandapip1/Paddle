# Copyright (c) 2016 PaddlePaddle Authors. All Rights Reserved.
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

# Version detection that works from tarball without git dependency
# This file replaces git-based version detection with static version files

# Check if we're in a git repository (for development builds)
set(IS_GIT_REPO FALSE)
if(EXISTS "${CMAKE_SOURCE_DIR}/.git")
  set(IS_GIT_REPO TRUE)
endif()

# Set default version
set(PADDLE_VERSION $ENV{PADDLE_VERSION})
if(NOT PADDLE_VERSION)
  set(PADDLE_VERSION "0.0.0")
endif()

# Try to read version from VERSION file (for tarball builds)
if(EXISTS "${CMAKE_SOURCE_DIR}/VERSION")
  file(READ "${CMAKE_SOURCE_DIR}/VERSION" VERSION_FILE_CONTENT)
  string(STRIP "${VERSION_FILE_CONTENT}" VERSION_FROM_FILE)
  if(VERSION_FROM_FILE)
    set(PADDLE_VERSION "${VERSION_FROM_FILE}")
    message(STATUS "Using version from VERSION file: ${PADDLE_VERSION}")
  endif()
endif()

# For development builds, try to get version from git if available
if(IS_GIT_REPO AND PADDLE_VERSION STREQUAL "0.0.0")
  find_package(Git QUIET)
  if(Git_FOUND)
    # Try to get version from git tag
    execute_process(
      COMMAND ${GIT_EXECUTABLE} describe --tags --abbrev=0 --always
      WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
      OUTPUT_VARIABLE GIT_TAG_NAME
      RESULT_VARIABLE GIT_RESULT
      ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
    
    if(NOT ${GIT_RESULT} AND GIT_TAG_NAME)
      # Remove 'v' prefix if present
      string(REGEX REPLACE "^v" "" PADDLE_VERSION "${GIT_TAG_NAME}")
      message(STATUS "Using version from git tag: ${PADDLE_VERSION}")
    endif()
  endif()
endif()

# Handle nightly builds
if(WITH_NIGHTLY_BUILD)
  if(IS_GIT_REPO)
    find_package(Git QUIET)
    if(Git_FOUND)
      execute_process(
        COMMAND ${GIT_EXECUTABLE} show -s --format=%ci HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_COMMIT_TIME
        OUTPUT_STRIP_TRAILING_WHITESPACE)
      string(REGEX REPLACE " (.*)$" "" DATE_ONLY "${GIT_COMMIT_TIME}")
      string(REPLACE "-" "" DATE_ONLY "${DATE_ONLY}")
      set(PADDLE_VERSION "${PADDLE_VERSION}.dev${DATE_ONLY}")
    else()
      # Fallback to current date for tarball builds
      string(TIMESTAMP DATE_ONLY "%Y%m%d")
      set(PADDLE_VERSION "${PADDLE_VERSION}.dev${DATE_ONLY}")
    endif()
  else()
    # For tarball builds, use current date
    string(TIMESTAMP DATE_ONLY "%Y%m%d")
    set(PADDLE_VERSION "${PADDLE_VERSION}.dev${DATE_ONLY}")
  endif()
  message(STATUS "Nightly build version: ${PADDLE_VERSION}")
endif()

# Parse version components
string(REPLACE "-" "." PADDLE_VER_LIST ${PADDLE_VERSION})
string(REPLACE "." ";" PADDLE_VER_LIST ${PADDLE_VER_LIST})
list(LENGTH PADDLE_VER_LIST VER_LIST_LENGTH)

if(VER_LIST_LENGTH GREATER_EQUAL 1)
  list(GET PADDLE_VER_LIST 0 PADDLE_MAJOR_VER)
else()
  set(PADDLE_MAJOR_VER "0")
endif()

if(VER_LIST_LENGTH GREATER_EQUAL 2)
  list(GET PADDLE_VER_LIST 1 PADDLE_MINOR_VER)
else()
  set(PADDLE_MINOR_VER "0")
endif()

if(VER_LIST_LENGTH GREATER_EQUAL 3)
  list(GET PADDLE_VER_LIST 2 PADDLE_PATCH_VER)
else()
  set(PADDLE_PATCH_VER "0")
endif()

# Calculate version integer
math(EXPR PADDLE_VERSION_INTEGER "${PADDLE_MAJOR_VER} * 1000000 + ${PADDLE_MINOR_VER} * 1000 + ${PADDLE_PATCH_VER}")

# Set preprocessor definitions
add_definitions(-DPADDLE_VERSION=${PADDLE_VERSION})
add_definitions(-DPADDLE_VERSION_INTEGER=${PADDLE_VERSION_INTEGER})

message(STATUS "Paddle version is ${PADDLE_VERSION}")

# Function to write version information to a file
function(version version_file)
  # Try to get git commit hash if in git repo
  set(PADDLE_GIT_COMMIT "unknown")
  if(IS_GIT_REPO)
    find_package(Git QUIET)
    if(Git_FOUND)
      execute_process(
        COMMAND ${GIT_EXECUTABLE} log --pretty=format:%H -1
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE PADDLE_GIT_COMMIT
        RESULT_VARIABLE GIT_RESULT
        ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
      if(GIT_RESULT)
        set(PADDLE_GIT_COMMIT "unknown")
      endif()
    endif()
  endif()
  
  # Write version information
  file(WRITE ${version_file}
    "Paddle version: ${PADDLE_VERSION}\n"
    "GIT COMMIT ID: ${PADDLE_GIT_COMMIT}\n"
    "WITH_MKL: ${WITH_MKL}\n"
    "WITH_ONEDNN: ${WITH_ONEDNN}\n"
    "WITH_OPENVINO: ${WITH_OPENVINO}\n"
    "WITH_GPU: ${WITH_GPU}\n"
    "WITH_ROCM: ${WITH_ROCM}\n"
    "WITH_IPU: ${WITH_IPU}\n")
  
  if(WITH_GPU)
    file(APPEND ${version_file}
         "CUDA version: ${CUDA_VERSION}\n"
         "CUDNN version: v${CUDNN_MAJOR_VERSION}.${CUDNN_MINOR_VERSION}\n")
  endif()
  
  if(WITH_ROCM)
    file(APPEND ${version_file}
         "HIP version: v${HIP_MAJOR_VERSION}.${HIP_MINOR_VERSION}\n"
         "MIOpen version: v${MIOPEN_MAJOR_VERSION}.${MIOPEN_MINOR_VERSION}\n")
  endif()
  
  if(WITH_IPU)
    file(APPEND ${version_file} "PopART version: ${POPART_VERSION}\n")
  endif()
  
  file(APPEND ${version_file}
       "CXX compiler version: ${CMAKE_CXX_COMPILER_VERSION}\n")
  
  if(TENSORRT_FOUND)
    file(APPEND ${version_file}
      "WITH_TENSORRT: ${TENSORRT_FOUND}\n"
      "TensorRT version: v${TENSORRT_MAJOR_VERSION}.${TENSORRT_MINOR_VERSION}.${TENSORRT_PATCH_VERSION}.${TENSORRT_BUILD_VERSION}\n")
  endif()
endfunction()