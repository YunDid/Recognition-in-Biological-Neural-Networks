%% Date:2024/03/24 计算hub节点
clc;
clear;
close all
% addpath('/Users/mengweiwei/Desktop/code_final/STTC/BCT/2019_03_03_BCT/')
parentFolder = 'K:\ZY\Voice_Data_Eight\temp\';
contents = dir(parentFolder);
n=0;
for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        n=n+1;
        subFolder = fullfile(parentFolder, contents(i).name);
        disp(['子文件夹：' contents(i).name]);
        % 获取子文件夹内的文件列表
        subContents=dir(fullfile(subFolder,'/sttc/hubness','*.mat'));
        fileNamess={subContents.name};
        % 构建保存文件夹的完整路径
%         savedir1=strcat(subFolder,'/network/');
%         mkdir(savedir1);
        savedir2=strcat(subFolder,'/sttc/hubness/result/');
        mkdir(savedir2)
        % 遍历子文件夹内的每个文件
        bc=[];cloc=[];deg=[];eloc=[];str=[];ele=[];num=[];
        for j = 1:length(fileNamess)
%         for j = 1:3  
            path=fullfile(subFolder,'sttc/hubness/',fileNamess(j));
            data=load(path{1,1});
            bc=[bc; data.bc];
            cloc=[cloc data.cloc];
            deg=[deg data.deg];
            eloc=[eloc; data.eloc];
            str=[str data.str];
            ele=[ele data.zero_rows*1];
            num=[num length(str)];
        end
        mean_str=str./deg;
        
        a=sort(mean_str,'descend');
        b=sort(cloc,'descend');
        c=sort(eloc,'descend');
        d=round(0.4*length(a));
        a1=(mean_str>=a(d))*1;
        b1=(cloc>=b(d))*1;
        c1=(eloc>=c(d))*1;
        hub=a1+b1+c1';
        s(n,1)=sum(hub(1:num(1)))/num(1);
        s(n,2)=sum(hub(num(1)+1:num(2)))/(num(2)-num(1));
        s(n,3)=sum(hub(num(2)+1:num(3)))/(num(3)-num(2));
        savepath= strcat(savedir2,'result.mat');
        save(savepath,'ele','hub')
    end
end