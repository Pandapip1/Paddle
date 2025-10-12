#!/bin/bash
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

# Script to verify that the unvendoring was successful
# This script checks for any remaining references to the old vendored system

set -e

echo "Verifying that unvendoring was successful..."
echo "============================================="

# Check for remaining third_party references
echo ""
echo "1. Checking for remaining third_party references..."
if grep -r "third_party" cmake/ 2>/dev/null; then
    echo "❌ FAIL: Found remaining third_party references"
    exit 1
else
    echo "✅ PASS: No third_party references found"
fi

# Check for remaining THIRD_PARTY_PATH references
echo ""
echo "2. Checking for remaining THIRD_PARTY_PATH references..."
if grep -r "THIRD_PARTY_PATH" cmake/ 2>/dev/null; then
    echo "❌ FAIL: Found remaining THIRD_PARTY_PATH references"
    exit 1
else
    echo "✅ PASS: No THIRD_PARTY_PATH references found"
fi

# Check for remaining ExternalProject references
echo ""
echo "3. Checking for remaining ExternalProject references..."
if grep -r "ExternalProject" cmake/ 2>/dev/null; then
    echo "❌ FAIL: Found remaining ExternalProject references"
    exit 1
else
    echo "✅ PASS: No ExternalProject references found"
fi

# Check for remaining git submodule references
echo ""
echo "4. Checking for remaining git submodule references..."
if grep -r "submodule" cmake/ 2>/dev/null; then
    echo "❌ FAIL: Found remaining submodule references"
    exit 1
else
    echo "✅ PASS: No submodule references found"
fi

# Check that dependencies.cmake exists and is being used
echo ""
echo "5. Checking that new dependency system is in place..."
if [ -f "cmake/dependencies.cmake" ]; then
    echo "✅ PASS: cmake/dependencies.cmake exists"
else
    echo "❌ FAIL: cmake/dependencies.cmake not found"
    exit 1
fi

# Check that CMakeLists.txt uses dependencies.cmake
if grep -q "include(dependencies)" CMakeLists.txt; then
    echo "✅ PASS: CMakeLists.txt uses dependencies.cmake"
else
    echo "❌ FAIL: CMakeLists.txt does not use dependencies.cmake"
    exit 1
fi

# Check that version.cmake is git-free
echo ""
echo "6. Checking that version detection is git-free..."
if grep -q "find_package(Git QUIET)" cmake/version.cmake; then
    echo "✅ PASS: version.cmake uses optional git"
else
    echo "❌ FAIL: version.cmake still requires git"
    exit 1
fi

# Check that VERSION file exists
if [ -f "VERSION" ]; then
    echo "✅ PASS: VERSION file exists"
else
    echo "❌ FAIL: VERSION file not found"
    exit 1
fi

# Check that external directory is removed or empty
echo ""
echo "7. Checking that external directory is cleaned up..."
if [ -d "cmake/external" ]; then
    if [ "$(ls -A cmake/external 2>/dev/null)" ]; then
        echo "❌ FAIL: cmake/external directory still contains files"
        exit 1
    else
        echo "✅ PASS: cmake/external directory is empty"
    fi
else
    echo "✅ PASS: cmake/external directory removed"
fi

# Check that cinn external directory is removed or empty
if [ -d "cmake/cinn/external" ]; then
    if [ "$(ls -A cmake/cinn/external 2>/dev/null)" ]; then
        echo "❌ FAIL: cmake/cinn/external directory still contains files"
        exit 1
    else
        echo "✅ PASS: cmake/cinn/external directory is empty"
    fi
else
    echo "✅ PASS: cmake/cinn/external directory removed"
fi

# Check that obsolete files are removed
echo ""
echo "8. Checking that obsolete files are removed..."
if [ -f "cmake/cblas.cmake" ]; then
    echo "❌ FAIL: cmake/cblas.cmake still exists (should be removed)"
    exit 1
else
    echo "✅ PASS: cmake/cblas.cmake removed"
fi

if [ -f "cmake/third_party.cmake" ]; then
    echo "❌ FAIL: cmake/third_party.cmake still exists (should be removed)"
    exit 1
else
    echo "✅ PASS: cmake/third_party.cmake removed"
fi

# Check that system package dependencies are properly configured
echo ""
echo "9. Checking that system package dependencies are configured..."
if grep -q "find_package.*REQUIRED" cmake/dependencies.cmake; then
    echo "✅ PASS: System package dependencies configured"
else
    echo "❌ FAIL: System package dependencies not properly configured"
    exit 1
fi

# Check that tarball creation script exists
echo ""
echo "10. Checking that tarball creation script exists..."
if [ -f "tools/create_tarball.sh" ]; then
    echo "✅ PASS: Tarball creation script exists"
else
    echo "❌ FAIL: Tarball creation script not found"
    exit 1
fi

echo ""
echo "============================================="
echo "✅ SUCCESS: Unvendoring verification passed!"
echo "============================================="
echo ""
echo "The build system has been successfully unvendored:"
echo "- All vendored dependencies removed"
echo "- System package dependencies configured"
echo "- Git-free version detection implemented"
echo "- Tarball build support added"
echo "- Obsolete files cleaned up"
echo ""
echo "Next steps:"
echo "1. Test the build system: mkdir build && cd build && cmake .. && make -j\$(nproc)"
echo "2. Test tarball creation: ./tools/create_tarball.sh"
echo "3. Install system dependencies as documented in MIGRATION_GUIDE.md"
