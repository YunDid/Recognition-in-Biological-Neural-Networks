import numpy as np
import os
from pathlib import Path
# matrix = np.array([1, 2, 3, 4, 5, 6])
# matrix2 = np.arange(6)
# print(matrix2)
# print(range(6, 10))

folder_path = Path('E:\新建文件夹')
output_path = Path('E:\data_results\spike_sorting')
print(folder_path)
print(output_path)
file_names = os.listdir(folder_path)
for file_name in file_names:
    print(file_name)
    recording_file = folder_path / file_name
    print(recording_file)
    output_folder_name = os.path.splitext(file_name)[0]
    output_folder = output_path / output_folder_name
    waveforms_folder = output_folder / 'waveforms_folder'
    print(output_folder)
    print(waveforms_folder)
