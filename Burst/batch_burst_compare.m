%% batch_burst_compare.m
% 批量计算单脑区(single) vs 多脑区(modular) 自放电爆发指标，导出对比 Excel。
%
% 用途：MATLAB 中 run 本脚本即可。数据根在 CFG.root。
% 输入：
%   CFG.root\single\D{5,10,15,20}_Spon_*\C*\(mat\)*.mat   单脑区原始 NEX 导出 mat (每段5min)
%   CFG.root\merge\cell{1,2,3}\day{5,10,15}\mat\*.mat      多脑区原始 NEX 导出 mat (10min,自动拆2段)
%   CFG.root\merge\cell{1,2,3}\day20\spikes_*.mat          多脑区 day20 已转换 spike(变量 spikes,64x1 cell,5min)
%   同一 盘×DIV 多段各算一条，不合并；10min 录制(末spike>450s)自动按 0-300/300-600s 拆成两段 5min。
% 处理：1)整理+转换(自动识别已转换/待转换；待转换按 _ID_ 前两位数字正则提取 (列,行)=>(列-1)*8+行)
%       2)忠实复刻 main_burst2 口径算 MBR/MNBR/SIB/NBD/MFR(单通道 NN=2/ISI=0.1 后留 S>=5；网络爆发涉及>=20%
%         active；active=单通道爆发>=20)，每段按 5min 归一化，含除零保护
%       3)导出三表 Excel：单脑区(逐条)、多脑区(逐条)、单vs多对比(DIV×指标,均值±SD,n,p)
% 输出：CFG.clean_root 整理后 spike 树；CFG.out_xlsx 三表；CFG.out_mat 备份
% 依赖：Code\Burst\burst\BurstDetectISIn.m
clc; clear; close all;

%% ===== 配置区 =====
CFG.root        = 'E:\Recognition-in-Biological-Neural-Networks\Data\Spon\NEX_mat';
CFG.burst_path  = 'E:\Recognition-in-Biological-Neural-Networks\Code\Burst\burst';
CFG.clean_root  = 'E:\Recognition-in-Biological-Neural-Networks\Data\Spon\spike_ready';
CFG.out_xlsx    = 'E:\Recognition-in-Biological-Neural-Networks\Data\Spon\burst_metrics.xlsx';
CFG.out_mat     = 'E:\Recognition-in-Biological-Neural-Networks\Data\Spon\burst_metrics.mat';
CFG.split_sec   = 300;   % 拆分窗口(秒)
CFG.split_thr   = 450;   % 末spike>此值视为10min录制并拆分
CFG.write_clean = true;
CFG.swap_modular_5_10 = true;   % 多脑区 day5/day10 录制标注互换,校正回真实 DIV(day5活动反常高=实为day10)
addpath(CFG.burst_path);
if CFG.write_clean && exist(CFG.clean_root,'dir'), rmdir(CFG.clean_root,'s'); end  % 清旧整理树,避免残留错标文件

%% ===== 1) 发现所有录制 =====
recs = struct('group',{},'dish',{},'div',{},'src',{});
mroot = fullfile(CFG.root,'merge');
dd = dir(fullfile(mroot,'cell*'));
for i=1:numel(dd)
    if ~dd(i).isdir, continue; end
    days = dir(fullfile(mroot,dd(i).name,'day*'));
    for j=1:numel(days)
        if ~days(j).isdir, continue; end
        div = str2double(regexp(days(j).name,'\d+','match','once'));
        if CFG.swap_modular_5_10, if div==5, div=10; elseif div==10, div=5; end, end
        mats = findMats(fullfile(mroot,dd(i).name,days(j).name));
        for r=1:numel(mats), recs(end+1)=struct('group','modular','dish',dd(i).name,'div',div,'src',mats{r}); end %#ok<SAGROW>
    end
end
sroot = fullfile(CFG.root,'single');
days = dir(fullfile(sroot,'D*_Spon*'));
for j=1:numel(days)
    if ~days(j).isdir, continue; end
    tk = regexp(days(j).name,'^D(\d+)','tokens','once'); div = str2double(tk{1});
    dishes = dir(fullfile(sroot,days(j).name,'C*'));
    for i=1:numel(dishes)
        if ~dishes(i).isdir, continue; end
        mats = findMats(fullfile(sroot,days(j).name,dishes(i).name));
        for r=1:numel(mats), recs(end+1)=struct('group','single','dish',dishes(i).name,'div',div,'src',mats{r}); end %#ok<SAGROW>
    end
