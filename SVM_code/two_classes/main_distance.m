clc;
clear;
close all
% 指定要遍历的文件夹路径
parentFolder = '/Users/mengweiwei/Desktop/结果/svm/2分类/merged';
% 获取文件夹内的文件和子文件夹列表
contents = dir(parentFolder);
up = repmat([1,1,1,1,0,0,0,0],1,8);
down=repmat([0,0,0,0,1,1,1,1],1,8);
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
            savedir1=strcat(subFolder,'/sound/',num2str(k),'ms/');
            % 创建文件夹
            mkdir(savedir1);
            % 遍历子文件夹内的每个文件
            for j = 1:3
                    path=fullfile(subFolder,fileNamess(j));% path
                    d=load(path{1,1});%spikes data
                    [active_ch]=active_channel(d,k*0.001,up,down);%活跃电极
                    [sti_data,interval]=stimulus_data(d,active_ch,k*0.001);
                    %                     bin=[500,250,100,50,10,5];
                    bin=10;
                    [sound1,sound2]=instance(sti_data,interval,bin*0.001);
                    sound=[sound1;sound2];
                    label=[zeros(1,30),ones(1,30)];
                    savepath=strcat(savedir1,fileNamess(j));
                    save (savepath{1,1},'sound','label')

%                     sound3=zscore(sound);
%                     sound1=sound3(1:30,:);
%                     sound2=sound3(31:60,:);
%                     %% test类内距
%                     distances_matrix1 = pdist(sound1);
%                     distances_matrix2 = pdist(sound2);
%                     %将距离转换为矩阵形式
%                     distances_matrix1_matrix = squareform(distances_matrix1);
%                     distances_matrix2_matrix = squareform(distances_matrix2);
%                     test(k+1,j)  =(sum(sum(distances_matrix1_matrix))/(30*29))/(4800^(1/2));
%                     test(k+1,j+4)=(sum(sum(distances_matrix2_matrix))/(30*29))/(4800^(1/2));
%                     %% test类间距
%                     distances_between_matrices = pdist2(sound1, sound2);
%                     test(k+1,j+8)=(sum(sum(distances_between_matrices))/(30*30))/(4800^(1/2));
            end
        end
%         savepath2=strcat('/Users/mengweiwei/Desktop/结果/svm/2分类/distance/merged/',contents(i).name,'-dis.xlsx');
%         writematrix(test, savepath2);
%         savepath3=strcat('/Users/mengweiwei/Desktop/svm/classification/merged/',contents(i).name,'-rbf.xlsx');
%         writematrix(accuracy_rbf, savepath3);
    end
end
