function [model_struct, train_ins] = lr_sequence_train(train, trainLabel)
% LR_SEQUENCE_TRAIN 训练多类逻辑回归模型
%   [model_struct, train_ins] = LR_SEQUENCE_TRAIN(train, trainLabel) 训练多类逻辑回归模型
%   输入:
%       train - 训练数据矩阵，每行是一个样本
%       trainLabel - 训练数据标签向量
%   输出:
%       model_struct - 包含模型和标准化参数的结构体
%       train_ins - 训练数据

% 数据预处理：标准化
[train_ins, mu, sigma] = zscore(train);

% 处理可能的NaN或Inf值
train_ins(isnan(train_ins)) = 0;
train_ins(isinf(train_ins)) = 0;

% 将标签转换为分类变量
trainLabel = categorical(trainLabel);

% 训练多类逻辑回归模型
model = fitcecoc(train_ins, trainLabel, 'Learners', templateLinear('Solver', 'lbfgs', 'Regularization', 'ridge'));

% 创建包含模型和标准化参数的结构体
model_struct = struct();
model_struct.model = model;
model_struct.mu = mu;
model_struct.sigma = sigma;

end