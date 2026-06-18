%% Date:2024/03/18 2分类,全局网络，上下区域
clc;
clear;
close all
% 指定要遍历的文件夹路径
parentFolder = '/Users/mengweiwei/Desktop/结果/svm/2分类/merged';
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
            mkdir(savedir1);
            % 遍历子文件夹内的每个文件
            for j = 1:3
                path=fullfile(subFolder,fileNamess(j));% path
                d=load(path{1,1});%spikes data
                [active_ch,up_ch,down_ch]=active_channel(d,k*0.001,up,down);%活跃电极
                [sti_data,interval]=stimulus_data(d,active_ch,k*0.001);
                [sti_data_up,interval_up]=stimulus_data(d,up_ch,k*0.001);
                [sti_data_down,interval_down]=stimulus_data(d,down_ch,k*0.001);
                %                     bin=[500,250,100,50,10,5];
                bin=10;
                for p=bin
                    [sound1,sound2]=instance(sti_data,interval,p*0.001);
                    label_0=zeros(30,1);label_1=ones(30,1);
                    train=[sound1(1:24,:);sound2(1:24,:)];
                    trainLabel=[label_0(1:24);label_1(1:24)];
                    test=[sound1(25:30,:);sound2(25:30,:)];
                    testLabel=[label_0(25:30);label_1(25:30)];
                    [model_linear,bestcv,bestg,bestc,train_ins] = svm_sequence_linear_train(train,trainLabel);
                    [predict_label, accu,test_ins] = svm_sequence_linear_test(test,train,testLabel,model_linear);
                    accuracy_linear(k+1,j)=accu(1);
                    
                    [sound1_up,sound2_up]=instance(sti_data_up,interval_up,p*0.001);
                    label_0=zeros(30,1);label_1=ones(30,1);
                    train_up=[sound1_up(1:24,:);sound2_up(1:24,:)];
                    trainLabel=[label_0(1:24);label_1(1:24)];
                    test_up=[sound1_up(25:30,:);sound2_up(25:30,:)];
                    testLabel=[label_0(25:30);label_1(25:30)];
                    [model_linear_up,bestcv_up,bestg_up,bestc_up,train_ins_up] = svm_sequence_linear_train(train_up,trainLabel);
                    [predict_label_up, accu_up,test_ins_up] = svm_sequence_linear_test(test_up,train_up,testLabel,model_linear_up);
                    accuracy_linear(k+1,j+3)=accu_up(1);
                    
                    [sound1_down,sound2_down]=instance(sti_data_down,interval_down,p*0.001);
                    label_0=zeros(30,1);label_1=ones(30,1);
                    train_down=[sound1_down(1:24,:);sound2_down(1:24,:)];
                    trainLabel=[label_0(1:24);label_1(1:24)];
                    test_down=[sound1_down(25:30,:);sound2_down(25:30,:)];
                    testLabel=[label_0(25:30);label_1(25:30)];
                    [model_linear_down,bestcv_down,bestg_down,bestc_down,train_ins_down] = svm_sequence_linear_train(train_down,trainLabel);
                    [predict_label_down, accu_down,test_ins_down] = svm_sequence_linear_test(test_down,train_down,testLabel,model_linear_down);
                    accuracy_linear(k+1,j+6)=accu_down(1);
                end
                savepath=strcat(savedir1,fileNamess(j));
                save (savepath{1,1},'sti_data','sti_data_up','sti_data_down','interval','interval_up','interval_down','active_ch','up_ch','down_ch')
            end    
        end
        savepath2=strcat('/Users/mengweiwei/Desktop/结果/svm/2分类/classification/merged/','0329new-',contents(i).name,'-linear.xlsx');
        writematrix(accuracy_linear, savepath2);
    end
end
% savepath2=strcat('/Users/mengweiwei/Desktop/svm/classification/','modular-linear.xlsx');
% writematrix(accuracy_linear, savepath2);