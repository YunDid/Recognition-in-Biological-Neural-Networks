clc;
clear;
close all
% 指定要遍历的文件夹路径
parentFolder = 'E:\Voice_Data_Eight\Voice_data_export\20250215_0117C1_HTrain_Cell1_medium\STTC';
% 获取文件夹内的文件和子文件夹列表
contents = dir(parentFolder);
% 遍历每个文件或文件夹
a=0;
up=[1 2 3 4 9 10 11 12 17 18 19 20 25 26 27 28 33 34 35 36 ...
    41 42 43 44 49 50 51 52 57 58 59 60 ];
for i = 1:length(contents)
    % 忽略当前目录（.）和上一级目录（..）
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        % 获取子文件夹的路径
        subFolder = fullfile(parentFolder, contents(i).name);
        % 显示子文件夹的名称
        disp(['子文件夹：' contents(i).name]);
        a=a+1;
        % 获取子文件夹内的文件列表
        subContents=dir(fullfile(subFolder,'te-network','*.mat'));
        fileNamess={subContents.name};
        for j=1%:length(fileNamess)
            path=fullfile(subFolder,'te-network',fileNamess(j));
            data=load(path{1,1});
            IT=data.IT2;
            delet=data.delet_units;
            ele=find(delet>0);
           
            up_area=[];down_area=[];
            for k=1:length(ele)
                if ismember(ele(k,1),up)
                    up_area(k,1)=1;down_area(k,1)=0;
                else
                    up_area(k,1)=0;down_area(k,1)=1;
                end
            end
            up_down=[];up_up=[];down_up=[];down_down=[];
            for m=1:length(ele)
                if up_area(m)>0
                    up_down(m)=IT(m,:)*down_area;
                    up_up(m)=IT(m,:)*up_area;
                else
                    down_up(m)=IT(m,:)*up_area;
                    down_down(m)=IT(m,:)*down_area;
                end
            end
            TI(a,j)=sum(up_down);TI(a,j+6)=sum(up_up);
            TI(a,j+12)=sum(down_up);TI(a,j+18)=sum(down_down);
            percent(a,j)=TI(a,j)/sum(sum(IT))*100;
            percent(a,j+6)=TI(a,j+6)/sum(sum(IT))*100;
            percent(a,j+12)=TI(a,j+12)/sum(sum(IT))*100;
            percent(a,j+18)=TI(a,j+18)/sum(sum(IT))*100;
            percent2(a,j)=TI(a,j)/(TI(a,j)+TI(a,j+6))*100;
            percent2(a,j+6)=TI(a,j+6)/(TI(a,j)+TI(a,j+6))*100;
            percent2(a,j+12)=TI(a,j+12)/(TI(a,j+12)+TI(a,j+18))*100;
            percent2(a,j+18)=TI(a,j+18)/(TI(a,j+12)+TI(a,j+18))*100;
        end
    end
end