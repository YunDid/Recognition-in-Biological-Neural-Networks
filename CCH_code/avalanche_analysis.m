function results = avalanche_analysis(electrodeSpikes, savedir, filename)
%% 雪崩分析主函数 
% 计算tau, alpha, DCC, SC error, BR等指标
% 输入: electrodeSpikes - spike数据（要微信我提供给师兄的格式）, savedir - 保存路径（分析完后的结果数据要存在哪儿）, filename - electrodeSpikes来源的文件名
% 输出: results - 包含所有指标的结构体，最终这个会保存在mat里

    %% 数据预处理  剔除了一些数据 应该是留了5min数据
    spikes = electrodeSpikes;
%     for r = 1:length(spikes)
%         spikes{r,1} = round(spikes{r,1}*1000);
%         spikes{r,1}(spikes{r,1}>300000) = [];
%     end
    
    %% 计算ISI和bin大小   ISI 的计算师兄可以用自己的或者那这个也行
    asdf2.raster = spikes;
    asdf2.binsize = 1;
    asdf2.nbins = 300000;
    asdf2.nchannels = length(spikes);
    
    sp = [];
    for p = 1:length(spikes)
        sp = [sp asdf2.raster{p,1}]; 
    end
    sp = sort(sp,'descend');
    isi = sp(1:(length(sp)-1)) - sp(2:length(sp));
    mean_isi = mean(isi);
    bin = ceil(mean_isi);
    
    %% 计算雪崩属性
    newAsdf2 = rebin(asdf2, bin);
    Av = avprops(newAsdf2, 'ratio', 'fingerprint');
    
    %% 1. 提取tau (size distribution)    这里会自动出图并保存
    [tau, xminSZ, xmaxSZ, sigmaSZ, pSZ, pCritSZ, ksDR, DataSZ] = ...
        avpropvals(Av.size, 'size','plot');
    saveas(gcf, fullfile(savedir, ['size-' filename '.jpg']));
    close;
    
    %% 2. 提取alpha (duration distribution)   这里会自动出图并保存
    [alpha, xminDR, xmaxDR, sigmaDR, pDR, pCritDR, ksDR, DataDR] = ...
        avpropvals(Av.duration, 'duration','plot');
    saveas(gcf, fullfile(savedir, ['duration-' filename '.jpg']));
    close;
    
    %% 3. 提取sigmaNuZInvSD (size given duration)     这里会自动出图并保存
    [sigmaNuZInvSD, ~, ~, sigmaSD] = avpropvals({Av.size, Av.duration},...
        'sizgivdur', 'durmin', xminDR{1}, 'durmax', xmaxDR{1},'plot');
    saveas(gcf, fullfile(savedir, ['sizgivdur-' filename '.jpg']));
    close;
    
    %% 4. 计算shape collapse
    avgProfiles = avgshapes(Av.shape, Av.duration, 'cutoffs', 4, 20);
    
    % 绘制temporal profiles
    figure;
    for iProfile = 1:length(avgProfiles)
        hold on;
        plot(1:length(avgProfiles{iProfile}), avgProfiles{iProfile});
    end
    hold off;
    xlabel('Time Bin, t', 'fontsize', 14);
    ylabel('Neurons Active, s(t)', 'fontsize', 14);
    title('Mean Temporal Profiles', 'fontsize', 14);
    saveas(gcf, fullfile(savedir, ['shape-' filename '.jpg']));
    close;
    
    % 计算shape collapse statistics
    [sigmaNuZInvSC, secondDrv, range, errors] = avshapecollapse(avgProfiles, 'plot');
    sigmaSC = avshapecollapsestd(avgProfiles);
    title(['Shape Collapse, 1/(sigma nu z) = ' num2str(sigmaNuZInvSC) ' +/- ' num2str(sigmaSC)]);
    saveas(gcf, fullfile(savedir, ['collapse-' filename '.jpg']));
    close;
    
    %% 5. 计算DCC和SC error
    % 提取数值（处理cell类型）
    if iscell(tau), tau = tau{1}; end
    if iscell(alpha), alpha = alpha{1}; end
    
    beta_fit = sigmaNuZInvSD;
    beta_shape_collapse = sigmaNuZInvSC;
    beta_pred = (alpha - 1) / (tau - 1);
    
    dcc = abs(beta_pred - beta_fit);
    sc_error = abs(beta_shape_collapse - beta_fit);
    
    %% 6. 计算BR值
    [br, slopevals, brsimple] = brestimate(asdf2);
    
    %% 整合所有结果
    results.tau = tau;
    results.alpha = alpha;
    results.sigmaNuZInvSD = sigmaNuZInvSD;
    results.sigmaNuZInvSC = sigmaNuZInvSC;
    results.beta_pred = beta_pred;
    results.dcc = dcc;
    results.sc_error = sc_error;
    results.br = br;
    results.brsimple = brsimple;
    results.bin = bin;
    
    % 保存结果到MAT文件
    save(fullfile(savedir, [filename '_results.mat']), 'results');
    
    % 创建结果表格并保存为CSV
%     resultsTable = struct2table(results);
%     writetable(resultsTable, fullfile(savedir, [filename '_results.csv']));
    
    fprintf('分析完成: %s\n', filename);
end