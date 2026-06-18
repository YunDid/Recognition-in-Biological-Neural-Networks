%% Date:2024/03/27 计算有效网络
clc;
clear;
close all
% addpath('/Users/mengweiwei/Desktop/CODEs/BCT/2019_03_03_BCT/')
parentFolder = 'E:\Voice_Data_Eight\Voice_data_export\20250215_0117C1_HTrain_Cell1_medium\STTC';
contents = dir(parentFolder);
n=0;
for i = 1:length(contents)
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        n=n+1;
        subFolder = fullfile(parentFolder, contents(i).name);
        disp(['子文件夹：' contents(i).name]);
        % 获取子文件夹内的文件列表
        subContents=dir(fullfile(subFolder,'spike/','*.mat'));
        fileNamess={subContents.name};
        % 构建保存文件夹的完整路径
        savedir1=strcat(subFolder,'/te/');
        mkdir(savedir1);
        %         savedir2=strcat(savedir1,'pic/');
        %         mkdir(savedir2)
        % 遍历子文件夹内的每个文件
        for j = 1:length(fileNamess)
            path=fullfile(subFolder,'spike',fileNamess(j));
            d=load(path{1,1});
            %% spike数据格式转换为asdf，计算每个电极的信息熵
            spikes=d.electrodeSpikes; %spike数据
            entropy_value=zeros(length(spikes),1);%每个电极信息熵
            delet_units=ones(length(spikes),1);
            %% 剔除掉5min内放电总个数少于60的神经元
            asdf=cell(length(spikes),1);
            for jj=1:length(spikes)
                if length(spikes{jj,1})>=60
                    asdf{jj,1}=spikes{jj,1}*1000;
                    prob_0=(5*60*1000-length(asdf{jj,1}))/(5*60*1000);%5min数据
                    prob_1=length(asdf{jj,1})/(5*60*1000);
                    ent=-prob_0*log2(prob_0)-prob_1*log2(prob_1);%电极的信息熵
                    entropy_value(jj,1)=ent;
                else
                    delet_units(jj,1)=0;
                end
            end
            del_units=find(delet_units==0);
            if ~isempty(del_units)% 剔除放电率小于60的unit
                del_units=sort(del_units ,'descend');
                for d=1:length(del_units)
                    asdf(del_units(d),:)=[];
                    entropy_value(del_units(d),:)=[];
                end
            else
            end
            asdf{length(entropy_value)+2,1}=[length(entropy_value),5*60*1000];%5min数据，单位ms
            asdf{length(entropy_value)+1,1}=1;%时间窗为1ms
            %     asdf(cellfun('isempty',asdf))={0};%将空赋为0
            %% 计算高阶延时传递熵
            [peak_TE, C_I, TEdelays] = ASDFTE(asdf, 1:20, 1, 3);%计算高阶延时传递熵
            peakTE = peak_TE - diag(diag(peak_TE));%去除自身传递熵
            CI = C_I - diag(diag(C_I));%去除自身CI
            %% 有效连接显著性检验
            jitter_TE=cell(length(entropy_value),1);
            jitter_CI=cell(length(entropy_value),1);
            %     rng('default')
            for s=1:length(entropy_value)
                da1=asdf{s,1};
                jit=[];
                for w=1:length(da1)
                    a=normrnd(da1(w),10,100,1); %产生100个高斯随机数
                    jit=[jit,a];
                end
                TE_jit=[];
                CI_jit=[];
                tic
                for f=1:100
                    se=jit(f,:);
                    se=round(se);
                    se=sort(se);
                    
                    for r=1:length(entropy_value)
                        re=asdf{r,1};
                        
                        if ~(r==s)
                            asdf_jit=cell(4,1);
                            asdf_jit{1,1}=se;
                            asdf_jit{2,1}=re;
                            asdf_jit{3,1}=1;
                            asdf_jit{4,1}=[2,5*60*1000];%5min数据，单位ms
                            [peak_TE_jit, C_I_jit, TEdelays_jit] = ASDFTE(asdf_jit, 1:20, 1, 3);%计算高阶延时传递熵
                            TE_jit(r,f)=peak_TE_jit(1,2);
                            CI_jit(r,f)=C_I_jit(1,2);
                        else
                        end
                    end
                    jitter_TE{s,1}=TE_jit;
                    jitter_CI{s,1}=CI_jit;
                end
                toc
            end
            %% 保存数据
            savepath=strcat(savedir1,'TE-',fileNamess(i));
            save(savepath{1,1},'asdf','peak_TE','C_I', 'TEdelays','jitter_TE','jitter_CI','entropy_value','delet_units','del_units')
        end
    end
    
end           