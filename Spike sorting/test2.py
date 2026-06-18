import matplotlib.pyplot as plt
from pprint import pprint
import probeinterface.plotting as pp
import spikeinterface as si
import spikeinterface.extractors as se
import spikeinterface.preprocessing as spre
import spikeinterface.sorters as ss
import spikeinterface.postprocessing as spost
import spikeinterface.qualitymetrics as sqm
import spikeinterface.comparison as sc
import spikeinterface.exporters as sexp
import spikeinterface.curation as scur
import spikeinterface.widgets as sw
from pathlib import Path
import os
import numpy as np
import probeinterface as pi
import spikeinterface_gui
import scipy.io
# params = ss.get_default_sorter_params('mountainsort5')
# print("Parameters:\n", params)
#
# desc = ss.get_sorter_params_description('mountainsort5')
# print("Descriptions:\n", desc)
# folder_path = Path("D:\wwmong\\results\hippo1216_1\spike_sorting\day3\spon1\sorter_output\\firings.npz")
# sorting = se.read_(folder_path)
# we_loaded = si.load_waveforms("D:\wwmong\\results\\0814-new\\0925\\2023-09-25T14-32-05McsRecording\waveforms_folder")
# print(we_loaded.get_available_extension_names())
# data = np.load("D:\wwmong\\results\\0814-new\\0925\\2023-09-25T14-32-05McsRecording\sorter_output\\firings.npz")
# array_names = data.files
# print("数组名称：", array_names)
# for array_name in array_names:
#     array = data[array_name]
#     print(f"数组名：{array_name}")
#     print(f"数组形状:{array.shape}")
#     print(f"数组内容：\n{array}")
# print(data)

# npz_file = np.load("D:\wwmong\\results\\0814-new\\0925\\2023-09-25T14-32-05McsRecording\sorter_output\\firings.npz")
# data_dict = {}
# for key in npz_file.files:
#     data_dict[key] = npz_file[key]
# for key, value in data_dict.items():
#     print(f'Key:{key},Shape:{value.shape}, Data:{value} ')
# scipy.io.savemat('output.mat', data_dict)

npy_data = np.load('D:/wwmong/results/0814-new/0925/2023-09-25T14-32-05McsRecording/waveforms_folder/unit_locations/unit_locations.npy')
mat_data = {'unit_locations': npy_data}
scipy.io.savemat('unit_locations.mat', mat_data)
