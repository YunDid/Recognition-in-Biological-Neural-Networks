# Japanese Vowels Feature-Retention Check

These scripts validate whether Japanese Vowels speaker information survives the
BRC six-site compression and top-k stimulation encoding.

Run from this directory or pass absolute paths.

```powershell
$data = "E:\Recognition-in-Biological-Neural-Networks\Data\japanese+vowels\ae.train"
$size = "E:\Recognition-in-Biological-Neural-Networks\Data\japanese+vowels\size_ae.train"

python .\01_compute_intra_inter.py --data $data --size $size --metric dtw_euclidean

python .\02_standardize_dataset.py --data $data --out .\standardized_12slot.txt --time-slots 12 --fit-size $size --fit-speakers 1-8
python .\01_compute_intra_inter.py --data .\standardized_12slot.txt --size $size --metric flat_euclidean --feature-zscore

python .\03_compress_12_to_6.py --data .\standardized_12slot.txt --out .\score6_12slot.txt --abs
python .\01_compute_intra_inter.py --data .\score6_12slot.txt --size $size --metric flat_euclidean --feature-zscore

python .\04_topk_encode.py --data .\score6_12slot.txt --out .\top1_6site.txt --k 1
python .\04_topk_encode.py --data .\score6_12slot.txt --out .\top2_6site.txt --k 2
python .\04_topk_encode.py --data .\score6_12slot.txt --out .\top3_6site.txt --k 3

python .\01_compute_intra_inter.py --data .\top1_6site.txt --size $size --metric flat_hamming
python .\01_compute_intra_inter.py --data .\top2_6site.txt --size $size --metric flat_hamming
python .\01_compute_intra_inter.py --data .\top3_6site.txt --size $size --metric flat_hamming

python .\05_classify_svm.py --data .\standardized_12slot.txt --size $size --c 1
python .\05_classify_svm.py --data .\score6_12slot.txt --size $size --c 1
python .\05_classify_svm.py --data .\top1_6site.txt --size $size --c 1
python .\05_classify_svm.py --data .\top2_6site.txt --size $size --c 1
python .\05_classify_svm.py --data .\top3_6site.txt --size $size --c 0.1
```

Interpretation:

- `intra_mean`: mean distance between samples from the same speaker.
- `inter_mean`: mean distance between samples from different speakers.
- `inter_intra_ratio`: larger than 1 means between-speaker distances are larger
  than within-speaker distances.
- `dtw_euclidean`: use for raw variable-length time series.
- `flat_euclidean`: use for same-shape continuous feature blocks.
- `flat_hamming`: use for same-shape binary top-k blocks.
- `05_classify_svm.py`: runs a simple one-vs-rest linear SVM. It requires
  fixed-shape samples, so raw variable-length utterances must be converted to
  fixed time slots first.
