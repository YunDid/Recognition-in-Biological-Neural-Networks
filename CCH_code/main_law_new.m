clc;
clear;
close all
% addpath('/Users/mengweiwei/Desktop/CritAnalysisSoftwarePackage2016-04-25')
parentFolder = 'E:\Voice_Data_Eight\Exported_process_data_CCH\20250324\1';
contents = dir(parentFolder);

% 创建一个表格来存储所有重要的数据
allResults = table();

n=0;
for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        n=n+1;
        subFolder = fullfile(parentFolder, contents(i).name);
        disp(['子文件夹：' contents(i).name]);
        % 获取子文件夹内的文件列表
        subContents=dir(fullfile(subFolder,'spike_con/','*.mat'));
        fileNamess={subContents.name};
        % 构建保存文件夹的完整路径
        savedir1=strcat(subFolder,'/av/');
        mkdir(savedir1);
        %         savedir2=strcat(savedir1,'pic/');
        %         mkdir(savedir2)
        % 遍历子文件夹内的每个文件
        for j = 1:length(fileNamess)
            path=fullfile(subFolder,'spike_con',fileNamess(j));
            d=load(path{1,1});
            spikes=d.electrodeSpikes;
            for r=1:length(spikes)
                spikes{r,1}=round(spikes{r,1}*1000);
                spikes{r,1}(spikes{r,1}>300000)=[];
            end
            asdf2.raster=spikes;
            asdf2.binsize=1;
            asdf2.nbins=300000;
            asdf2.nchannels=length(spikes);
            b=0;
            sp=[];
            for p=1:length(spikes)
               sp=[sp asdf2.raster{p,1}]; 
            end
            sp=sort(sp,'descend');
            isi=sp(1:(length(sp)-1))-sp(2:length(sp));
            mean_isi=mean(isi);
            bin=ceil(mean_isi);
%             for bin=[1 5 10 20 40 ]
                b=b+1;
                newAsdf2 = rebin(asdf2, bin);
                % Compute all avalanche properties
                Av = avprops(newAsdf2, 'ratio', 'fingerprint');
                %% Compute power-law parameters using macro
                
                % size distribution (SZ)
                [tau, xminSZ, xmaxSZ, sigmaSZ, pSZ, pCritSZ, ksDR, DataSZ] =...
                    avpropvals(Av.size, 'size','plot');
                law(n,b)=tau{1,1};        p_v(n,b)=pSZ{1,1};
                savepath= strcat(savedir1,'size-',fileNamess(j));
                savepath=erase(savepath,'.mat');
                print(gcf,savepath{1,1},'-r600','-djpeg')%保存图片
                close
                % duration distribution (DR)
                [alpha, xminDR, xmaxDR, sigmaDR, pDR, pCritDR, ksDR, DataDR] =...
                    avpropvals(Av.duration, 'duration','plot');
                law(n,b+6)=alpha{1,1};      p_v(n,b+6)=pDR{1,1};
                savepath= strcat(savedir1,'duration-',fileNamess(j));
                savepath=erase(savepath,'.mat');
                print(gcf,savepath{1,1},'-r600','-djpeg')%保存图片
                close
                % size given duration distribution (SD)
                [sigmaNuZInvSD, waste, waste, sigmaSD] = avpropvals({Av.size, Av.duration},...
                    'sizgivdur', 'durmin', xminDR{1}, 'durmax', xmaxDR{1},'plot');
                law(n,b+12)=sigmaNuZInvSD;
                savepath= strcat(savedir1,'sidu-',fileNamess(j));
                savepath=erase(savepath,'.mat');
                print(gcf,savepath{1,1},'-r600','-djpeg')%保存图片
                close
                %% Perform avalanche shape collapse for all shapes
                
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
                
%                 sigmaSC = avshapecollapsestd(avgProfiles);
%                 
%                 title(['Avalanche Shape Collapse', char(10), '1/(sigma nu z) = ',...
%                     num2str(sigmaNuZInvSC), ' +/- ', num2str(sigmaSC)], 'fontsize', 14)
%                 savepath= strcat(savedir1,'collapse-',fileNamess(j));
%                 savepath=erase(savepath,'.mat');
%                 print(gcf,savepath{1,1},'-r600','-djpeg')%保存图片
                close
                
                % 将重要的值存储到临时表格中
                currentRow = table();
                currentRow.SubFolder = {contents(i).name};
                currentRow.FileName = {fileNamess{j}};
                currentRow.Tau = tau{1,1};                % Size distribution exponent
                currentRow.Alpha = alpha{1,1};            % Duration distribution exponent
                currentRow.SigmaNuZInvSD = sigmaNuZInvSD; % Size given duration
                if isempty(sigmaNuZInvSC)
                    sigmaNuZInvSC = NaN;
                end
                currentRow.SigmaNuZInvSC = sigmaNuZInvSC; % Shape collapse statistics
%                 currentRow.SigmaNuZInvSC = sigmaNuZInvSC; % Shape collapse statistics
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