end
fprintf('files: %d (modular %d, single %d)\n', numel(recs), ...
    sum(strcmp({recs.group},'modular')), sum(strcmp({recs.group},'single')));

%% ===== 2) 逐段(拆分后) 转换 + 算指标 =====
[G,Dish,SRC,ERR,NOTE] = deal({});
[D,Rep,DURM,MBR,MNBR,SIB,NBD,MFR,NACT,LAST] = deal([]);
repMap = containers.Map('KeyType','char','ValueType','double');
for k=1:numel(recs)
    rc = recs(k);
    try
        sp0 = loadOrConvert(rc.src);
        last0 = lastSpike(sp0);
        if last0 > CFG.split_thr
            segs = {windowSpikes(sp0,0,CFG.split_sec), windowSpikes(sp0,CFG.split_sec,2*CFG.split_sec)};
            snote = {'10min拆分1/2','10min拆分2/2'};
        else
            segs = {sp0}; snote = {''};
        end
        for si=1:numel(segs)
            spikes = segs{si};
            key = sprintf('%s|%s|%d', rc.group, rc.dish, rc.div);
            if isKey(repMap,key), repMap(key)=repMap(key)+1; else, repMap(key)=1; end
            rep = repMap(key);
            if CFG.write_clean
                od = fullfile(CFG.clean_root, rc.group, rc.dish, sprintf('day%d',rc.div));
                if ~exist(od,'dir'), mkdir(od); end
                save(fullfile(od, sprintf('rec%02d_spikes.mat',rep)), 'spikes');
            end
            M = computeMetrics(spikes, 5);
            G{end+1}=rc.group; Dish{end+1}=rc.dish; D(end+1)=rc.div; Rep(end+1)=rep; DURM(end+1)=5; %#ok<SAGROW>
            MBR(end+1)=M.MBR; MNBR(end+1)=M.MNBR; SIB(end+1)=M.SIB; NBD(end+1)=M.NBD; MFR(end+1)=M.MFR; %#ok<SAGROW>
            NACT(end+1)=M.nActive; LAST(end+1)=lastSpike(spikes); SRC{end+1}=rc.src; ERR{end+1}=''; NOTE{end+1}=snote{si}; %#ok<SAGROW>
            fprintf('%-8s %-6s day%-2d rep%d | MBR=%.2f MNBR=%.2f SIB=%.1f NBD=%.3f act=%d %s\n',...
                rc.group,rc.dish,rc.div,rep,M.MBR,M.MNBR,M.SIB,M.NBD,M.nActive,snote{si});
        end
    catch e
        G{end+1}=rc.group; Dish{end+1}=rc.dish; D(end+1)=rc.div; Rep(end+1)=0; DURM(end+1)=NaN; %#ok<SAGROW>
        MBR(end+1)=NaN; MNBR(end+1)=NaN; SIB(end+1)=NaN; NBD(end+1)=NaN; MFR(end+1)=NaN; %#ok<SAGROW>
        NACT(end+1)=NaN; LAST(end+1)=NaN; SRC{end+1}=rc.src; ERR{end+1}=e.message; NOTE{end+1}=''; %#ok<SAGROW>
        fprintf('%-8s %-6s day%-2d | ERR: %s\n', rc.group,rc.dish,rc.div,e.message);
    end
end
N = numel(G);

% 重复段标记(不剔除,仅备注)：同 group+dish+div 内四指标四舍五入相同
sig = arrayfun(@(i) sprintf('%s|%s|%d|%.3f|%.3f|%.3f|%.4f', G{i},Dish{i},D(i),MBR(i),MNBR(i),SIB(i),NBD(i)), 1:N, 'uni',0);
[~,~,ic] = unique(sig,'stable');
for g=1:max(ic)
    mem = find(ic==g);
    if numel(mem)>1 && ~any(isnan(MBR(mem)))
        for t=2:numel(mem), NOTE{mem(t)} = strtrim([NOTE{mem(t)} ' 疑似重复']); end
    end
end

%% ===== 3) 导出 Excel =====
hdr = {'组别','盘','DIV(天)','重复','记录时长(min)','MBR 平均爆发率(bursts/min)','MNBR 网络同步爆发率(NB/min)', ...
       'SIB 爆发内spike占比(%)','NBD 网络爆发时长(s)','MFR 平均放电率(spikes/min)','活跃电极数','记录末spike时间(s)','备注','源文件','错误'};
