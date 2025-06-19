#!/bin/bash
#####################################
# SLURM Job Configuration
#####################################
#SBATCH --job-name=search
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
LOG_ROOT=/thfs1/home/air_atom/log/diskann/search
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
    PIPELINE_WIDTH=32
    MAX_MEMORY=56
    THREADS=$CPUS_PER_TASK
    SIMILARITY=l2
    INDEX_PREFIX=$ROOT/index/${MAX_NEIGHBORS}_${POOL_SIZE}_${COMPRESSED_SIZE}_${MAX_MEMORY}_${SIMILARITY}/1000w
    QUERY_FILE=$ROOT/test_query.bin
    # TOPK=10
    TOPK=1000
    GT_FILE=$ROOT/gt_$TOPK.bin
    SEARCH_MODE=2

    TASK_LOG_FILE=$LOG_ROOT/search_${MAX_NEIGHBORS}_${POOL_SIZE}_${COMPRESSED_SIZE}_${MAX_MEMORY}_${SIMILARITY}_${SEARCH_MODE}.txt

    echo "worker #${worker_name} start at ${task_start_time}" > $TASK_LOG_FILE

    # build/tests/search_disk_index <data_type> <index_prefix> <nthreads> <I/O pipeline width (max for PipeANN)> <query file> <truth file> <top-K> <similarity> <search_mode (2 for PipeANN)> <L of in-memory index> <Ls for on-disk index>
    ./time -v ./build/tests/search_disk_index \
        $DATA_TYPE \
        $INDEX_PREFIX \
        $THREADS \
        $PIPELINE_WIDTH \
        $QUERY_FILE \
        $GT_FILE \
        $TOPK \
        $SIMILARITY \
        $SEARCH_MODE \
        10 \
        $TOPK $(($TOPK * 2)) $(($TOPK * 3)) $(($TOPK * 4)) $(($TOPK * 5)) \
        >> $TASK_LOG_FILE 2>&1
    # echo "./time -v ./build/tests/search_disk_index \
    #     $DATA_TYPE \
    #     $INDEX_PREFIX \
    #     $THREADS \
    #     $PIPELINE_WIDTH \
    #     $QUERY_FILE \
    #     $GT_FILE \
    #     $TOPK \
    #     $SIMILARITY \
    #     $SEARCH_MODE \
    #     $TOPK \
    #     $TOPK $(($TOPK * 2))" > $TASK_LOG_FILE


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

    sleep 5m
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
