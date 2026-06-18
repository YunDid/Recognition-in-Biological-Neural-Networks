function results_table = calculate_dcc_sc(alpha_values, tau_values, beta_fit_values, beta_shape_collapse)
    % 函数用于计算DCC和SC error
    % 输入:
    %   alpha_values: alpha值向量
    %   tau_values: tau值向量
    %   beta_fit_values: 实验拟合的beta值向量
    %   beta_shape_collapse: 基于形状塌陷计算的beta预测值向量
    % 输出:
    %   results_table: 包含所有计算结果的表格
    
    % 检查输入向量长度是否一致
    if length(alpha_values) ~= length(tau_values) || ...
       length(alpha_values) ~= length(beta_fit_values) || ...
       length(alpha_values) ~= length(beta_shape_collapse)
        error('所有输入向量必须具有相同长度');
    end
    
    % 使用公式(3-8)计算βpred: βpred = (α-1)/(τ-1)
    beta_pred_values = (alpha_values - 1) ./ (tau_values - 1);
    
    % 计算DCC: dcc = ||βpred - βfit||
    dcc_values = abs(beta_pred_values - beta_fit_values);
    
    % 计算SC error: sc_error = ||beta_shape_collapse - βfit||
    sc_error_values = abs(beta_shape_collapse - beta_fit_values);
    
    % 创建结果表格
    results_table = table(alpha_values', tau_values', beta_fit_values', ...
                          beta_pred_values', dcc_values', ...
                          beta_shape_collapse', sc_error_values', ...
                          'VariableNames', {'Alpha', 'Tau', 'Beta_fit', ...
                                           'Beta_pred', 'DCC', ...
                                           'Beta_shape_collapse', 'SC_Error'});
    
    % 显示结果
    disp('计算结果:');
    disp(results_table);
    
    % 保存结果到CSV文件
    writetable(results_table, 'metrics_results.csv');
    disp('结果已保存到 metrics_results.csv');
end