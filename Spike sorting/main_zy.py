import matplotlib.pyplot as plt
from pprint import pprint
import numpy as np
import os
from pathlib import Path
import random

# ProbeInterface 库 - 用于电极阵列定义和可视化
import probeinterface as pi
import probeinterface.plotting as pp

# SpikeInterface 库及其各个子模块 - 用于神经电生理数据处理
import spikeinterface as si
import spikeinterface.extractors as se          # 数据提取
import spikeinterface.preprocessing as spre      # 预处理
import spikeinterface.sorters as ss             # 尖峰排序
import spikeinterface.postprocessing as spost    # 后处理
import spikeinterface.qualitymetrics as sqm      # 质量指标
import spikeinterface.comparison as sc           # 比较工具
import spikeinterface.exporters as sexp          # 导出工具
import spikeinterface.curation as scur           # 数据管理
import spikeinterface.widgets as sw              # 可视化组件
# import spikeinterface_gui                        # GUI界面


def create_electrode_probe(num_channels=60):
    """
    创建电极阵列对象并设置通道位置和属性
    
    参数:
        num_channels: 电极通道数量，默认为60
        
    返回:
        probe: 配置好的电极阵列对象
    """
    # 初始化电极位置坐标矩阵 (x,y)
    positions = np.zeros((num_channels, 2))
    
    # 定义前6个电极(0-5)的位置
    for i in range(6):
        x = i // 8
        y = 6 - i % 8
        positions[i] = x, y
    
    # 定义中间电极(6-53)的位置
    for i in range(6, 54):
        x = (i+2) // 8
        y = 7 - (i+2) % 8
        positions[i] = x, y
    
    # 定义最后几个电极(54-59)的位置
    for i in range(54, 60):
        x = (i+2) // 8
        y = 6 - (i+2) % 8
        positions[i] = x, y
    
    # 坐标缩放 (单位: 微米)
    positions *= 200
    
    # 创建电极阵列对象 (2D平面, 单位: 微米)
    probe = pi.Probe(ndim=2, si_units='um')
    
    # 设置电极触点属性 (圆形, 半径15微米)
    probe.set_contacts(positions=positions, shapes='circle', shape_params={'radius': 15})
    
    # 设置电极阵列平面轮廓
    planar_contour = [(-100, -100), (1500, -100), (1500, 1500), (-100, 1500)]
    probe.set_planar_contour(planar_contour)
    
    return probe


def map_channels_to_probe(probe):
    """
    将设备通道映射到电极阵列
    
    参数:
        probe: 电极阵列对象
        
    返回:
        probe: 更新后的电极阵列对象
    """
    # 设备通道与探针通道的映射关系 (60个通道)
    device_channel_indices = np.array([
        20, 18, 15, 14, 11, 9, 23, 21, 19, 16,
        13, 10, 8, 6, 25, 24, 22, 17, 12, 7,
        5, 4, 28, 29, 27, 26, 3, 2, 0, 1,
        31, 30, 32, 33, 56, 57, 59, 58, 34, 35,
        37, 42, 47, 52, 54, 55, 36, 38, 40, 43,
        46, 49, 51, 53, 39, 41, 44, 45, 48, 50
    ])
    
    # 设置通道映射并转换为数据框
    probe.set_device_channel_indices(device_channel_indices)
    probe.to_dataframe(complete=True)
    
    return probe


def preprocess_recording(recording):
    """
    对神经元记录进行预处理 (滤波和信号白化)
    
    参数:
        recording: 原始记录对象
        
    返回:
        recording_preprocessed: 预处理后的记录对象
    """
    # 带通滤波 (300-6000Hz)
    recording_filtered = spre.bandpass_filter(recording, freq_min=300, freq_max=6000)
    
    # 信号白化处理
    recording_preprocessed = spre.whiten(recording_filtered, dtype='float32')
    
    return recording_preprocessed


