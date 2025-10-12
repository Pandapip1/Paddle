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

# Script to clean up obsolete CMake files after unvendoring dependencies
# This script removes files that are no longer needed after switching to system packages

set -e

echo "Cleaning up obsolete CMake files after unvendoring dependencies..."

# Create backup directory
BACKUP_DIR="cmake_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating backup in $BACKUP_DIR..."

# Backup obsolete files before removal
echo "Backing up obsolete files..."

# Backup external directory
if [ -d "cmake/external" ]; then
    cp -r cmake/external "$BACKUP_DIR/"
    echo "✓ Backed up cmake/external/"
fi

# Backup cinn external directory
if [ -d "cmake/cinn/external" ]; then
    cp -r cmake/cinn/external "$BACKUP_DIR/"
    echo "✓ Backed up cmake/cinn/external/"
fi

# Backup obsolete main files
if [ -f "cmake/cblas.cmake" ]; then
    cp cmake/cblas.cmake "$BACKUP_DIR/"
    echo "✓ Backed up cmake/cblas.cmake"
fi

if [ -f "cmake/third_party.cmake" ]; then
    cp cmake/third_party.cmake "$BACKUP_DIR/"
    echo "✓ Backed up cmake/third_party.cmake"
fi

echo ""
echo "Removing obsolete files..."

# Remove external directory
if [ -d "cmake/external" ]; then
    rm -rf cmake/external
    echo "✓ Removed cmake/external/"
fi

# Remove cinn external directory
if [ -d "cmake/cinn/external" ]; then
    rm -rf cmake/cinn/external
    echo "✓ Removed cmake/cinn/external/"
fi

# Remove obsolete main files
if [ -f "cmake/cblas.cmake" ]; then
    rm cmake/cblas.cmake
    echo "✓ Removed cmake/cblas.cmake"
fi

if [ -f "cmake/third_party.cmake" ]; then
    rm cmake/third_party.cmake
    echo "✓ Removed cmake/third_party.cmake"
fi

echo ""
echo "Verifying cleanup..."

# Check for remaining references
echo "Checking for remaining third_party references..."
if grep -r "THIRD_PARTY_PATH" cmake/ 2>/dev/null; then
    echo "⚠️  Warning: Found remaining THIRD_PARTY_PATH references"
else
    echo "✓ No THIRD_PARTY_PATH references found"
fi

echo "Checking for remaining ExternalProject references..."
if grep -r "ExternalProject" cmake/ 2>/dev/null; then
    echo "⚠️  Warning: Found remaining ExternalProject references"
else
    echo "✓ No ExternalProject references found"
fi

echo "Checking for remaining third_party references..."
if grep -r "third_party" cmake/ 2>/dev/null; then
    echo "⚠️  Warning: Found remaining third_party references"
else
    echo "✓ No third_party references found"
fi

echo ""
echo "Cleanup completed!"
echo "Backup created in: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "1. Test the build system: mkdir build && cd build && cmake .. && make -j\$(nproc)"
echo "2. Test tarball creation: ./tools/create_tarball.sh"
echo "3. If issues occur, restore from backup: cp -r $BACKUP_DIR/* cmake/"
echo ""
echo "Files removed:"
echo "- cmake/external/ (entire directory)"
echo "- cmake/cinn/external/ (entire directory)"
echo "- cmake/cblas.cmake"
echo "- cmake/third_party.cmake"
echo ""
echo "The build system now uses:"
echo "- cmake/dependencies.cmake (system packages)"
echo "- cmake/version.cmake (git-free version detection)"
echo "- cmake/inference_lib.cmake (updated for system packages)"
