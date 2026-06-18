clc;
clear;
close all
% addpath('/Users/mengweiwei/Desktop/CritAnalysisSoftwarePackage2016-04-25')
parentFolder = 'E:\Voice_Data_Eight\Exported_process_data_CCH\20250324\1';
contents = dir(parentFolder);

% 创建一个表格来存储所有重要的数据
allResults = table();

for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        subFolder = fullfile(parentFolder, contents(i).name);
        disp(['子文件夹：' contents(i).name]);
        % 获取子文件夹内的文件列表
        subContents=dir(fullfile(subFolder,'spike_cch/','*.mat'));
        fileNamess={subContents.name};
        % 构建保存文件夹的完整路径
        savedir1=strcat(subFolder,'/av/');
        mkdir(savedir1);
        %         savedir2=strcat(savedir1,'pic/');
        %         mkdir(savedir2)
        % 遍历子文件夹内的每个文件
        for j = 1:length(fileNamess)
            path=fullfile(subFolder,'spike_cch',fileNamess(j));
            d=load(path{1,1});
            spikes=d.electrodeSpikes;
            for r=1:length(spikes)
                spikes{r,1}=round(spikes{r,1}*1000);
                spikes{r,1}(spikes{r,1}>300000)=[];
            end
            
            %% 基于输入的 spike train 出计算临界性指标的总参数 Av，ISI前面的计算只为了计算 bin 这个指标，ISI的计算可以变
            asdf2.raster=spikes;
            asdf2.binsize=1;
            asdf2.nbins=300000;
            asdf2.nchannels=64;
            sp=[];
            for p=1:64
               sp=[sp asdf2.raster{p,1}]; 
            end
            sp=sort(sp,'descend');
            isi=sp(1:(length(sp)-1))-sp(2:length(sp));
            mean_isi=mean(isi);
            bin=ceil(mean_isi);
                newAsdf2 = rebin(asdf2, bin);
                % Compute all avalanche properties
                Av = avprops(newAsdf2, 'ratio', 'fingerprint');
                %% Compute power-law parameters using macro  出 a b r 三个参数，这个可以把tau，alpha，sigmaNuZInvSD 保存下来
                
                % size distribution (SZ)
                [tau, xminSZ, xmaxSZ, sigmaSZ, pSZ, pCritSZ, ksDR, DataSZ] =...
                    avpropvals(Av.size, 'size','plot');
                savepath= strcat(savedir1,'size-',fileNamess(j));
                savepath=erase(savepath,'.mat');
                print(gcf,savepath{1,1},'-r600','-djpeg')%保存图片
                close
                % duration distribution (DR)
                [alpha, xminDR, xmaxDR, sigmaDR, pDR, pCritDR, ksDR, DataDR] =...
                    avpropvals(Av.duration, 'duration','plot');
                savepath= strcat(savedir1,'duration-',fileNamess(j));
                savepath=erase(savepath,'.mat');
                print(gcf,savepath{1,1},'-r600','-djpeg')%保存图片
                close
                % size given duration distribution (SD)
                [sigmaNuZInvSD, waste, waste, sigmaSD] = avpropvals({Av.size, Av.duration},...
                    'sizgivdur', 'durmin', xminDR{1}, 'durmax', xmaxDR{1},'plot');
                savepath= strcat(savedir1,'sidu-',fileNamess(j));
                savepath=erase(savepath,'.mat');
                print(gcf,savepath{1,1},'-r600','-djpeg')%保存图片
                close
                %% Perform avalanche shape collapse for all shapes  出临界性指标其他一些示意图的 具体参数先不管
                % compute average temporal profiles
                avgProfiles = avgshapes(Av.shape, Av.duration, 'cutoffs', 4, 20);
                
                % plot all profiles
                figure;
                for iProfile = 1:length(avgProfiles)
                    hold on
                    plot(1:length(avgProfiles{iProfile}), avgProfiles{iProfile});
                end
                hold off
                xlabel('Time Bin, t', 'fontsize', 14)
                ylabel('Neurons Active, s(t)', 'fontsize', 14)
                title('Mean Temporal Profiles', 'fontsize', 14)
                savepath= strcat(savedir1,'shape-',fileNamess(j));
                savepath=erase(savepath,'.mat');
                print(gcf,savepath{1,1},'-r600','-djpeg')%保存图片
                close
                % compute shape collapse statistics (SC) and plot
                [sigmaNuZInvSC, secondDrv, range, errors] = avshapecollapse(avgProfiles, 'plot');  
                sigmaSC = avshapecollapsestd(avgProfiles);  
                title(['Avalanche Shape Collapse', char(10), '1/(sigma nu z) = ',...
                    num2str(sigmaNuZInvSC), ' +/- ', num2str(sigmaSC)], 'fontsize', 14)
                savepath= strcat(savedir1,'collapse-',fileNamess(j));
                savepath=erase(savepath,'.mat');
                print(gcf,savepath{1,1},'-r600','-djpeg')%保存图片
                close
                
                
                %% 最后汇总数据用的 这个不同的批处理操作需求不一样
                % 将重要的值存储到临时表格中
                currentRow = table();
                currentRow.SubFolder = {contents(i).name};
                currentRow.FileName = {fileNamess{j}};
                currentRow.Tau = tau{1,1};                % Size distribution exponent
                currentRow.Alpha = alpha{1,1};            % Duration distribution exponent
                currentRow.SigmaNuZInvSD = sigmaNuZInvSD; % Size given duration
                currentRow.SigmaNuZInvSC = sigmaNuZInvSC; % Shape collapse statistics
                currentRow.BinSize = bin;                 % 当前使用的bin大小
                
                % 将当前行添加到总表格中
                allResults = [allResults; currentRow];
%             end
        end
    end
end

% 将所有结果保存到父目录中的Excel文件
excelFile = fullfile(parentFolder, 'Avalanche_AnalysisResults.xlsx');
writetable(allResults, excelFile, 'Sheet', 'Results');
disp(['分析结果已保存到: ' excelFile]);

matFile = fullfile(parentFolder, 'Avalanche_AnalysisResults.mat');
save(matFile, 'allResults');
disp(['分析结果已同时保存为MAT格式: ' matFile]);