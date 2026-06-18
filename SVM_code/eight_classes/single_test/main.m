%% Date:2024/03/19 5分类 1轮测试
clc;
clear;
close all
order=load('/Users/mengweiwei/Desktop/5分类/stimulus_marker/1227-1.mat');
label=order.order';
% 指定要遍历的文件夹路径
parentFolder = '/Users/mengweiwei/Desktop/5分类/spike/single_test';
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
            m=0;
            for j = 1:3:length(fileNamess)
                m=m+1;
                    path=fullfile(subFolder,fileNamess(j));% path
                    d=load(path{1,1});%spikes data
                    path2=fullfile(subFolder,fileNamess(j+1));% path
                    d2=load(path2{1,1});%spikes data
                    path3=fullfile(subFolder,fileNamess(j+2));% path
                    d3=load(path3{1,1});%spikes data
                    [active_ch]=active_channel(d,d2,d3,k*0.001,up,down);%活跃电极
                    [sti_data,interval]=stimulus_data(d,active_ch,k*0.001);
                    [sti_data2,interval2]=stimulus_data(d2,active_ch,k*0.001);
                    [sti_data3,interval3]=stimulus_data(d3,active_ch,k*0.001);
%                     bin=[250,10];
                    bin=10;
                    nu=0;
                    for p=bin
                        nu=nu+1;
                        [ins1]=instance(sti_data,interval,p*0.001);
                        [ins2]=instance(sti_data2,interval2,p*0.001);
                        [ins3]=instance(sti_data3,interval3,p*0.001);
                        ins=[ins1;ins2;ins3];
                        class1=find(label==1);
                        class2=find(label==2);
                        class3=find(label==3);
                        class4=find(label==4);
                        class5=find(label==5);
                        train1=ins(class1(1:24),:);test1=ins(class1(25:30),:);
                        train2=ins(class2(1:24),:);test2=ins(class2(25:30),:);
                        train3=ins(class3(1:24),:);test3=ins(class3(25:30),:);
                        train4=ins(class4(1:24),:);test4=ins(class4(25:30),:);
                        train5=ins(class5(1:24),:);test5=ins(class5(25:30),:);
                        train=[train1;train2;train3;train4;train5];
                        test=[test1;test2;test3;test4;test5];
                        % 类标签
                        repeat1 = 24;repeat2 = 6;
                        trainLabel=repelem(1:5, repeat1)';
                        testLabel=repelem(1:5, repeat2)';
                        [model_linear,bestcv2,bestg2,bestc2,train_ins2] = svm_sequence_linear_train(train,trainLabel);
                        [predict_label2, accu2,test_ins2] = svm_sequence_linear_test(test,train,testLabel,model_linear);
                        accuracy_linear(k+1,m)=accu2(1);
                    end
                    savepath=strcat(savedir1,fileNamess(j));
                    save (savepath{1,1},'sti_data','active_ch','train','test')
            end
        end
        savepath2=strcat('/Users/mengweiwei/Desktop/5分类/svm/',contents(i).name,'-linear.xlsx');
        writematrix(accuracy_linear, savepath2);
        %         savepath3=strcat('/Users/mengweiwei/Desktop/svm/classification/merged/',contents(i).name,'-rbf.xlsx');
        %         writematrix(accuracy_rbf, savepath3);
    end
end
