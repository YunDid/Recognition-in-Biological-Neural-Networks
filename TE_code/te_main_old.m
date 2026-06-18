clc
clear 
close all
addpath('C:\Users\47470\Desktop\D\te_matlab_0\')
maindir='C:\Users\47470\Desktop\te\0901\sttc\';
savedir='C:\Users\47470\Desktop\te\0901\te\';
mkdir C:\Users\47470\Desktop\te\0901\ te
subdir=dir(fullfile(maindir,'*.mat'));
fileNames={subdir.name};
for i=1:length(fileNames)
    path=strcat(maindir,fileNames(i));
    data=load(path{1,1});
    %% spike数据格式转换为asdf，计算每个电极的信息熵
    spikes=data.spikes; %spike数据    
    entropy_value=zeros(length(spikes),1);%每个电极信息熵
    delet_units=ones(length(spikes),1);
    %% 剔除掉5min内放电总个数少于60的神经元
    asdf=cell(length(spikes),1);
    for j=1:length(spikes)
        if length(spikes{j,1})>=60
        asdf{j,1}=spikes{j,1}*1000;
        prob_0=(5*60*1000-length(asdf{j,1}))/(5*60*1000);%5min数据
        prob_1=length(asdf{j,1})/(5*60*1000);
        ent=-prob_0*log2(prob_0)-prob_1*log2(prob_1);%电极的信息熵
        entropy_value(j,1)=ent;
        else
            delet_units(j,1)=0;
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
    savepath=strcat(savedir,'TE-',fileNames(i));
    save(savepath{1,1},'asdf','peak_TE','C_I', 'TEdelays','jitter_TE','jitter_CI','entropy_value','delet_units','del_units')
end

clc
clear 
close all
addpath('C:\Users\47470\Desktop\D\te_matlab_0\')
maindir='C:\Users\47470\Desktop\te\0928-3\sttc\';
savedir='C:\Users\47470\Desktop\te\0928-3\te\';
mkdir C:\Users\47470\Desktop\te\0928-3\ te
subdir=dir(fullfile(maindir,'*.mat'));
fileNames={subdir.name};
for i=1:length(fileNames)
    path=strcat(maindir,fileNames(i));
    data=load(path{1,1});
    %% spike数据格式转换为asdf，计算每个电极的信息熵
    spikes=data.spikes; %spike数据    
    entropy_value=zeros(length(spikes),1);%每个电极信息熵
    delet_units=ones(length(spikes),1);
    %% 剔除掉5min内放电总个数少于60的神经元
    asdf=cell(length(spikes),1);
    for j=1:length(spikes)
        if length(spikes{j,1})>=60
        asdf{j,1}=spikes{j,1}*1000;
        prob_0=(5*60*1000-length(asdf{j,1}))/(5*60*1000);%5min数据
        prob_1=length(asdf{j,1})/(5*60*1000);
        ent=-prob_0*log2(prob_0)-prob_1*log2(prob_1);%电极的信息熵
        entropy_value(j,1)=ent;
        else
            delet_units(j,1)=0;
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
    savepath=strcat(savedir,'TE-',fileNames(i));
    save(savepath{1,1},'asdf','peak_TE','C_I', 'TEdelays','jitter_TE','jitter_CI','entropy_value','delet_units','del_units')
end

