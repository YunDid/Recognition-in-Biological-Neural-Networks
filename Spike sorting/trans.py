import numpy as np
import scipy.io
import os
from pathlib import Path

# folder_path = Path('E:/Voice_Data_Eight/20250310/C3_20250310_MCon_Cell0218/si_sorting/after/2025-03-10T11-59-50McsRecording_E-00159/sorter_output')
# output_path = Path('E:/Voice_Data_Eight/20250310/C3_20250310_MCon_Cell0218/si_sorting/after/2025-03-10T11-59-50McsRecording_E-00159/tran/npz')
# mat = Path('.mat')
# file_names = os.listdir(folder_path)
# for file_name in file_names:
#     recording_file = folder_path / file_name
#     output_folder_name = os.path.splitext(file_name)[0] + ".mat"
#     output_folder = output_path / output_folder_name
#     npz_file = np.load(recording_file)
#     data_dict = {}
#     for key in npz_file.files:
#         data_dict[key] = npz_file[key]
#     for key, value in data_dict.items():
#         print(f'Key:{key},Shape:{value.shape}, Data:{value} ')
#     scipy.io.savemat(output_folder, data_dict)

folder_path = Path('E:/Voice_Data_Eight/20250310/C3_20250310_MCon_Cell0218/si_sorting/after/2025-03-10T11-59-50McsRecording_E-00159/waveforms_folder/extensions/spike_locations')
output_path = Path('E:/Voice_Data_Eight/20250310/C3_20250310_MCon_Cell0218/si_sorting/after/2025-03-10T11-59-50McsRecording_E-00159/tran/npy')
mat = Path('.mat')
file_names = os.listdir(folder_path)
for file_name in file_names:
    # 只处理.npy文件，跳过其他文件类型
    if not file_name.endswith('.npy'):
        print(f"跳过非NumPy文件: {file_name}")
        continue
        
    recording_file = folder_path / file_name
    output_folder_name = os.path.splitext(file_name)[0] + ".mat"
    output_folder = output_path / output_folder_name
    npy_file = np.load(recording_file, allow_pickle=True)
    mat_data = {'unit_locations': npy_file}
    scipy.io.savemat(output_folder, mat_data)