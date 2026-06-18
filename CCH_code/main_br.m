clc;
clear;
close all
% addpath('/Users/mengweiwei/Desktop/CritAnalysisSoftwarePackage2016-04-25')
parentFolder = 'E:\Voice_Data_Eight\Exported_process_data_CCH\20250324\';
contents = dir(parentFolder);
n=0;
for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        n=n+1;
        subFolder = fullfile(parentFolder, contents(i).name);
        disp(['子文件夹：' contents(i).name]);
        % 获取子文件夹内的文件列表
        subContents=dir(fullfile(subFolder,'spike_cch/','*.mat'));
        fileNamess={subContents.name};
        for j = 1:length(fileNamess)
            path=fullfile(subFolder,'spike_cch',fileNamess(j));
            d=load(path{1,1});
            spikes=d.electrodeSpikes;
            for r=1:length(spikes)
                spikes{r,1}=round(spikes{r,1}*1000);
                spikes{r,1}(spikes{r,1}>300000)=[]; 
            end
            asdf2.raster=spikes;
            asdf2.binsize=1;
            asdf2.nbins=300000;
            asdf2.nchannels=64;
            [br,slopevals,brsimple] = brestimate(asdf2);
            result(n,j)=br;
            result(n,j+length(fileNamess))=brsimple;
        end
    end
end