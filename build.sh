set -e

module load GCC/9.3.0 cmake openblas boost openblas loginnode

code_root=$(pwd)

cd $code_root/third_party/liburing
./configure
make -j

mkdir $code_root/third_party/gperftools/build
cd $code_root/third_party/gperftools/build
cmake ..
make -j

export ADDITIONAL_DEFINITIONS="-DDYN_PIPE_WIDTH"

cd $code_root
mkdir build
cd build
cmake ..
make -j