shS = buildRows(hdr,strcmp(G,'single'), G,Dish,D,Rep,DURM,MBR,MNBR,SIB,NBD,MFR,NACT,LAST,NOTE,SRC,ERR);
shM = buildRows(hdr,strcmp(G,'modular'),G,Dish,D,Rep,DURM,MBR,MNBR,SIB,NBD,MFR,NACT,LAST,NOTE,SRC,ERR);
cmp = buildCompare(D,strcmp(G,'single'),strcmp(G,'modular'),MBR,MNBR,SIB,NBD);
if exist(CFG.out_xlsx,'file'), delete(CFG.out_xlsx); end
writecell(shS, CFG.out_xlsx, 'Sheet','单脑区');
writecell(shM, CFG.out_xlsx, 'Sheet','多脑区');
writecell(cmp, CFG.out_xlsx, 'Sheet','单vs多对比');
save(CFG.out_mat,'G','Dish','D','Rep','DURM','MBR','MNBR','SIB','NBD','MFR','NACT','LAST','NOTE','SRC','ERR','CFG');
fprintf('\nDONE. xlsx: %s\n', CFG.out_xlsx);

%% ===== 本地函数 =====
function L = lastSpike(sp)
    L = 0; for c=1:numel(sp), if ~isempty(sp{c}), L=max(L,max(sp{c})); end; end
end

function out = windowSpikes(sp, t0, t1)
    out = cell(numel(sp),1);
    for j=1:numel(sp)
        s = sp{j};
        if ~isempty(s), m = s>=t0 & s<t1; out{j} = s(m) - t0; end
    end
end

function m = findMats(folder)
    a = dir(fullfile(folder,'*.mat')); b = dir(fullfile(folder,'mat','*.mat'));
    f = [a; b]; m = {};
    for i=1:numel(f), m{end+1} = fullfile(f(i).folder, f(i).name); end %#ok<AGROW>
    m = sort(m);
end

function spikes = loadOrConvert(p)
    w = whos('-file', p); cv = w(strcmp({w.class},'cell'));
    if ~isempty(cv), S = load(p, cv(1).name); spikes = S.(cv(1).name);
    else, S = load(p); spikes = nex2spikes(S); end
    spikes = spikes(:); if numel(spikes) < 64, spikes{64} = []; end
end

function spikes = nex2spikes(S)
    fn = fieldnames(S); spikes = cell(64,1);
    for i=1:numel(fn)
        nm = fn{i};
        if contains(nm,'Ref') || strcmpi(nm,'StartStop'), continue; end
        tok = regexp(nm,'_(\d)(\d)_ID_','tokens','once');
        if isempty(tok), continue; end
        col = str2double(tok{1}); row = str2double(tok{2}); idx = (col-1)*8 + row;
        if idx>=1 && idx<=64, v = S.(nm); spikes{idx} = v(:)'; end
    end
end