def run_spike_sorting(recording_preprocessed, output_folder):
    """
    运行MountainSort5尖峰排序算法
    
    参数:
        recording_preprocessed: 预处理后的记录对象
        output_folder: 输出文件夹路径
        
    返回:
        sorting: 排序结果对象
    """
    # 运行MountainSort5排序算法
    sorting = ss.run_sorter(
        sorter_name="mountainsort5", 
        recording=recording_preprocessed,
        output_folder=output_folder,
        detect_threshold=4,                       # 检测阈值
        detect_time_radius_msec=1.5,              # 检测时间半径(毫秒)
        snippet_mask_radius=150,                  # 片段掩码半径(微米)
        scheme2_phase1_detect_channel_radius=150, # 方案2阶段1检测通道半径(微米)
        scheme2_training_duration_sec=60          # 方案2训练持续时间(秒)
    )
    
    return sorting


def extract_and_compute_metrics(recording_preprocessed, sorting, waveforms_folder):
    """
    提取波形并计算各种指标
    
    参数:
        recording_preprocessed: 预处理后的记录对象
        sorting: 排序结果对象
        waveforms_folder: 波形存储文件夹路径
        
    返回:
        waveform_extractor: 波形提取器对象
        metrics: 包含各种计算指标的字典
    """
    # 提取波形
    waveform_extractor = si.extract_waveforms(
        recording_preprocessed, 
        sorting, 
        folder=waveforms_folder, 
        overwrite=None
    )
    
    # 计算各种神经元指标
    metrics = {
        'unit_locations': spost.compute_unit_locations(waveform_extractor,method="center_of_mass"),
        'spike_locations': spost.compute_spike_locations(waveform_extractor),
        'correlograms': spost.compute_correlograms(waveform_extractor)[0],  # 只保存相关图
        'bins': spost.compute_correlograms(waveform_extractor)[1],          # 保存bins
        'similarity': spost.compute_template_similarity(waveform_extractor),
        'noise_levels': spost.compute_noise_levels(waveform_extractor)
    }
    
    return waveform_extractor, metrics


def process_recording_files(input_folder, output_folder):
    """
    处理文件夹中的所有记录文件
    
    参数:
        input_folder: 输入文件夹路径
        output_folder: 输出文件夹路径
    """
    # 创建电极阵列并设置通道映射
    probe = create_electrode_probe()
    probe = map_channels_to_probe(probe)
    
    # 获取所有文件名
    file_names = os.listdir(input_folder)
    
    # 处理每个文件
    for file_name in file_names:
        # 构建路径
        recording_file = input_folder / file_name
        output_folder_name = os.path.splitext(file_name)[0]
        current_output_folder = output_folder / output_folder_name
        waveforms_folder = current_output_folder / 'waveforms_folder'
        
        # 读取MCS H5格式记录
        recording = se.read_mcsh5(recording_file)
        print(f"正在处理记录: {recording}")
        
        # 设置电极阵列
        recording = recording.set_probe(probe, in_place=True)
        
        # 可视化电极阵列(取消注释以显示)
        pp.plot_probe(probe)
        plt.show()  # 取消注释以显示图像
        
        # 预处理记录
        recording_preprocessed = preprocess_recording(recording)
        
        # 运行尖峰排序
        sorting = run_spike_sorting(recording_preprocessed, current_output_folder)
        print(f"排序结果: {sorting}")
        
        # 提取波形并计算指标
        waveform_extractor, metrics = extract_and_compute_metrics(
            recording_preprocessed, 
            sorting, 
            waveforms_folder
        )
        print(f"波形提取器: {waveform_extractor}")
        
        # 输出可用扩展名
        print(f"可用扩展名: {waveform_extractor.get_available_extension_names()}")


def main():
    """主函数"""
    # 设置输入和输出路径
    input_folder = Path('K:\\Fig5_summary\\TestData_0812\\20250718\\m1\\spon_1_5min')
    output_folder = Path('K:\\Fig5_summary\\TestData_0812\\20250718\\m1\\spon_1_5min\\after_raw_h5')
    
    # 处理记录文件
    process_recording_files(input_folder, output_folder)
    


# 当脚本直接运行时执行main函数
if __name__ == "__main__":
    main()