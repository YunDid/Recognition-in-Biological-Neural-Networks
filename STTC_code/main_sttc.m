%% Date:2024/03/23 计算STTC
clc;
clear;
close all
parentFolder = 'E:\Voice_Data_Eight\Exported_process_data_Htrain\20250314\1';
contents = dir(parentFolder);
for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        subFolder = fullfile(parentFolder, contents(i).name);
        disp(['子文件夹：' contents(i).name]);
        % 获取子文件夹内的文件列表
        subContents=dir(fullfile(subFolder,'train_spon_spike/','*.mat'));
        fileNamess={subContents.name};
        % 构建保存文件夹的完整路径
        savedir1=strcat(subFolder,'/sttc/');
        mkdir(savedir1);
        savedir2=strcat(savedir1,'pic/');
        mkdir(savedir2)
        % 遍历子文件夹内的每个文件
        for j = 1:length(fileNamess)
            path=fullfile(subFolder,'train_spon_spike',fileNamess(j));
            d=load(path{1,1});
            spikes=d.electrodeSpikes; % 需要注意具体spike.mat的字段名称
%% tiling coefficient over all electrode pairs
            method = 'tileCoef';
            downSample = 0;     %不用管设为0就好
            lag = 0.03;         %Δt,s
            time = 200;         %时间总长，s
            [adjM, activeElectrode] = getAdjM(spikes, method, downSample, lag, time);
%             adjM(isnan(adjM)) = 0;             %clear nan
            adjM(1:size(adjM,1)+1:end)=nan;      %clear diagonal
%             adjM(adjM < 0.35)=0;               %clear 随机连接
            savepath=strcat(savedir1,'sttc-',fileNamess(j));
            save (savepath{1,1},'adjM','activeElectrode')
%% 连接矩阵图
            figure
            h = imagesc(adjM);
            xlabel('Electrode')
            ylabel('Electrode')
            yticks([1, 10:10:60])
            xticks([1, 10:10:60])
            set(gca,'TickDir','out');
            cb = colorbar;
            ylabel(cb, 'Correlation')
            cb.TickDirection = 'out';
            caxis([0 1])
            cb.Ticks = 0:0.1:1;
            set(gca,'TickDir','out');
            cb.Location = 'Eastoutside';
            cb.Box = 'off';
            set(gca, 'FontSize', 11)
            axis square;
            xLength = 300;
            yLength = xLength;
            set(gcf, 'Position', [0 0 xLength yLength])
            
            savepath2= strcat(savedir2,'matrix-',fileNamess(j));
            savepath2=erase(savepath2,'.mat');
            print(gcf,savepath2{1,1},'-r600','-djpeg')%保存图片
            close
%% Network plot!
            figure
            goodElectrodes =1:64;
