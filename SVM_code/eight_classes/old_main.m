%% Date:2024/03/19 8分类 3轮测试
clc;
clear;
close all

order=load('E:\Voice_Data_Eight\Voice_data_export\20250208_0117C1_Con\Con-onlyPDMS\Sti\SVM\sti.mat');
label=order.stim_labels';
% 指定要遍历的文件夹路径
parentFolder = 'E:\Voice_Data_Eight\Voice_data_export\20250208_0117C1_Con\Con-onlyPDMS\Sti\SVM\';
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
            path=fullfile(subFolder,fileNamess(1));% path
            d=load(path{1,1});%spikes data
            path2=fullfile(subFolder,fileNamess(2));% path
            d2=load(path2{1,1});%spikes data
            path3=fullfile(subFolder,fileNamess(3));% path
            d3=load(path3{1,1});%spikes data
            path4=fullfile(subFolder,fileNamess(4));% path
            d4=load(path4{1,1});%spikes data
            
            [active_ch]=new_active_channel(d,d2,d3,d4,k*0.001,up,down);%活跃电极
            
            [sti_data,interval]=new_stimulus_data(d,active_ch,k*0.001);
            [sti_data2,interval2]=new_stimulus_data(d2,active_ch,k*0.001);
            [sti_data3,interval3]=new_stimulus_data(d3,active_ch,k*0.001);
            [sti_data4,interval4]=new_stimulus_data(d4,active_ch,k*0.001);
            
            bin=10;
            p=bin;
            
            [ins1]=instance(sti_data,interval,p*0.001);
            [ins2]=instance(sti_data2,interval2,p*0.001);
            [ins3]=instance(sti_data3,interval3,p*0.001);
            [ins4]=instance(sti_data4,interval4,p*0.001);
            ins=[ins1;ins2;ins3;ins4];
            
            class1=find(label==1);
            class2=find(label==2);
            class3=find(label==3);
            class4=find(label==4);
            class5=find(label==5);
            class6=find(label==6);
            class7=find(label==7);
            class8=find(label==8);
            
            train1=ins(class1(1:21),:);test1=ins(class1(22:28),:);
            train2=ins(class2(1:21),:);test2=ins(class2(22:28),:);
            train3=ins(class3(1:21),:);test3=ins(class3(22:28),:);
            train4=ins(class4(1:21),:);test4=ins(class4(22:28),:);
            train5=ins(class5(1:21),:);test5=ins(class5(22:28),:);
            train6=ins(class6(1:21),:);test6=ins(class6(22:28),:);
            train7=ins(class7(1:21),:);test7=ins(class7(22:28),:);
            train8=ins(class8(1:21),:);test8=ins(class8(22:28),:);
            
            train=[train1;train2;train3;train4;train5;train6;train7;train8];
            test=[test1;test2;test3;test4;test5;test6;test7;test8];
            % 类标签
            repeat1 = 21;repeat2 = 7;
            trainLabel=repelem(1:8, repeat1)';
            testLabel=repelem(1:8, repeat2)';
            [model_linear,bestcv2,bestg2,bestc2,train_ins2] = svm_sequence_linear_train(train,trainLabel);
            [predict_label2, accu2,test_ins2] = svm_sequence_linear_test(test,train,testLabel,model_linear);
            accuracy_linear(k+1)=accu2(1);
%             savepath=strcat(savedir1,fileNamess(k+1));
%             save (savepath{1,1},'sti_data','active_ch','train','test')
        end
        savepath2 = strcat(pwd, '/', contents(i).name, '-linear.xlsx');
        writematrix(accuracy_linear, savepath2);
    end
end
