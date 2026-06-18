import numpy as np
import os

def read_numpy_file(file_path):
    """
    读取 .npy 或 .npz 文件并返回其内容
    
    参数:
        file_path (str): .npy 或 .npz 文件的路径
    
    返回:
        numpy.ndarray 或 dict: 文件中的数据
    """
    try:
        file_extension = os.path.splitext(file_path)[1].lower()
        
        if file_extension == '.npy':
            data = np.load(file_path)
            print(f"文件加载成功！")
            print(f"数据形状: {data.shape}")
            print(f"数据类型: {data.dtype}")
            return data
            
        elif file_extension == '.npz':
            data = np.load(file_path)
            print(f"文件加载成功！")
            print("\n文件中包含以下数组：")
            for key in data.files:
                print(f"\n数组名称: {key}")
                print(f"形状: {data[key].shape}")
                print(f"类型: {data[key].dtype}")
            return data
            
        else:
            print("不支持的文件格式。请使用 .npy 或 .npz 文件。")
            return None
            
    except Exception as e:
        print(f"读取文件时出错: {str(e)}")
        return None

if __name__ == "__main__":
    # 示例用法
    file_path = input("请输入 .npy 或 .npz 文件的路径: ")
    data = read_numpy_file(file_path)
    
    if data is not None:
        if isinstance(data, np.ndarray):
            print("\n数据预览:")
            print(data)
        elif isinstance(data, np.lib.npyio.NpzFile):
            key = input("\n请输入要查看的数组名称（从上面列表中选择）: ")
            if key in data.files:
                print(f"\n{key} 的数据预览:")
                print(data[key])
            else:
                print(f"未找到名为 {key} 的数组") 