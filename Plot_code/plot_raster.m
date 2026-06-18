clc
clear 
close all
% maindir='E:\Voice_Data_Eight\Exported_process_data_CCH\20250324\C1_20250324_MCCH_Cell0218\spike_cch\';
% savedir='E:\Voice_Data_Eight\Exported_process_data_CCH\20250324\C1_20250324_MCCH_Cell0218\spike_cch\raster\';
% subdir=dir(fullfile(maindir,'*.mat'));
% fileNames={subdir.name};
% 
parentFolder = 'E:\Voice_Data_Eight\20250311_Eight_CCH_export_mat\20251021'; 
% 获取文件夹内的文件和子文件夹列表
contents = dir(parentFolder);
% 遍历每个文件或文件夹
for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        % 获取子文件夹的路径
        subFolder = fullfile(parentFolder, contents(i).name);
        % 显示子文件夹的名称
        disp(['子文件夹：' contents(i).name]);
        % 获取子文件夹内的文件列表
        inputDir=fullfile(subFolder,'\spike_con\');
        outputDir=fullfile(subFolder,'\spike_con\raster\');      
        mkdir(outputDir);
        
        %% 获取目录中所有mat文件
        matFiles = dir(fullfile(inputDir, '*.mat'));
        matFileNames = {matFiles.name};
            
        for jj=1:length(matFileNames)
            yyaxis left
            path=strcat(inputDir,matFileNames(jj));
            data=load(path{1,1});
            spike=data.electrodeSpikes;
            % 原始的元胞数组
            originalCellArray = spike; % 这里替换成你的元胞数组
            % 计算每个元胞内元素的个数
            numElementsInCell = cellfun(@numel, originalCellArray);
            % 根据元素个数对原始元胞数组进行排序
            [sortedNumElements, sortedIndices] = sort(numElementsInCell, 'descend');
            % 提取前59个最多的元胞（改为60是因为第一个可能被跳过）
            top59CellsIndices = sortedIndices(2:60);
            top59Cells = originalCellArray(top59CellsIndices);
            % 恢复原来的先后顺序
            [~, restoreIndices] = sort(top59CellsIndices);
            newspike = top59Cells(restoreIndices);
            spikes=[];
            for j=1:59
                dataa=newspike{j,1};
                dataa=dataa(dataa>=25 & dataa<=325)-25;
                spikes=[spikes dataa];
                for f=1:length(dataa)
                    plot([dataa(f),dataa(f)],[j-1,j-0.1],'LineStyle','-','Marker','none','Color',[66/256,183/256,185/256],'linewidth',0.5)
                    hold on
                end
            end
            %     axis([0 60,0 59])%窗口的长度和高度
            xlim([0,300])
            ylim([0,59])
            set(gca,'ycolor',[0/256,155/256,158/256])
            xlabel('Time(s)')
            ylabel('Channel')
            %     set(gca,'xtick',[],'ytick',[])
            %     set(gca,'Visible','off')%去除坐标轴
            fr=[];
            for h=1:3000
                t1=0.1*(h-1);
                t2=t1+0.1;
                a=length(find(spikes>t1 & spikes<=t2));
                fr(h)=a;
            end
            fr=fr/0.1/1000;
            b=max(fr);
            fr1=smoothdata(fr,'gaussian',8);
            x=(0.1:0.1:300);
            yyaxis right
            b2=max(fr1);
            plot(x,fr1,'Color',[214/256,145/256,193/256],'linewidth',1.5)
            ylim([0,2.5])
            ylabel('Pop.firing rate(kHz)')
            set(gca,'ycolor',[199/256,93/256,171/256])
            set(gca, 'FontName', 'Times New Roman', 'FontSize', 25);
            savepath= strcat(outputDir,matFileNames(jj));
            savepath=erase(savepath,'.mat');
            print(gcf,savepath{1,1},'-r600','-djpeg')%保存图片
            close
        end
    end
end