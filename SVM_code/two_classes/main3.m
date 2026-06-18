%% Date:2024/04/06 2分类,全局网络，上下区域 ，时空信息
clc;
clear;
close all
% 指定要遍历的文件夹路径
parentFolder = '/Users/mengweiwei/Desktop/结果/svm/2分类/modular';
% 获取文件夹内的文件和子文件夹列表
contents = dir(parentFolder);
up=repmat([1,1,1,1,0,0,0,0], 1,8);
down=repmat([0,0,0,0,1,1,1,1],1,8);
% accuracy=zeros(15,18);
% 遍历每个文件或文件夹
for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        % 获取子文件夹的路径
        subFolder = fullfile(parentFolder, contents(i).name);
        % 显示子文件夹的名称
        disp(['子文件夹：' contents(i).name]);
        % 获取子文件夹内的文件列表
        subContents=dir(fullfile(subFolder,'*.mat'));
        fileNamess={subContents.name};
        for k=0:1:20
            % 构建保存文件夹的完整路径
            savedir1=strcat(subFolder,'/stimulation/',num2str(k),'ms/');
            % 创建文件夹
%             mkdir(savedir1);
            % 遍历子文件夹内的每个文件
            for j = 1
                path=fullfile(subFolder,fileNamess(j));% path
                d=load(path{1,1});%spikes data
                [active_ch,up_ch,down_ch]=active_channel(d,k*0.001,up,down);%活跃电极
                [sti_data,interval]=stimulus_data(d,active_ch,k*0.001);
                [sti_data_up,interval_up]=stimulus_data(d,up_ch,k*0.001);
                [sti_data_down,interval_down]=stimulus_data(d,down_ch,k*0.001);
                %                     bin=[500,250,100,50,10,5];
                bin=10;
                for p=bin
                    label_0=zeros(30,1);label_1=ones(30,1);
                    trainLabel=[label_0(1:24);label_1(1:24)];
                    testLabel=[label_0(25:30);label_1(25:30)];
                    %% 全局网络
                    [sound1_ds,sound2_ds,sound1_dt,sound2_dt,sound1_dst,sound2_dst]=instance_st(sti_data,interval,p*0.001);
                    
                    train_ds=[sound1_ds(1:24,:);sound2_ds(1:24,:)];
                    test_ds=[sound1_ds(25:30,:);sound2_ds(25:30,:)];
                    [model_linear_ds] = svm_sequence_linear_train(train_ds,trainLabel);
                    [predict_label_ds, accu_ds] = svm_sequence_linear_test(test_ds,train_ds,testLabel,model_linear_ds);
                    accuracy_linear(k+1,j)=accu_ds(1);
                    
                    train_dt=[sound1_dt(1:24,:);sound2_dt(1:24,:)];
                    test_dt=[sound1_dt(25:30,:);sound2_dt(25:30,:)];
                    [model_linear_dt] = svm_sequence_linear_train(train_dt,trainLabel);
                    [predict_label_dt, accu_dt] = svm_sequence_linear_test(test_dt,train_dt,testLabel,model_linear_dt);
                    accuracy_linear(k+1,j+1)=accu_dt(1);
                    
                    train_dst=[sound1_dst(1:24,:);sound2_dst(1:24,:)];
                    test_dst=[sound1_dst(25:30,:);sound2_dst(25:30,:)];
                    [model_linear_dst] = svm_sequence_linear_train(train_dst,trainLabel);
                    [predict_label_dst, accu_dst] = svm_sequence_linear_test(test_dst,train_dst,testLabel,model_linear_dst);
                    accuracy_linear(k+1,j+2)=accu_dst(1);
                    
                    %% input
                    [sound1_ds_up,sound2_ds_up,sound1_dt_up,sound2_dt_up,sound1_dst_up,sound2_dst_up]=instance_st(sti_data_up,interval_up,p*0.001);
                    
                    train_ds_up=[sound1_ds_up(1:24,:);sound2_ds_up(1:24,:)];
                    test_ds_up=[sound1_ds_up(25:30,:);sound2_ds_up(25:30,:)];
                    [model_linear_ds_up] = svm_sequence_linear_train(train_ds_up,trainLabel);
                    [predict_label_ds_up, accu_ds_up] = svm_sequence_linear_test(test_ds_up,train_ds_up,testLabel,model_linear_ds_up);
                    accuracy_linear(k+1,j+3)=accu_ds_up(1);
                    
                    train_dt_up=[sound1_dt_up(1:24,:);sound2_dt_up(1:24,:)];
                    test_dt_up=[sound1_dt_up(25:30,:);sound2_dt_up(25:30,:)];
                    [model_linear_dt_up] = svm_sequence_linear_train(train_dt_up,trainLabel);
                    [predict_label_dt_up, accu_dt_up] = svm_sequence_linear_test(test_dt_up,train_dt_up,testLabel,model_linear_dt_up);
                    accuracy_linear(k+1,j+4)=accu_dt_up(1);
                    
                    train_dst_up=[sound1_dst_up(1:24,:);sound2_dst_up(1:24,:)];
                    test_dst_up=[sound1_dst_up(25:30,:);sound2_dst_up(25:30,:)];
                    [model_linear_dst_up] = svm_sequence_linear_train(train_dst_up,trainLabel);
                    [predict_label_dst_up, accu_dst_up] = svm_sequence_linear_test(test_dst_up,train_dst_up,testLabel,model_linear_dst_up);
                    accuracy_linear(k+1,j+5)=accu_dst_up(1);
                    
                    %% output
                    [sound1_ds_down,sound2_ds_down,sound1_dt_down,sound2_dt_down,sound1_dst_down,sound2_dst_down]=instance_st(sti_data_down,interval_down,p*0.001);
                    
                    train_ds_down=[sound1_ds_down(1:24,:);sound2_ds_down(1:24,:)];
                    test_ds_down=[sound1_ds_down(25:30,:);sound2_ds_down(25:30,:)];
                    [model_linear_ds_down] = svm_sequence_linear_train(train_ds_down,trainLabel);
                    [predict_label_ds_down, accu_ds_down] = svm_sequence_linear_test(test_ds_down,train_ds_down,testLabel,model_linear_ds_down);
                    accuracy_linear(k+1,j+6)=accu_ds_down(1);
                    
                    train_dt_down=[sound1_dt_down(1:24,:);sound2_dt_down(1:24,:)];
                    test_dt_down=[sound1_dt_down(25:30,:);sound2_dt_down(25:30,:)];
                    [model_linear_dt_down] = svm_sequence_linear_train(train_dt_down,trainLabel);
                    [predict_label_dt_down, accu_dt_down] = svm_sequence_linear_test(test_dt_down,train_dt_down,testLabel,model_linear_dt_down);
                    accuracy_linear(k+1,j+7)=accu_dt_down(1);
                    
                    train_dst_down=[sound1_dst_down(1:24,:);sound2_dst_down(1:24,:)];
                    test_dst_down=[sound1_dst_down(25:30,:);sound2_dst_down(25:30,:)];
                    [model_linear_dst_down] = svm_sequence_linear_train(train_dst_down,trainLabel);
                    [predict_label_dst_down, accu_dst_down] = svm_sequence_linear_test(test_dst_down,train_dst_down,testLabel,model_linear_dst_down);
                    accuracy_linear(k+1,j+8)=accu_dst_down(1);
                end
%                 savepath=strcat(savedir1,fileNamess(j));
%                 save (savepath{1,1},'sti_data','sti_data_up','sti_data_down','interval','interval_up','interval_down','active_ch','up_ch','down_ch')
            end    
        end
        savepath2=strcat('/Users/mengweiwei/Desktop/结果/svm/2分类/classification/modular-st/','0406-',contents(i).name,'-linear.xlsx');
        writematrix(accuracy_linear, savepath2);
    end
end
% savepath2=strcat('/Users/mengweiwei/Desktop/svm/classification/','modular-linear.xlsx');
% writematrix(accuracy_linear, savepath2);