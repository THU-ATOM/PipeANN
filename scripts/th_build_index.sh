#!/bin/bash
#####################################
# SLURM Job Configuration
#####################################
#SBATCH --job-name=index
#SBATCH --nodes=6
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --partition=thcp3
#SBATCH --output=/thfs1/home/air_atom/slurm_out/diskann_slurm.out
#SBATCH --error=/thfs1/home/air_atom/slurm_out/diskann_slurm.err

#####################################
# Configuration Variables
#####################################
NODES=$(grep -oP '(?<=--nodes=)\d+' $0)
TASKS_PER_NODE=$(grep -oP '(?<=--ntasks-per-node=)\d+' $0)
CPUS_PER_TASK=$(grep -oP '(?<=--cpus-per-task=)\d+' $0)

ROOT=/thfs1/home/air_atom/diskann/1000w
LOG_ROOT=/thfs1/home/air_atom/log/diskann/index
LOG_FILE=$LOG_ROOT/$(date +"%Y-%m-%d").txt
mkdir -p $LOG_ROOT


#####################################
# Function Definitions
#####################################
# Process a single task with timing information
run_task() {
    local task_id=$SLURM_PROCID
    NEIGHBORS=(64 96 128)
    POOL_SIZES=(100 200)

    local total_pool=${#POOL_SIZES[@]}
    local neighbor_idx=$((task_id / total_pool))
    local pool_idx=$((task_id % total_pool))
    
    local MAX_NEIGHBORS=${NEIGHBORS[$neighbor_idx]}
    local POOL_SIZE=${POOL_SIZES[$pool_idx]}

    worker_name="${MAX_NEIGHBORS}-${POOL_SIZE}-${task_id}"
    task_start_time=$(date +"%Y-%m-%d %H:%M:%S")

    # Other task definition
    DATA_TYPE=float
    BIN_PATH=$ROOT/test.bin
    COMPRESSED_SIZE=32
    MAX_MEMORY=56
    THREADS=$CPUS_PER_TASK
    SIMILARITY=l2
    INDEX_PREFIX=$ROOT/index/${MAX_NEIGHBORS}_${POOL_SIZE}_${COMPRESSED_SIZE}_${MAX_MEMORY}_${SIMILARITY}/1000w
    SINGLE_FILE=0

    mkdir -p "$(dirname "$INDEX_PREFIX")"

    TASK_LOG_FILE=$LOG_ROOT/index_${MAX_NEIGHBORS}_${POOL_SIZE}_${COMPRESSED_SIZE}_${MAX_MEMORY}_${SIMILARITY}.txt

    echo "worker #${worker_name} start at ${task_start_time}" > $TASK_LOG_FILE

    ./time -v ./build/tests/build_disk_index \
        $DATA_TYPE \
        $BIN_PATH \
        $INDEX_PREFIX \
        $MAX_NEIGHBORS \
        $POOL_SIZE \
        $COMPRESSED_SIZE \
        $MAX_MEMORY \
        $THREADS \
        $SIMILARITY \
        $SINGLE_FILE >> $TASK_LOG_FILE 2>&1

    ./time -v ./build/tests/utils/gen_random_slice \
        $DATA_TYPE \
        $BIN_PATH \
        ${INDEX_PREFIX}_SAMPLE_RATE_0.01 \
        0.01 >> $TASK_LOG_FILE 2>&1

    ./time -v ./build/tests/build_memory_index \
        $DATA_TYPE \
        ${INDEX_PREFIX}_SAMPLE_RATE_0.01_data.bin \
        ${INDEX_PREFIX}_SAMPLE_RATE_0.01_ids.bin \
        ${INDEX_PREFIX}_mem.index \
        0 0 \
        $MAX_NEIGHBORS \
        $POOL_SIZE \
        1.2 \
        $THREADS \
        $SIMILARITY >> $TASK_LOG_FILE 2>&1

    # Calculate duration
    task_end_time=$(date +"%Y-%m-%d %H:%M:%S")
    start_seconds=$(date -d "$task_start_time" +%s)
    end_seconds=$(date -d "$task_end_time" +%s)
    total_time=$((end_seconds - start_seconds))

    # Format duration breakdown
    hours=$((total_time / 3600))
    minutes=$(( (total_time % 3600) / 60 ))
    seconds=$((total_time % 60))

    # Log task execution details
    echo "worker #${worker_name} end: $task_start_time -> $task_end_time, $hours hours, $minutes minutes, $seconds seconds" >> $TASK_LOG_FILE

    sleep 5h
}

#####################################
# Initialization
#####################################

# Setup timing
start_time=$(date +"%Y-%m-%d %H:%M:%S")
echo "$start_time" >> $LOG_FILE


#####################################
# Job Control Setup
#####################################

# Export variables for subshells
export ROOT LOG_ROOT CPUS_PER_TASK

#####################################
# Main Processing Loop
#####################################

yhrun bash -c "$(declare -f run_task); run_task"

#####################################
# Final Timing and Cleanup
#####################################
end_time=$(date +"%Y-%m-%d %H:%M:%S")
echo "End time: $end_time" >> "$LOG_FILE"

# Calculate total execution time
start_seconds=$(date -d "$start_time" +%s)
end_seconds=$(date -d "$end_time" +%s)
total_time=$((end_seconds - start_seconds))

# Format time breakdown
hours=$((total_time / 3600))
minutes=$(( (total_time % 3600) / 60 ))
seconds=$((total_time % 60))

echo "Total time: $hours hours, $minutes minutes, $seconds seconds" >> $LOG_FILE
