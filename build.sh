#!/bin/bash
set -e  # Exit immediately if any command fails

# Load required modules
module load GCC/9.3.0 cmake openblas boost openblas loginnode

code_root=$(pwd)

# Clean and build liburing
echo "Cleaning and rebuilding liburing..."
cd "${code_root}/third_party/liburing"
# Optional: add make clean if needed
make clean
./configure
make -j

# Clean and build gperftools
echo "Cleaning gperftools build directory..."
if [ -d "${code_root}/third_party/gperftools/build" ]; then
    echo "Removing existing gperftools build directory..."
    rm -rf "${code_root}/third_party/gperftools/build"
fi

echo "Building gperftools..."
mkdir -p "${code_root}/third_party/gperftools/build"
cd "${code_root}/third_party/gperftools/build"
cmake ..
make -j

# Clean and build main project
export ADDITIONAL_DEFINITIONS="-DDYN_PIPE_WIDTH"

echo "Cleaning main build directory..."
if [ -d "${code_root}/build" ]; then
    echo "Removing existing main build directory..."
    rm -rf "${code_root}/build"
fi

echo "Preparing and building main project..."
mkdir -p "${code_root}/build"
cd "${code_root}/build"
cmake ..
make -j

echo "Build completed successfully!"