%             adjM(adjM <= 0.1) = NaN;
            plotAdj(adjM, goodElectrodes')
            
            yLength = 800;
            xLength = yLength * 1;
            set(gcf, 'Position', [100 100 xLength yLength])
            axis equal;
            
            savepath3= strcat(savedir2,'network-',fileNamess(j),'.jpg');
            savepath3=erase(savepath3,'.mat');
            exportgraphics(gcf, savepath3{1,1}, 'Resolution', 600);
            print(gcf,savepath3{1,1},'-r600','-djpeg')%保存图片
            close
            
%% Relationship between correlation coefficient and distance
            % set up distance matrix
            gridLength = 8;
            electrodePairs = npermutek(1:gridLength, 2);
            % remove the 4 corners
            %             corners = [1; 8; 57; 64];
            %             electrodePairs(corners, :) = [ ];
            % distanceMatrix = pdist(electrodePairs, 'euclidean'); % nope
            distanceMatrix = distmat(electrodePairs);
            % remove self connections
            distanceMatrix(logical(eye(size(distanceMatrix)))) = NaN;
            corrMatrix = adjM;
%             corrMatrix(logical(eye(size(corrMatrix)))) = NaN;
%             corrMatrix(corrMatrix == 0) = NaN;
            % plot relationship between distance and corr coef
            figure
            dotSize = 60;
            elecSpacingCoef = 200;
            scatter(distanceMatrix(:) * elecSpacingCoef, corrMatrix(:), dotSize, 'filled', 'MarkerFaceAlpha',.5,'MarkerEdgeAlpha',0);
            xlabel('Distance (\mum)')
            ylabel('Correlation')
            set(gca, 'FontSize', 14)
            set(gca,'TickDir','out');
            ylim([0 1])
            set(gcf, 'Position', [100, 100, 500 * 16/9, 500])
            savepath4= strcat(savedir2,'distance-',fileNamess(j));
            savepath4=erase(savepath4,'.mat');
            print(gcf,savepath4{1,1},'-r600','-djpeg')%保存图片
            close
            % plot individual electrodes with different colours
            %             figure
            %             dotSize = 64;
            %             elecSpacingCoef = 200; % they are 200 micro-meters apart (\mu m)
            %             for elec = 1:64
            %                 scatter(distanceMatrix(:, elec) * elecSpacingCoef, corrMatrix(:, elec), dotSize, 'filled', 'MarkerFaceAlpha',.5,'MarkerEdgeAlpha',0);
            %                 hold on
            %             end
            %             xlabel('Distance (\mum)')
            %             ylabel('Tiling coefficient')
            %             set(gca, 'FontSize', 14)
            %             set(gca,'TickDir','out');
%% distance distribution plot multiple histograms
            distAndCorr = [distanceMatrix(:) * elecSpacingCoef, corrMatrix(:)];
            % find high correlation distacne: > 0.8
            distAndHighCorr = distAndCorr(distAndCorr(:, 2) >= 0.8, 1);
            % find medium correlation distances: 0.5 - 0.8
            distAndMedCorr = distAndCorr(distAndCorr(:, 2) >= 0.5 & distAndCorr(:, 2) < 0.8, 1);
            % find low correlation distances: < 0.5
            distAndLowCorr = distAndCorr(distAndCorr(:, 2) < 0.5, 1);
            
            
            % one way is to use bar
            % https://uk.mathworks.com/matlabcentral/answers/288261-how-to-get-multiple-groups-plotted-with-histogram
            edges = 200:200:1800;
            
            h1 = histcounts(distAndHighCorr, edges) / size(distAndCorr, 1) * 100; % make it a proportion value
            h2 = histcounts(distAndMedCorr, edges) / size(distAndCorr, 1) * 100;
            h3 = histcounts(distAndLowCorr, edges) / size(distAndCorr, 1) * 100;
            
            figure
            bar(edges(1:end-1),[h1; h2; h3]', 'EdgeColor','white')
            
            ylabel('Proportion of connections (%)')
            xlabel('Distance (\mum)')
            % xlim([200 1700])
            legend('High correlation (> 0.8)', 'Medium correlation (0.5 - 0.8)', 'Low correlation (< 0.5)')
            legend boxoff
            set(gca,'TickDir','out');
            set(gcf, 'Position', [100, 100, 500 * 16/9, 500])
            set(gca, 'FontSize', 14)
%             mymap=[];
%             colormap(mymap)
            savepath5= strcat(savedir2,'distance2-',fileNamess(j),'.jpg');
            savepath5=erase(savepath5,'.mat');
            print(gcf,savepath5{1,1},'-r600','-djpeg')%保存图片
            close
%% distance distribution plot with trendline           
            distAndHighCorrCount = histcounts(distAndHighCorr, edges);
            distAndMedCorrCount = histcounts(distAndMedCorr, edges);
            distAndLowCorrCount = histcounts(distAndLowCorr, edges);
            
            distAndHighCorrProp = histcounts(distAndHighCorr, edges) / size(distAndCorr, 1) * 100; % make it a proportion value
            distAndMedCorrProp = histcounts(distAndMedCorr, edges) / size(distAndCorr, 1) * 100;
            distAndLowCorrProp = histcounts(distAndLowCorr, edges) / size(distAndCorr, 1) * 100;

            figure
            numbins = 8;
            fitmethod = 'gamma';
            
            % Low Correlation
            if ~isempty(distAndLowCorr)
                h3 = histfit(distAndLowCorr, numbins, fitmethod);
                h3Color = [166, 206, 227] / 255;
                set(h3(2), 'color', h3Color);
                delete(h3(1))
                hold on
            else
            end
            % Medium Correlation
            h2 = histfit(distAndMedCorr, numbins, fitmethod);
            h2Color = [178, 223,138] / 255;
            set(h2(2),'color', h2Color);
            delete(h2(1))
            hold on

            % High Correlation
            if ~isempty(distAndHighCorr)
                h1 = histfit(distAndHighCorr, numbins, fitmethod);
                h1Color = [31, 120, 180] / 255;
                set(h1(2),'color',h1Color);
                % remove the bars
                delete(h1(1))
                hold on
            else
            end
            % labels and legends
            ylabel('Number of connections')
            xlabel('Distance (\mum)')
            % aesthetics
            % legend({'High correlation (> 0.8)', 'Medium correlation (0.3 - 0.8)', 'Low correlation (< 0.3)'})
            % legend boxoff
            
            % overlay scatter
% %             dotSize = 50;
% %             scatter(edges(1:8), distAndHighCorrCount, dotSize, h1Color, 'filled')
% %             scatter(edges(1:8), distAndMedCorrCount, dotSize, h2Color, 'filled')
% %             scatter(edges(1:8), distAndLowCorrCount, dotSize, h3Color, 'filled')
% %             
% %             xlim([100 1700])
% %             edges = 200:200:1800;
% %             xticks(edges)
            
            % convert from raw count to proportion
            % yt = get(gca, 'YTick');
            % set(gca, 'YTick', yt, 'YTickLabel', round(yt/size(distAndCorr, 1) * 100 ) )
            % ylabel('Proportion of connections (%)')
            
            % only label lines and not the dots
            h = findobj(gca,'Type','line');
            legend(h, {'High correlation (> 0.8)', 'Medium correlation (0.5 - 0.8)', 'Low correlation (< 0.5)'})
            % legend(h, {'Low correlation (< 0.3)', 'Medium correlation (0.3 - 0.8)', 'High correlation (> 0.8)'})
            legend boxoff
            set(gca,'TickDir','out');
            set(gcf, 'Position', [100, 100, 500 * 16/9, 500])
            set(gca, 'FontSize', 14)
            savepath6= strcat(savedir2,'distance2-',fileNamess(j),'.jpg');
            savepath6=erase(savepath6,'.mat');
            print(gcf,savepath6{1,1},'-r600','-djpeg')%保存图片
            close
        end
        
        
        %         savepath2=strcat('/Users/mengweiwei/Desktop/svm/2分类/classification/cch/',contents(i).name,'-linear.xlsx');
        %         writematrix(accuracy_linear, savepath2);
    end
end

disp(['end']);