%% Date:2024/03/18 2分类，输入数据为NEX导出的spike序列，不需要经过spikeData2
clc;
clear;
close all
% 指定要遍历的文件夹路径
parentFolder = 'E:\TestingData\三次实验，电刺激二分类数据\实验三';
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
        for k=10
            % 构建保存文件夹的完整路径
            savedir1=strcat(subFolder,'/stimulation/',num2str(k),'ms/');  
            % 创建文件夹
            mkdir(savedir1);
            % 遍历子文件夹内的每个文件
            for j = 1:1
                    path=fullfile(subFolder,fileNamess(j));% path
                    d=load(path{1,1});%spikes data
                    [active_ch]=active_channel(d,k*0.001,up,down);%活跃电极
                    [sti_data,interval]=stimulus_data(d,active_ch,k*0.001);
%                     bin=[500,250,100,50,10,5];
                    bin=20;
                    nu=0;
                    for p=bin
                        nu=nu+1;
                        [sound1,sound2]=instance(sti_data,interval,p*0.001);
                        label_0=zeros(30,1);label_1=ones(30,1);
                        train=[sound1(1:24,:);sound2(1:24,:)];
                        trainLabel=[label_0(1:24);label_1(1:24)];
                        test=[sound1(25:30,:);sound2(25:30,:)];
                        testLabel=[label_0(25:30);label_1(25:30)];
                        [model_linear,bestcv,bestg,bestc,train_ins] = svm_sequence_linear_train(train,trainLabel);
%                         [model_rbf,bestcv2,bestg2,bestc2,train_ins2] = svm_sequence_rbf_train(train,trainLabel);
                        [predict_label, accu,test_ins] = svm_sequence_linear_test(test,train,testLabel,model_linear);
%                         [predict_label2, accu2,test_ins2] = svm_sequence_rbf_test(test,train,testLabel,model_rbf);
                        accuracy_linear(i-2,j+3*(nu-1))=accu(1)
                        
%                         accuracy_rbf(k+1,j+3*(nu-1))=accu2(1);
                    end
%                     savepath=strcat(savedir1,fileNamess(j));
%                     save (savepath{1,1},'sti_data','active_ch','sound1','sound2')
            end
        end
%         savepath2=strcat('/Users/mengweiwei/Desktop/svm/2分类/classification/cch/',contents(i).name,'-linear.xlsx');
%         writematrix(accuracy_linear, savepath2);
%         savepath3=strcat('/Users/mengweiwei/Desktop/svm/classification/merged/',contents(i).name,'-rbf.xlsx');
%         writematrix(accuracy_rbf, savepath3);
%         all_accuracy_linear = [all_accuracy_linear;accuracy_linear;]
    end
end
