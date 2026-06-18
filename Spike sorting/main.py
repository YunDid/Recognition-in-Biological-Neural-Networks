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
import numpy as np
import probeinterface as pi
import spikeinterface_gui

'''并行计算'''
# global_job_kwargs = dict(n_jobs=4, chunk_duration="1s", progress_bar=True)
# si.set_global_job_kwargs(**global_job_kwargs)
'''read recording'''
base_folder = Path('E:\新建文件夹')
recording_file = base_folder / '2023-01-05T10-29-13McsRecording_E-00159.h5'
recording = se.read_mcsh5(recording_file)
# print(recording)
# print(recording.get_property('electrode_labels'))
# print(recording.get_channel_ids())
# w_ts = sw.plot_timeseries(recording, time_range=(0, 5), show_channel_ids=True)
# w_ts2 = sw.plot_timeseries(recording, mode='map', time_range=(0, 5),
#                            show_channel_ids=True)
# plt.show()

'''set probe'''
n = 60
positions = np.zeros((n, 2))
for i in range(6):
    x = i // 8
    y = 6 - i % 8
    positions[i] = x, y
for i in range(6, 54):
    x = (i+2) // 8
    y = 7 - (i+2) % 8
    positions[i] = x, y
for i in range(54, 60):
    x = (i+2) // 8
    y = 6 - (i+2) % 8
    positions[i] = x, y
# print(positions)
positions *= 200
probe = pi.Probe(ndim=2, si_units='um')
probe.set_contacts(positions=positions, shapes='circle', shape_params={'radius': 15})
# print(probe)
polygon = [(-100, -100), (1500, -100), (1500, 1500), (-100, 1500)]
probe.set_planar_contour(polygon)
# pp.plot_probe(probe, with_channel_index=True)
# plt.show()

'''connect device channels to probe'''
device_channel_indices = np.array([20, 18, 15, 14, 11, 9, 23, 21, 19, 16,
                                  13, 10, 8, 6, 25, 24, 22, 17, 12, 7,
                                  5, 4, 28, 29, 27, 26, 3, 2, 0, 1,
                                  31, 30, 32, 33, 56, 57, 59, 58, 34, 35,
                                  37, 42, 47, 52, 54, 55, 36, 38, 40, 43,
                                  46, 49, 51, 53, 39, 41, 44, 45, 48, 50])
print(device_channel_indices)
probe.set_device_channel_indices(device_channel_indices)
probe.to_dataframe(complete=True)
recording = recording.set_probe(probe, in_place=True)
# pp.plot_probe(probe, with_channel_index=True, with_device_index=True)
# plt.show()

'''lazy preprocessing'''
recording_filtered = spre.bandpass_filter(recording, freq_min=300, freq_max=6000)
recording_preprocessed: si.BaseRecording = spre.whiten(recording_filtered, dtype='float32')
# print(recording_preprocessed)
'''sorting'''
sorting = ss.run_sorter(sorter_name="mountainsort5", recording=recording_preprocessed,
                        output_floder=)
print(sorting)
# params = ss.get_default_sorter_params('mountainsort5')
# print(params)
we_MS5 = si.extract_waveforms(recording_preprocessed, sorting, folder='waveforms_folder', overwrite=True)
print(we_MS5)
amplitudes = spost.compute_spike_amplitudes(we_MS5)
unit_locations = spost.compute_unit_locations(we_MS5)
spike_locations = spost.compute_spike_locations(we_MS5)
correlograms, bins = spost.compute_correlograms(we_MS5)
similarity = spost.compute_template_similarity(we_MS5)
noise_levels = spost.compute_noise_levels(we_MS5)
principal_components = spost.compute_principal_components(we_MS5)
print(we_MS5.get_available_extension_names())
'''GUI'''
# app = spikeinterface_gui.mkQApp()
# win = spikeinterface_gui.MainWindow(we_MS5)
# win.show()
# app.exec_()
