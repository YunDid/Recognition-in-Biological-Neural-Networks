%% 命名跟随excel的表格顺序来的
% 注意这个顺序不是下降了，而是错序了，按照excel表中的来

clc
clear
close all
electrodes_location = [ 1400,1200,1000,800,600,400,200,0,...
    1400,1200,1000,800,600,400,200,0,...
    1400,1200,1000,800,600,400,200,0,...
    1400,1200,1000,800,600,400,200,0,...
    1400,1200,1000,800,600,400,200,0,...
    1400,1200,1000,800,600,400,200,0,...
    1400,1200,1000,800,600,400,200,0,...
    1400,1200,1000,800,600,400,200,0;...
    0,0,0,0,0,0,0,0,...
    200,200,200,200,200,200,200,200,...
    400,400,400,400,400,400,400,400,...
    600,600,600,600,600,600,600,600,...
    800,800,800,800,800,800,800,800,...
    1000,1000,1000,1000,1000,1000,1000,1000,...
    1200,1200,1200,1200,1200,1200,1200,1200,...
    1400,1400,1400,1400,1400,1400,1400,1400];
electrodes_location2 = [ 1200,1000,800,600,400,200,...
    1400,1200,1000,800,600,400,200,0,...
    1400,1200,1000,800,600,400,200,0,...
    1400,1200,1000,800,600,400,200,0,...
    1400,1200,1000,800,600,400,200,0,...
    1400,1200,1000,800,600,400,200,0,...
    1400,1200,1000,800,600,400,200,0,...
    1200,1000,800,600,400,200;...
    0,0,0,0,0,0,...
    200,200,200,200,200,200,200,200,...
    400,400,400,400,400,400,400,400,...
    600,600,600,600,600,600,600,600,...
    800,800,800,800,800,800,800,800,...
    1000,1000,1000,1000,1000,1000,1000,1000,...
    1200,1200,1200,1200,1200,1200,1200,1200,...
    1400,1400,1400,1400,1400,1400];


parentFolder = 'K:\ZY\Voice_Data_Eight\temp'; 
% 获取文件夹内的文件和子文件夹列表
contents = dir(parentFolder);
% accuracy=zeros(15,18);
% 遍历每个文件或文件夹
for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        % 获取子文件夹的路径
        subFolder = fullfile(parentFolder, contents(i).name);
        % 显示子文件夹的名称
        disp(['子文件夹：' contents(i).name]);
        % 获取子文件夹内的文件列表
        maindir=fullfile(subFolder,'\sttc\hubness\result\');
        savedir=fullfile(subFolder,'\sttc\hubness\hub_pic\');     
        subdir=dir(fullfile(maindir,'*.mat'));
        fileNames={subdir.name};
        path=strcat(maindir,fileNames{1,1});
        data=load(path);
        ele=data.ele;
        hub=data.hub;
        % 这的个数和spike的文件一致
        num=[64 64 64 64 64 64 64 64 64]-sum(ele);
        n=[0 num(1) sum(num(1:2)) sum(num(1:3)) sum(num(1:4)) sum(num(1:5)) sum(num(1:6)) sum(num(1:7)) sum(num(1:8)) sum(num(1:9))];

        for i=1:size(ele, 2)
            elec=ele(:,i);
            hubness=hub((n(i)+1):n(i+1));
            a=find(elec==0);
            b=[a hubness'];
            scatter(electrodes_location2(2,:),electrodes_location2(1,:),400,'o', 'MarkerEdgeColor', '[0.9020    0.9412    0.9961]','MarkerFaceColor','[0.9020    0.9412    0.9961]','DisplayName', 'Stimulation Electrode')
            hold on
            for j=1:length(a)
                if b(j,2)==3
                    scatter(electrodes_location(2,b(j,1)),electrodes_location(1,b(j,1)),400,'o', 'MarkerEdgeColor', '[0.9059    0.2196    0.2784]','MarkerFaceColor','[0.9059    0.2196    0.2784]','DisplayName', 'Connector Hub')
                    hold on
                else if b(j,2)==2
                        scatter(electrodes_location(2,b(j,1)),electrodes_location(1,b(j,1)),400,'o', 'MarkerEdgeColor', '[0.9961    0.7176    0.0196]','MarkerFaceColor','[0.9961    0.7176    0.0196]','DisplayName', 'Provincial Hub')
                        hold on
                    else if b(j,2)==1
                            scatter(electrodes_location(2,b(j,1)),electrodes_location(1,b(j,1)),400,'o', 'MarkerEdgeColor', '[0.1294    0.6196    0.7373]','MarkerFaceColor','[0.1294    0.6196    0.7373]','DisplayName', 'Kinless Node')
                            hold on
                        else
                        end
                    end
                end

            end
        %     legend('show','Location','northeastoutside')
            axis equal
            axis off;
            set(gcf, 'Color', 'w');
            savepath= strcat(savedir,num2str(i));

            print(gcf,savepath,'-r600','-djpeg')%保存图片
        %     close
        end
        
    end
end

