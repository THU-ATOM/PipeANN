# Usage:
# build/tests/build_disk_index <data_type (float/int8/uint8)> <data_file.bin> <index_prefix_path> <R>  <L>  <B>  <M>  <T> <similarity metric (cosine/l2) case sensitive>. <single_file_index (0/1)>
# Parameter explanation:

# R: maximum out-neighbors
# L: candidate pool size during build (build in fact conducts vector searches to optimize graph edges)
# B: in-memory PQ-compressed vector size. Our goal is to use 32 bytes per vector; higher-dimensional vectors might require more bytes.
# M: maximum memory used during build, 256GB is sufficient for the 100M index to be built totally in memory.
# T: number of threads used during build. Our machine has 112 threads.

module load GCC/9.3.0 cmake openblas boost openblas loginnode

task_start_time=$(date +"%Y-%m-%d %H:%M:%S")
echo "$task_start_time"

./build/tests/build_disk_index float ../test/test.bin ../test/test_index 128 200 32 64 16 l2 0

task_end_time=$(date +"%Y-%m-%d %H:%M:%S")
start_seconds=$(date -d "$task_start_time" +%s)
end_seconds=$(date -d "$task_end_time" +%s)
total_time=$((end_seconds - start_seconds))

hours=$((total_time / 3600))
minutes=$(( (total_time % 3600) / 60 ))
seconds=$((total_time % 60))

echo "$task_start_time -> $task_end_time, $hours hours, $minutes minutes, $seconds seconds"