module load GCC/9.3.0 cmake openblas boost openblas loginnode

task_start_time=$(date +"%Y-%m-%d %H:%M:%S")
echo "$task_start_time"

./build/tests/build_disk_index float ../test.bin ../test_index 128 200 32 64 16 l2 0

task_end_time=$(date +"%Y-%m-%d %H:%M:%S")
start_seconds=$(date -d "$task_start_time" +%s)
end_seconds=$(date -d "$task_end_time" +%s)
total_time=$((end_seconds - start_seconds))

hours=$((total_time / 3600))
minutes=$(( (total_time % 3600) / 60 ))
seconds=$((total_time % 60))

echo "$task_start_time -> $task_end_time, $hours hours, $minutes minutes, $seconds seconds"