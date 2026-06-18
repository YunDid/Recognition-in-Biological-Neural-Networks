function [predict_label, accu, test_ins] = lr_sequence_test(test, train, testLabel, model_struct)
% LR_SEQUENCE_TEST 测试多类逻辑回归模型
%   [predict_label, accu, test_ins] = LR_SEQUENCE_TEST(test, train, testLabel, model_struct) 测试多类逻辑回归模型
%   输入:
%       test - 测试数据矩阵，每行是一个样本
%       train - 训练数据矩阵，每行是一个样本
%       testLabel - 测试数据标签向量
%       model_struct - 包含模型和标准化参数的结构体
%   输出:
%       predict_label - 预测的标签
%       accu - 准确率信息 [accuracy, 0, 0]，与SVM输出格式兼容
%       test_ins - 测试数据

% 从结构体中获取模型和标准化参数
model = model_struct.model;
mu = model_struct.mu;
sigma = model_struct.sigma;

% 对测试数据进行相同的标准化处理
test_ins = (test - mu) ./ sigma;

% 处理可能的NaN或Inf值
test_ins(isnan(test_ins)) = 0;
test_ins(isinf(test_ins)) = 0;

% 预测
predict_label = predict(model, test_ins);
predict_label = double(predict_label); % 将分类变量转换为数值

% 计算准确率
correct = sum(predict_label == testLabel);
total = length(testLabel);
accuracy = correct / total * 100;

% 返回格式与SVM兼容
accu = [accuracy, 0, 0];

end