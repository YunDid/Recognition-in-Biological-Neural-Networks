    clc
    clear
    close all
    import java.awt.Robot;
    import java.awt.event.*;
    robot = Robot();
    %% ↓↓↓↓↓↓↓↓↓↓↓↓↓↓   参数配置   ↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    % 参数结构体
    params = struct();
    % 电极坐标
    params.locx = [888 918 945 973 1002 1029 ...
        862 888 918 945 973 1002 1029 1055 ...
        862 888 918 945 973 1002 1029 1055 ...
        862 888 918 945 973 1002 1029 1055 ...
        862 888 918 945 973 1002 1029 1055 ...
        862 888 918 945 973 1002 1029 1055 ...
        862 888 918 945 973 1002 1029 1055 ...
        888 918 945 973 1002 1029] - 146;
    params.locy = [418 418 418 418 418 418 ...
        455 455 455 455 455 455 455 455 ...
        474 474 474 474 474 474 474 474 ...
        501 501 501 501 501 501 501 501 ...
        531 531 531 531 531 531 531 531 ...
        558 558 558 558 558 558 558 558 ...
        585 585 585 585 585 585 585 585 ... 
        615 615 615 615 615 615] - 102;

    % 刺激参数
    params.positions = [    1 1 1 3 5 5;
        3 2 1 2 3 3;
        5 3 5 3 5 3;
        1 1 5 5 6 6;
        5 6 5 4 3 1;
        3 3 4 5 5 4;
        4 3 2 1 6 5;
        3 5 3 1 2 3];
    params.elec_position = [3,7,9,11,13,18];

    % 界面坐标
    params.record_pos = [213, 44];
    params.stim_test_pos = [726, 171];
    params.stim_train_pos = [755, 173];
    params.start_stim_pos = [350, 40];

    % 实验参数
    params.total_batches_test = 4;
    params.total_batches_train = 8;
    params.stim_per_batch_test = 7; 
    params.stim_per_batch_train = 28; 

    %% ↓↓↓↓↓↓↓↓↓↓↓↓↓↓   实验流程   ↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    pause(10);

    % 自放电记录
    Record_Spon(300, params.record_pos);

    % 第一轮测试
    rng('shuffle');
    stim_labels_test1 = run_test(params, params.stim_test_pos);

    % 自放电记录
    Record_Spon(300, params.record_pos);

    % 训练阶段
    stim_labels_train = run_train(params, params.stim_train_pos);

    % 自放电记录
    Record_Spon(300, params.record_pos);

    % 第二轮测试
    rng('shuffle');
    stim_labels_test2 = run_test(params, params.stim_test_pos);

    % 自放电记录
    Record_Spon(300, params.record_pos);

    % 保存结果
    save('stim_labels.mat', 'stim_labels_test1', 'stim_labels_train', 'stim_labels_test2');
    disp('实验数据已保存');


    %% ↓↓↓↓↓↓↓↓↓↓↓↓↓↓   接口函数   ↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    %% 测试阶段函数
    function stim_labels = run_test(params, stim_pos)
        stim_labels = [];
        for batch = 1:params.total_batches_test
            % 开始记录
            ClickOnce(params.record_pos(1), params.record_pos(2));
            pause(5);
            ClickOnce(stim_pos(1), stim_pos(2));

            % 每批次刺激
            for round = 1:params.stim_per_batch_test
                rand_idx = randperm(size(params.positions,1));
                current_positions = params.positions(rand_idx, :);

                % 施加刺激序列
                for p = 1:size(current_positions,1)
                    process_stim_sequence(params, current_positions(p,:));
                    stim_labels = [stim_labels, rand_idx(p)];
                    pause(10);
                end
            end

            % 停止记录
            ClickOnce(stim_pos(1), stim_pos(2));
            ClickOnce(params.record_pos(1), params.record_pos(2));
            pause(5);
        end
    end

    %% 训练阶段函数
    function stim_labels = run_train(params, stim_pos)
        stim_labels = [];
        for batch = 1:params.total_batches_train
            % 开始记录
            ClickOnce(params.record_pos(1), params.record_pos(2));
            pause(5);
            ClickOnce(stim_pos(1), stim_pos(2));

            % 顺序施加刺激模式
            for repeat = 1:params.stim_per_batch_train
                process_stim_sequence(params, params.positions(batch,:));
                stim_labels = [stim_labels, batch];
                pause(10);
            end

            % 停止记录
            ClickOnce(stim_pos(1), stim_pos(2));
            ClickOnce(params.record_pos(1), params.record_pos(2));
            pause(5);
        end
    end

    %% 通用刺激序列执行函数 - 单次声音刺激
    function process_stim_sequence(params, sequence)
        for i = 1:length(sequence)
            elec_idx = params.elec_position(sequence(i));
            x = params.locx(elec_idx);
            y = params.locy(elec_idx);
            ClickStim(x, y, params.start_stim_pos);
        end
    end

    %% ↓↓↓↓↓↓↓↓↓↓↓↓↓   基础函数   ↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    function ClickOnce(x,y)
        import java.awt.Robot;
        import iava.awe.event.*;
        robot = java.awt.Robot;
        robot.mouseMove(-1,-1);
        robot.mouseMove(x,y);
        robot.mousePress (java.awt.event.InputEvent.BUTTON1_MASK);
        robot.mouseRelease (java.awt.event.InputEvent.BUTTON1_MASK);
    end

    function ClickStim(x, y, start_pos)
        ClickOnce(x, y);
        ClickOnce(start_pos(1), start_pos(2));
        pause(0.25);
        ClickOnce(x, y);
    end

    function Record_Spon(time, record_pos)
        ClickOnce(record_pos(1), record_pos(2));
        pause(time);
        ClickOnce(record_pos(1), record_pos(2));
    end