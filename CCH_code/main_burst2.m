%% 神经网络放电活动与爆发分析脚本
% 此脚本从多通道神经元记录数据中提取和分析单通道及网络级别的爆发活动特征
%
% 计算的主要指标:
%   1. 单通道爆发分析:
%      - ch_mbr: 单通道爆发率(Mean Burst Rate)，每个活跃电极每秒的爆发次数
%      - ch_bd: 单通道爆发持续时间(Burst Duration)，单个爆发的平均持续时间
%      - ch_sib: 爆发内脉冲百分比(Spikes In Burst)，爆发内脉冲占总脉冲的百分比
%      - mfr: 平均放电率(Mean Firing Rate)，每个活跃电极每秒的平均脉冲数
%
%   2. 网络级爆发分析:
%      - net_mbr: 网络爆发率，每秒网络爆发的次数
%      - net_bd: 网络爆发持续时间，网络爆发的平均持续时间
%
% 使用方法：
%   1. 设置正确的数据路径(parentFolder)
%   2. 确保有BurstDetectISIn函数用于爆发检测
%   3. 运行脚本进行批量分析
%
% 注意: 此脚本使用ISI方法(NN=2, isi_nn=0.1)检测爆发，并定义了爆发标准(S>=5)
%       和活跃电极标准(爆发数>=20)。网络爆发定义为至少20%活跃电极参与的事件。

clc;
clear;
close all

% 指定要遍历的文件夹路径
parentFolder = 'E:\Voice_Data_Eight\Exported_process_data_CCH\20250324';
% 获取文件夹内的文件和子文件夹列表
contents = dir(parentFolder);
% 遍历每个文件或文件夹
n=0;
for i = 1:length(contents)
    % 忽略当前目录（.）和上一级目录（..）
    if contents(i).isdir && ~strcmp(contents(i).name, '.') && ~strcmp(contents(i).name, '..')
        % 获取子文件夹的路径
        subFolder = fullfile(parentFolder, contents(i).name);
        % 显示子文件夹的名称
        disp(['子文件夹：' contents(i).name]);
        n=n+1;
        % 获取子文件夹内的文件列表
        subContents=dir(fullfile(subFolder,'spike_cch','*.mat'));
        fileNamess={subContents.name};
        for jj=1:length(fileNamess)
            path=fullfile(subFolder,'spike_cch',fileNamess(jj));
            data=load(path{1,1});
            spikes=data.electrodeSpikes;
            ch_burst=cell(64,1);        %每个单通道burst
            ch_spike_number=cell(64,1); %每个单通道spike
            active=zeros(64,1);         %活跃电极
            burst_start=cell(64,1);     %每个单通道burst开始时间
            burst_end=cell(64,1);       %每个单通道burst结束时间
            %提取单通道爆发
            ch_total_bursts=0;ch_BD=[];ch_total_spikes=0;ch_total_sib=0;
            for j=1:length(spikes)
                if ~isempty(spikes{j,1})
                    NN=2;
                    isi_nn=0.1;
                    %提取单通道burst
                    [Burst, SpikeBurstNumber] = BurstDetectISIn( spikes{j,1}, NN, isi_nn);
                    d=find(Burst.S>=5);
                    Burst.S=Burst.S(1,d);
                    Burst.T_end=Burst.T_end(1,d);
                    Burst.T_start=Burst.T_start(1,d);
                    
                    ch_BD=[ch_BD Burst.T_end-Burst.T_start];
                    ch_total_bursts=ch_total_bursts+length(Burst.T_start);
                    ch_total_spikes=ch_total_spikes+length(SpikeBurstNumber);
                    ch_total_sib=ch_total_sib+sum(Burst.S);
                    %确定活跃电极
                    if length(Burst.T_start)>=20
                        active(j)=1;
                        burst_start{j,1}=Burst.T_start;
                        burst_end{j,1}=Burst.T_end;
                    else
                    end
                    ch_burst{j,1}=Burst;
                    ch_spike_number{j,1}=SpikeBurstNumber;
                else
                end
            end
            ch_mbr(n,jj)=ch_total_bursts/sum(active)/5;
            ch_bd(n,jj)=mean(ch_BD);
            ch_sib(n,jj)=ch_total_sib/ch_total_spikes*100;
            mfr(n,jj)=ch_total_spikes/5/sum(active);
%             savepath= strcat(savedir1,'ch_burst-',num2str(i),'.mat');
%             save(savepath,'ch_burst','ch_spike_number')
            %提取网络爆发
            burst_s=[];ch=[];burst_e=[];
            for k=1:64
                burst_s=[burst_s burst_start{k,1}];              %所有单通道爆发起始时间
                burst_e=[burst_e burst_end{k,1}];                %所有单通道爆发结束时间
                ch=[ch k*ones(1,length(burst_start{k,1}))];      %每个爆发对应的通道
            end
            [burst1, sortOrder] = sort(burst_s);
            % 使用排序顺序
            ch1 = ch( sortOrder);
            burst2=burst_e( sortOrder);
            [net_Burst, net_SpikeBurstNumber] = BurstDetectISIn( burst1, 2, 0.1);
            % 网络爆发的数量
            a=find(net_Burst.S>=sum(active)*0.2);
            net_mbr(n,jj)=length(a)/5;
%             num_net_burst=[num_net_burst length(find(net_Burst.S>sum(active)*0.2))];
            % 网络爆发结果,将不属于网络爆发的爆发剔除
            b=net_SpikeBurstNumber~=-1;
            net_burst_start=burst1(:,b);
            net_burst_end=burst2(:,b);
            net_burst_ch=ch1(:,b);
            net_burst_num=net_SpikeBurstNumber(:,b);
            c = find(net_Burst.S<sum(active)*0.2);%不符合网络爆发标准的网络爆发
            %网络爆发包含单通道信息，将不符合网络爆发标准的网络爆发
            for x=1:length(c)
                b=net_burst_num~=c(x);
                net_burst_start=net_burst_start(:,b);
                net_burst_end=net_burst_end(:,b);
                net_burst_ch=net_burst_ch(:,b);
                net_burst_num=net_burst_num(:,b);
            end
%             savepath= strcat(savedir1,'net_burst-ch-',num2str(i),'.mat');
%             save(savepath,'net_burst_start','net_burst_end','net_burst_ch','net_burst_num')
            %网络爆发
            Net_burst_end=[];e=0;
            for y=1:length(a)
                d=length(find(net_burst_num==a(y)));
                e=e+d;
                Net_burst_end(y)=net_burst_end(e);
            end
            logicalIndex = net_Burst.S>=sum(active)*0.2;
            Net_burst_start = net_Burst.T_start(:,logicalIndex);
            Net_burst_size = net_Burst.S(:,logicalIndex);
%             savepath= strcat(savedir1,'net_burst-',num2str(i),'.mat');
%             save(savepath,'Net_burst_start','Net_burst_end','Net_burst_size')
            %网络爆发持续时间
            net_bd(n,jj)=mean(Net_burst_end-Net_burst_start);
            
%             percent_up=[percent_up;length(find(Original(:,1)==1))/length(Original(:,1))];
%             percent_down=[percent_down;length(find(Original(:,1)==2))/length(Original(:,1))];
%             savepath= strcat(savedir1,'original_burst',num2str(i),'.mat');
%             save(savepath,'Original','original')
        end
    end
end