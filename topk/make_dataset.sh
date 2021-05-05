for j in `seq 1 12`
do
python ~/p4-dev/topk/packets/dataset/make_dataset_hw.py --dist z --parameter 1.1 --num_of_data 10000 --index $j
done