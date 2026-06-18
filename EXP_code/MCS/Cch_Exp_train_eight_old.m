clc
clear
close 
import java.awt.Robot;
import iava.awe.event.*;
robot = java.awt.Robot;
%% 电极位点位置
locx=[888 918 945 973 1002 1029 ...
    862 888 918 945 973 1002 1029 1055 ...
    862 888 918 945 973 1002 1029 1055 ...
    862 888 918 945 973 1002 1029 1055 ...
    862 888 918 945 973 1002 1029 1055 ...
    862 888 918 945 973 1002 1029 1055 ...
    862 888 918 945 973 1002 1029 1055 ...
    888 918 945 973 1002 1029] - 146;
locy=[418 418 418 418 418 418 ...
    455 455 455 455 455 455 455 455 ...
    474 474 474 474 474 474 474 474 ...
    501 501 501 501 501 501 501 501 ...
    531 531 531 531 531 531 531 531 ...
    558 558 558 558 558 558 558 558 ...
    585 585 585 585 585 585 585 585 ... 
    615 615 615 615 615 615] - 102;
%% 八种声音编码序列
positions = [
    1 1 1 3 5 5;
    3 2 1 2 3 3;
    5 3 5 3 5 3;
    1 1 5 5 6 6;
    5 6 5 4 3 1;
    3 3 4 5 5 4;
    4 3 2 1 6 5;
    3 5 3 1 2 3  
];
elec_position = [3,7,9,11,13,18]
%% 位置参数调整
record_pos = [213, 44]
stim_test_pos = [726, 171]
stim_train_pos = [755, 173]
start_stim_pos = [350, 40]
%% 分批次实施的28轮随机刺激，每批7轮，分4批
total_batches = 4;
stim_per_batch = 7; 
total_stim_rounds = 28; 
%% 初始化
pause(10)
%% 5min 自放电记录
Record_Spon(300);
%% 第一轮测试
rng('shuffle');  % 设置随机数种子
stim_labels_test1 = []; % 用于记录所有时空刺激的标签
for batch = 1:total_batches
    % 开始新一批的记录
    ClickOnce(record_pos(1), record_pos(2)); % 开始记录
    pause(5)
    ClickOnce(stim_test_pos(1),stim_test_pos(2));%刺激器1

    % 每批stim_per_batch轮的随机刺激
    for round = 1:stim_per_batch
        % 随机打乱positions的顺序，并生成对应的标签
        rand_idx = randperm(size(positions, 1));
        shuffled_positions = positions(rand_idx, :);
        current_labels = rand_idx; % 当前轮次的标签记录

        % 对每个随机的声音编码序列进行刺激
        for p = 1:size(shuffled_positions, 1)
            pos = shuffled_positions(p, :);
            for i = 1:length(pos)
                elec_index = elec_position(pos(i)); % 获取elec_position中的实际电极位置索引
                ClickStim(locx(elec_index), locy(elec_index), start_stim_pos);
            end
            % 记录当前时空刺激的标签
            stim_labels_test1 = [stim_labels_test1, current_labels(p)];
            pause(10);
        end
    end

    % 完成本批次，停止记录
    ClickOnce(stim_test_pos(1),stim_test_pos(2));%刺激器1
    ClickOnce(record_pos(1), record_pos(2)); % 停止记录
    pause(5)
    
    if batch < total_batches
        disp(['完成第 ', num2str(batch), ' 批次，准备下一批次...']);
    else
        disp('所有批次完成！');
    end
end

%% 5min 自放电记录
Record_Spon(300);
%% 训练 组间休息10s
stim_labels_train = []; % 用于记录所有时空刺激的标签
for batch = 1:total_batches
    % 开始新一批的记录
    ClickOnce(record_pos(1), record_pos(2)); % 开始记录
    pause(5)
    ClickOnce(stim_train_pos(1),stim_train_pos(2));%刺激器2
    
    % 按顺序施加刺激
    for pattern_idx = 1:size(positions, 1)
        for repeat = 1:stim_per_batch
            pos = positions(pattern_idx, :);
            for i = 1:length(pos)
                elec_index = elec_position(pos(i));
                ClickStim(locx(elec_index), locy(elec_index), start_stim_pos);
            end
            stim_labels_train = [stim_labels_train, pattern_idx];
            pause(10);
        end
    end

    % 完成本批次，停止记录
    ClickOnce(stim_train_pos(1),stim_train_pos(2));%刺激器2
    ClickOnce(record_pos(1), record_pos(2)); % 停止记录
    pause(5)
    
    if batch < total_batches
        disp(['完成第 ', num2str(batch), ' 批次，准备下一批次...']);
    else
        disp('所有批次完成！');
    end
end
%% 5min 自放电记录
Record_Spon(300);
%% 第二轮测试
rng('shuffle');  % 设置随机数种子
stim_labels_test2 = []; % 用于记录所有时空刺激的标签
for batch = 1:total_batches
    % 开始新一批的记录
    ClickOnce(record_pos(1), record_pos(2)); % 开始记录
    pause(5)
    ClickOnce(stim_test_pos(1),stim_test_pos(2));%刺激器1

    % 每批stim_per_batch轮的随机刺激
    for round = 1:stim_per_batch
        % 随机打乱positions的顺序，并生成对应的标签
        rand_idx = randperm(size(positions, 1));
        shuffled_positions = positions(rand_idx, :);
        current_labels = rand_idx; % 当前轮次的标签记录

        % 对每个随机的声音编码序列进行刺激
        for p = 1:size(shuffled_positions, 1)
            pos = shuffled_positions(p, :);
            for i = 1:length(pos)
                elec_index = elec_position(pos(i)); % 获取elec_position中的实际电极位置索引
                ClickStim(locx(elec_index), locy(elec_index), start_stim_pos);
            end
            % 记录当前时空刺激的标签
            stim_labels_test2 = [stim_labels_test2, current_labels(p)];
            pause(10);
        end
    end

    % 完成本批次，停止记录
    ClickOnce(stim_test_pos(1),stim_test_pos(2));%刺激器1
    ClickOnce(record_pos(1), record_pos(2)); % 停止记录
    pause(5)
    
    if batch < total_batches
        disp(['完成第 ', num2str(batch), ' 批次，准备下一批次...']);
    else
        disp('所有批次完成！');
    end
end
%% 5min 自放电记录
Record_Spon(300);
%% 保存 stim_labels 为 .mat 文件
save('stim_labels.mat', 'stim_labels');
disp('时空刺激标签已保存为 stim_labels.mat 文件。');



%% ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓函数接口↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
%% 点击事件接口
function ClickOnce(x,y)
    import java.awt.Robot;
    import iava.awe.event.*;
    robot = java.awt.Robot;
    robot.mouseMove(-1,-1);
    robot.mouseMove(x,y);
    robot.mousePress (java.awt.event.InputEvent.BUTTON1_MASK);
    robot.mouseRelease (java.awt.event.InputEvent.BUTTON1_MASK);
end
%% 刺激事件接口
function ClickStim(x, y, start_stim_pos)
    ClickOnce(x, y);
    ClickOnce(start_stim_pos(1), start_stim_pos(2)); % 开始刺激
    pause(0.25);
    ClickOnce(x, y);
end
%% 记录自放电接口
function Record_Spon(time, record_pos)
    ClickOnce(record_pos(1), record_pos(2)); % 开始记录
    pause(time);
    ClickOnce(record_pos(1), record_pos(2)); % 结束记录
end

%% Test接口

%% Train接口