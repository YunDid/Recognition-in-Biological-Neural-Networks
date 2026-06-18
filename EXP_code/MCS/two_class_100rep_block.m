clc
clear
close
import java.awt.Robot;
robot = java.awt.Robot;

%% 电极位点位置：沿用八分类脚本中已经校准过的鼠标坐标
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

%% 八分类脚本中的 8 条声音编码序列
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

% 八分类脚本中 1-6 号逻辑位点对应的实际鼠标点击点位
elec_position = [3,7,9,11,13,18];

% 二分类只选其中两条声音编码。需要换声音时，只改这里的编号 1-8。
sound1_id = 1;
sound2_id = 2;

% pos1/pos2 是实际 locx/locy 索引，供下面 ClickOnce 使用。
pos1 = elec_position(positions(sound1_id, :));
pos2 = elec_position(positions(sound2_id, :));

%% 界面坐标：沿用八分类脚本中已经校准过的鼠标坐标
record_pos = [213, 44];
stim_test_pos = [726, 171];
stim_start_pos = [350, 40];

%% 实验参数
% 分块协议：批次 1-2 全做序列1，批次 3-4 全做序列2，每批 50 次。
test_batches = 4;
reps_per_batch = 50;            % 每批次施加 50 次（同一条序列连续 50 次）
batch_sequence_id = [1 1 2 2];  % 每批次对应的序列编号：前两批序列1、后两批序列2
stim_step_interval = 0.25;
trial_interval = 10;
record_gap = 5;

stim_labels_test = [];
stim_batch_ids_test = [];
stim_trial_ids_test = [];
stim_source_ids_test = [];
global_trial_id = 0;

pause(5)

%% 加药状态下单轮 test：每类 100 次，总计 200 trials（按批次分块施加）
for batch = 1:test_batches
    sequence_id = batch_sequence_id(batch);   % 本批次固定施加的序列

    if sequence_id == 1
        current_pos = pos1;
        source_sound_id = sound1_id;
    else
        current_pos = pos2;
        source_sound_id = sound2_id;
    end

    ClickOnce(record_pos(1), record_pos(2)); % 开始记录
    pause(record_gap)
    ClickOnce(stim_test_pos(1), stim_test_pos(2)); % 选择测试刺激器

    for rep = 1:reps_per_batch
        for i = 1:length(current_pos)
            ClickStim(locx(current_pos(i)), locy(current_pos(i)), stim_start_pos, stim_step_interval);
        end

        pause(trial_interval)
        global_trial_id = global_trial_id + 1;
        stim_labels_test = [stim_labels_test, sequence_id]; %#ok<AGROW>
        stim_source_ids_test = [stim_source_ids_test, source_sound_id]; %#ok<AGROW>
        stim_batch_ids_test = [stim_batch_ids_test, batch]; %#ok<AGROW>
        stim_trial_ids_test = [stim_trial_ids_test, global_trial_id]; %#ok<AGROW>
    end

    ClickOnce(stim_test_pos(1), stim_test_pos(2)); % 关闭测试刺激器
    ClickOnce(record_pos(1), record_pos(2)); % 停止记录
    pause(record_gap)
end

%% 保存标签
protocol = struct();
protocol.condition = 'drug_test_only';
protocol.stim_order = 'block';   % 分块施加：序列1 全部做完再做序列2
protocol.sound1_id = sound1_id;
protocol.sound2_id = sound2_id;
protocol.test_batches = test_batches;
protocol.reps_per_batch = reps_per_batch;
protocol.batch_sequence_id = batch_sequence_id;
protocol.test_reps_per_sequence_total = sum(batch_sequence_id == 1) * reps_per_batch;
protocol.test_trials_total = test_batches * reps_per_batch;
protocol.stim_step_interval = stim_step_interval;
protocol.trial_interval = trial_interval;

save('stim_labels_two_class_100rep_drug_test_block.mat', ...
    'protocol', 'stim_labels_test', 'stim_source_ids_test', ...
    'stim_batch_ids_test', 'stim_trial_ids_test');
disp('Two-class drug-condition block-order test labels saved to stim_labels_two_class_100rep_drug_test_block.mat.');

%% 点击事件接口
function ClickOnce(x,y)
import java.awt.Robot;
robot = java.awt.Robot;
robot.mouseMove(-1,-1);
robot.mouseMove(x,y);
robot.mousePress(java.awt.event.InputEvent.BUTTON1_MASK);
robot.mouseRelease(java.awt.event.InputEvent.BUTTON1_MASK);
end

%% 刺激事件接口
function ClickStim(x, y, start_stim_pos, stim_step_interval)
    ClickOnce(x, y);
    ClickOnce(start_stim_pos(1), start_stim_pos(2));
    pause(stim_step_interval);
    ClickOnce(x, y);
end
