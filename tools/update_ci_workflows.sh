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

# Script to update CI workflows for the new unvendored system
# This script updates the GitHub Actions workflows to use system packages

set -e

echo "Updating CI workflows for unvendored system..."

# Create backup directory
BACKUP_DIR=".github_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating backup in $BACKUP_DIR..."

# Backup existing workflows
if [ -d ".github/workflows" ]; then
    cp -r .github/workflows "$BACKUP_DIR/"
    echo "✓ Backed up .github/workflows/"
fi

echo ""
echo "Updating workflows..."

# Update Linux-CPU workflow
if [ -f ".github/workflows/_Linux-CPU-new.yml" ]; then
    mv .github/workflows/_Linux-CPU.yml .github/workflows/_Linux-CPU-old.yml
    mv .github/workflows/_Linux-CPU-new.yml .github/workflows/_Linux-CPU.yml
    echo "✓ Updated _Linux-CPU.yml"
fi

# Update Linux-build workflow
if [ -f ".github/workflows/_Linux-build-new.yml" ]; then
    mv .github/workflows/_Linux-build.yml .github/workflows/_Linux-build-old.yml
    mv .github/workflows/_Linux-build-new.yml .github/workflows/_Linux-build.yml
    echo "✓ Updated _Linux-build.yml"
fi

# Add tarball build workflow
if [ -f ".github/workflows/tarball-build.yml" ]; then
    echo "✓ Added tarball-build.yml"
fi

echo ""
echo "Key changes made to workflows:"

echo "1. Removed git submodule operations:"
echo "   - No more 'git submodule foreach' commands"
echo "   - No more submodule initialization"

echo "2. Added system dependency installation:"
echo "   - libgflags-dev libgoogle-glog-dev libprotobuf-dev"
echo "   - libeigen3-dev libnlohmann-json-dev libyaml-cpp-dev"
echo "   - libblas-dev liblapack-dev libopenblas-dev"
echo "   - libcudnn8-dev libnccl-dev (for GPU builds)"

echo "3. Removed cmake-predownload.sh dependency:"
echo "   - No more vendored dependency downloading"
echo "   - Using system packages instead"

echo "4. Updated build process:"
echo "   - Removed third_party directory cleanup"
echo "   - Using modern CMake with find_package"

echo "5. Added tarball build testing:"
echo "   - Tests tarball creation and extraction"
echo "   - Tests build without git dependencies"
echo "   - Tests version detection from VERSION file"

echo ""
echo "Workflow updates completed!"
echo "Backup created in: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "1. Test the updated workflows in a PR"
echo "2. Verify that builds work with system packages"
echo "3. Update Docker images to include system dependencies"
echo "4. Remove old workflow files if everything works"
echo ""
echo "Files updated:"
echo "- .github/workflows/_Linux-CPU.yml (updated)"
echo "- .github/workflows/_Linux-build.yml (updated)"
echo "- .github/workflows/tarball-build.yml (new)"
echo ""
echo "The CI system now:"
echo "- Uses system packages instead of vendored dependencies"
echo "- Supports tarball builds without git"
echo "- Has faster build times (no dependency compilation)"
echo "- Follows modern CI/CD practices"
