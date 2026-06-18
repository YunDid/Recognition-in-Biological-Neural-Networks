import numpy as np
import scipy.io
import os
from pathlib import Path


def convert_npz_to_mat(input_folder, output_folder):
    """
    将NPZ文件转换为MAT文件格式
    
    参数:
        input_folder: 包含NPZ文件的输入文件夹路径
        output_folder: 保存MAT文件的输出文件夹路径
    """
    # 确保输出文件夹存在
    os.makedirs(output_folder, exist_ok=True)
    
    # 获取所有文件名
    file_names = os.listdir(input_folder)
    
    print(f"正在处理NPZ文件夹: {input_folder}")
    print(f"找到 {len(file_names)} 个文件")
    
    # 处理每个NPZ文件
    for file_name in file_names:
        # 构建路径
        input_file_path = input_folder / file_name
        output_file_name = os.path.splitext(file_name)[0] + ".mat"
        output_file_path = output_folder / output_file_name
        
        print(f"正在转换: {file_name} -> {output_file_name}")
        
        try:
            # 加载NPZ文件
            npz_file = np.load(input_file_path)
            
            # 创建数据字典
            data_dict = {}
            for key in npz_file.files:
                data_dict[key] = npz_file[key]
                print(f'  字段: {key}, 形状: {data_dict[key].shape}, 数据类型: {data_dict[key].dtype}')
            
            # 保存为MAT文件
            scipy.io.savemat(output_file_path, data_dict)
            print(f"  成功保存: {output_file_path}")
            
        except Exception as e:
            print(f"  转换失败: {e}")


def convert_npy_to_mat(input_folder, output_folder, field_name='unit_locations'):
    """
    将NPY文件转换为MAT文件格式
    
    参数:
        input_folder: 包含NPY文件的输入文件夹路径
        output_folder: 保存MAT文件的输出文件夹路径
        field_name: MAT文件中使用的字段名称，默认为'unit_locations'
    """
    # 确保输出文件夹存在
    os.makedirs(output_folder, exist_ok=True)
    
    # 获取所有文件名
    file_names = os.listdir(input_folder)
    
    print(f"正在处理NPY文件夹: {input_folder}")
    print(f"找到 {len(file_names)} 个文件")
    
    # 处理每个NPY文件
    for file_name in file_names:
        # 构建路径
        input_file_path = input_folder / file_name
        output_file_name = os.path.splitext(file_name)[0] + ".mat"
        output_file_path = output_folder / output_file_name
        
        print(f"正在转换: {file_name} -> {output_file_name}")
        
        try:
            # 加载NPY文件
            npy_data = np.load(input_file_path)
            
            # 创建数据字典，使用指定字段名
            mat_data = {field_name: npy_data}
            print(f'  字段: {field_name}, 形状: {npy_data.shape}, 数据类型: {npy_data.dtype}')
            
            # 保存为MAT文件
            scipy.io.savemat(output_file_path, mat_data)
            print(f"  成功保存: {output_file_path}")
            
        except Exception as e:
            print(f"  转换失败: {e}")


def process_sorting_outputs(root_folder):
    """
    处理根目录下所有日期文件夹中的sorting_out文件夹
    
    参数:
        root_folder: 根目录路径（包含所有日期文件夹）
    """
    print(f"开始处理根目录: {root_folder}")
    
    # 遍历根目录下的所有日期文件夹
    for date_folder in os.listdir(root_folder):
        date_path = root_folder / date_folder
        
        # 跳过非文件夹的项目
        if not date_path.is_dir():
            continue
            
        print(f"\n正在处理日期文件夹: {date_folder}")
        
        # 遍历日期文件夹下的所有细胞文件夹
        for cell_folder in os.listdir(date_path):
            cell_path = date_path / cell_folder
            
            # 跳过非文件夹的项目
            if not cell_path.is_dir():
                continue
                
            print(f"  正在处理细胞文件夹: {cell_folder}")
            
            # 遍历细胞文件夹下的所有spon文件夹
            for spon_folder in os.listdir(cell_path):
                spon_path = cell_path / spon_folder
                
                # 跳过非文件夹的项目
                if not spon_path.is_dir():
                    continue
                    
                # 检查是否是spon_x_5min格式的文件夹
                if not spon_folder.startswith('spon_') or not spon_folder.endswith('_5min'):
                    continue
                    
                print(f"    正在处理spon文件夹: {spon_folder}")
                
                # 检查是否存在sorting_out文件夹
                sorting_out_folder = spon_path / 'sorting_out'
                if not sorting_out_folder.exists():
                    print(f"      未找到sorting_output文件夹，跳过")
                    continue
                
                # 在sorting_output文件夹下创建trans文件夹
                trans_folder = sorting_out_folder / 'trans' 
                trans_folder.mkdir(exist_ok=True)
                
                # 在trans文件夹下直接创建npz和npy文件夹
                npz_output_folder = trans_folder / 'npz'
                npy_output_folder = trans_folder / 'npy'
                npz_output_folder.mkdir(exist_ok=True)
                npy_output_folder.mkdir(exist_ok=True)
                
                # 检查并转换sorter_out文件夹中的NPZ文件
                sorter_output_folder = sorting_out_folder / 'sorter_output'
                if sorter_output_folder.exists():
                    print(f"      转换NPZ文件...")
                    convert_npz_to_mat(sorter_output_folder, npz_output_folder)
                
                # 检查并转换waveforms_folder/extensions/unit_locations中的NPY文件
                unit_locations_folder = sorting_out_folder / 'waveforms_folder' / 'extensions' / 'unit_locations'
                if unit_locations_folder.exists():
                    print(f"      转换NPY文件...")
                    convert_npy_to_mat(unit_locations_folder, npy_output_folder)
                
                print(f"      完成转换: {spon_folder}")


def main():
    """主函数 - 执行批处理转换任务"""
    # 设置根目录路径（与main_zy.py保持一致）
    root_folder = Path('E:\\MetaData\\FIG5_h5')  # 最上层目录，包含所有日期文件夹
    
    print("=" * 50)
    print("开始批处理转换任务")
    print("=" * 50)
    
    # 执行批处理转换
    process_sorting_outputs(root_folder)
    
    print("\n所有转换完成!")


# 当脚本直接运行时执行main函数
if __name__ == "__main__":
    main()