function M = computeMetrics(spikes, durMin)
    nch = numel(spikes); active = zeros(nch,1); bs = cell(nch,1); be = cell(nch,1);
    tot_b=0; ch_BD=[]; tot_sp=0; tot_sib=0;
    for j=1:nch
        s = spikes{j};
        if ~isempty(s)
            s = s(:).';
            txt = evalc('[Burst, SBN] = BurstDetectISIn(s, 2, 0.1);'); %#ok<NASGU>
            d = find(Burst.S>=5);
            Burst.S=Burst.S(d); Burst.T_end=Burst.T_end(d); Burst.T_start=Burst.T_start(d);
            ch_BD=[ch_BD Burst.T_end-Burst.T_start]; %#ok<AGROW>
            tot_b=tot_b+numel(Burst.T_start); tot_sp=tot_sp+numel(SBN); tot_sib=tot_sib+sum(Burst.S);
            if numel(Burst.T_start)>=20, active(j)=1; bs{j}=Burst.T_start; be{j}=Burst.T_end; end
        end
    end
    nA = sum(active); M = struct('MBR',NaN,'MNBR',NaN,'SIB',NaN,'NBD',NaN,'MFR',NaN,'nActive',nA);
    if nA==0, return; end
    M.MBR = tot_b/nA/durMin;
    if tot_sp>0, M.SIB = tot_sib/tot_sp*100; end
    M.MFR = tot_sp/durMin/nA;
    burst_s=[]; ch=[]; burst_e=[];
    for k=1:nch, burst_s=[burst_s bs{k}]; burst_e=[burst_e be{k}]; ch=[ch k*ones(1,numel(bs{k}))]; end %#ok<AGROW>
    if isempty(burst_s), M.MNBR=0; return; end
    [b1, so] = sort(burst_s); b2=burst_e(so);
    txt = evalc('[net_Burst, net_SBN] = BurstDetectISIn(b1, 2, 0.1);'); %#ok<NASGU>
    a = find(net_Burst.S>=nA*0.2); M.MNBR = numel(a)/durMin;
    if isempty(a), return; end
    keep = net_SBN~=-1; nbe=b2(keep); nbn=net_SBN(keep);
    c = find(net_Burst.S<nA*0.2);
    for x=1:numel(c), bb = nbn~=c(x); nbe=nbe(bb); nbn=nbn(bb); end
    Net_end=zeros(1,numel(a)); e=0;
    for y=1:numel(a), e=e+numel(find(nbn==a(y))); if e>=1 && e<=numel(nbe), Net_end(y)=nbe(e); end, end
    Net_start = net_Burst.T_start(net_Burst.S>=nA*0.2);
    L = min(numel(Net_start), numel(Net_end));
    if L>=1, M.NBD = mean(Net_end(1:L)-Net_start(1:L)); end
end

function sh = buildRows(hdr,mask,G,Dish,D,Rep,DURM,MBR,MNBR,SIB,NBD,MFR,NACT,LAST,NOTE,SRC,ERR)
    idx = find(mask); keys = cell(1,numel(idx));
    for t=1:numel(idx), keys{t} = sprintf('%03d_%s_%02d', D(idx(t)), Dish{idx(t)}, Rep(idx(t))); end
    [~,o] = sort(keys); idx = idx(o); sh = hdr;
    for t=1:numel(idx)
        i=idx(t);
        sh(end+1,:) = {G{i},Dish{i},D(i),Rep(i),DURM(i),MBR(i),MNBR(i),SIB(i),NBD(i),MFR(i),NACT(i),LAST(i),NOTE{i},SRC{i},ERR{i}}; %#ok<AGROW>
    end
end

function cmp = buildCompare(D,isS,isM,MBR,MNBR,SIB,NBD)
    metrics = {'MBR 平均爆发率(bursts/min)',MBR; 'MNBR 网络同步爆发率(NB/min)',MNBR; ...
               'SIB 爆发内spike占比(%)',SIB; 'NBD 网络爆发时长(s)',NBD};
    cmp = {'DIV(天)','指标','单脑区 n','单脑区 均值','单脑区 标准差','多脑区 n','多脑区 均值','多脑区 标准差','p值','检验方法'};
    divs = sort(unique(D));
    for di=1:numel(divs)
        dv = divs(di);
        for mi=1:size(metrics,1)
            v = metrics{mi,2};
            xs = v(isS & D==dv); xs = xs(~isnan(xs));
            xm = v(isM & D==dv); xm = xm(~isnan(xm));
            [p,method] = cmpTest(xs,xm);
            cmp(end+1,:) = {dv, metrics{mi,1}, numel(xs), mnan(xs,@mean), mnan(xs,@std), ...
                            numel(xm), mnan(xm,@mean), mnan(xm,@std), p, method}; %#ok<AGROW>
        end
    end
end

function y = mnan(x,f), if isempty(x), y=NaN; else, y=f(x); end, end

function [p,method] = cmpTest(x,y)
    x=x(:); y=y(:);
    if numel(x)<2 || numel(y)<2, p=NaN; method='n<2'; return; end
    try
        p = ranksum(x,y); method='Mann-Whitney(ranksum)';
    catch
        mx=mean(x); my=mean(y); vx=var(x); vy=var(y); nx=numel(x); ny=numel(y);
        se=sqrt(vx/nx+vy/ny);
        if se==0, p=NaN; method='Welch t(SE=0)'; return; end
        t=(mx-my)/se; df=(vx/nx+vy/ny)^2 / ((vx/nx)^2/(nx-1)+(vy/ny)^2/(ny-1));
        p = betainc(df/(df+t^2), df/2, 0.5); method='Welch t';
    end
end
