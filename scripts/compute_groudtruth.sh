ROOT=/thfs1/home/air_atom/diskann/1000w
# topk=1000
topk=10

./build/tests/utils/compute_groundtruth \
    float \
    $ROOT/test.bin \
    $ROOT/test_query.bin \
    $topk \
    $ROOT/gt_$topk.bin