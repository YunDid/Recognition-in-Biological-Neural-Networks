clc;
clear;
close all
maindir='C:\Users\47470\Desktop\data_analysis\replay\hippocampus1\10-23\spon\';
maindirr='C:\Users\47470\Desktop\data_analysis\replay\hippocampus1\10-23\spon\Burst\';
A=load('C:\Users\47470\Desktop\data_analysis\replay\replay_analysis\map_color.mat');
map_color=A.map;
map=map_color/255;
subdir=dir(fullfile(maindir,'*.mat'));
fileNames={subdir.name};
%  for m=1:length(fileNames)
    path=strcat(maindir,fileNames(3));
    data=load(path{1,1});
    spike_timestamps=data.spike_timestamps;
    SpikeTimes=[];
    for i=1:8
        for j=1:8
            a=spike_timestamps{i,j} ;
            SpikeTimes=cat(1,SpikeTimes,a);
            spike_times=sort(SpikeTimes);
        end
     end
    N = (46:55);
    Steps = 10.^(-5:.05:1.5);
    HistogramISIn(spike_times,N,Steps,map)
    NN=50;
    isi_nn=0.089;
    [Burst, SpikeBurstNumber] = BurstDetectISIn( spike_times, NN, isi_nn);
    savepath1=strcat(maindirr,'Burst_',fileNames(3),'.mat');
    save (savepath1{1,1},'Burst')
    savepath2=strcat(maindirr,'Burst_',fileNames(3),'.jpg');
    print(gcf,savepath2{1,1},'-r600','-djpeg')
    close
%  end  
    function HistogramISIn( SpikeTimes, N, Steps ,map)
    % HistogramISIn( SpikeTimes, N, Steps )
    % 'SpikeTimes' [sec] % Vector of spike times.
    % 'N' % Vector of values for plotting ISI_N histograms.
    % 'Steps' [sec] % Vector of histogram edges.
    %
    % Steps should be of uniform width on a log scale. Note that histograms
    % are smoothed using smooth.m with the default span and lowess method.
    %
    %
    % Example code:
    % SpikeTimes = ---- ; % Load spike times here.
    % N = [2:10]; % Range of N for ISI_N histograms.
    % Steps = 10.^[-5:.05:1.5]; % Create uniform steps for log plot.
    % HistogramISIn(SpikeTimes,N,Steps) % Run function
    %
    figure; hold on
    
    cnt = 0;
    for FRnum = N
        cnt = cnt + 1;
        ISI_N= SpikeTimes( FRnum:end ) - SpikeTimes( 1:end-(FRnum-1) );
        n = histc( ISI_N*1000, Steps*1000 );
        n = smooth( n, 'lowess' );
        plot( Steps*1000, n/sum(n), '.-', 'color', map(cnt,:) )
    end
    xlabel 'ISI, T_i - T_{i-(N-1) _{ }} [ms]'
    ylabel 'Probability [%]'
    set(gca,'xscale','log')
    set(gca,'yscale','log')
    legend('46','47','48','49','50','51','52','53','54','55','location','SouthEast','FontSize',4)
    end

    
    function [Burst, SpikeBurstNumber] = BurstDetectISIn( Spike, N, ISI_N )
    % [Burst SpikeBurstNumber] = burstDetectISIn( Spike, N, ISI_N)
    %
    % 'Spike' is a structure with members:
    % Spike Vector of spike times [sec]
    % Spike.C (optional) Vector of spike channels
    %
    % 'N' spikes within 'ISI_N' [seconds] satisfies the burst criteria.
    %
    %
    % Returns Burst information and the Burst Number for each spike time:
    %
    % Burst.T_start Burst start time [sec]
    % Burst.T_end Burst end time [sec]
    % Burst.S Burst size (number of spikes)
    % Burst.C Burst size (number of channels)
    %
    % SpikeBurstNumber Burst number for each Spike;
    % '-1' if a spike is not in a burst.
    %
    %
    % Example code:
    %
    % Spike = ---- ; % Load spike times here.
    % Spike.C = ---- ; % Load spike channels here.
    % N = 10; % Set N
    % ISI_N = 0.10; % Set ISI_N threshold [sec]
    % % Run the detector
    % [Burst Spike.N] = BurstDetectISIn( Spike, N, ISI_N );
    %
    % % Plot results
    % figure, hold on
    %
    % % Order y-axis channels by firing rates
    % tmp = zeros( 1, max(Spike.C)-min(Spike.C) );
    % for c = min(Spike.C):max(Spike.C)
    % tmp(c-min(Spike.C)+1) = length( find(Spike.C==c) );
    % end
    % [tmp ID] = sort(tmp);
    % OrderedChannels = zeros( 1, max(Spike.C)-min(Spike.C) );
    % for c = min(Spike.C):max(Spike.C)
    % OrderedChannels(c-min(Spike.C)+1) = find( ID==c-min(Spike.C)+1 );
    % end
    % % Raster plot
    % plot( Spike, OrderedChannels(1+Spike.C), 'k.' )
    % % set( gca, 'ytick', (min(Spike.C):max(Spike.C))+1, 'yticklabel', ...
    % % ID-min(ID)+min(Spike.C) ) % set yaxis to channel ID
    %
    % % Plot times when bursts were detected
    % ID = find(Burst.T_end<max(Spike));
    % Detected = [];
    % for i=ID
    % Detected = [ Detected Burst.T_start(i) Burst.T_end(i) NaN ];
    % end
    % plot( Detected, 128*ones(size(Detected)), 'r', 'linewidth', 4 )
    %
    % xlabel 'Time [sec]'
    % ylabel 'Channel'
    %
    fprintf('Beginning burst detection.\n');
    % %% Find when the ISI_N burst condition is met
    % Look both directions from each spike
    dT = zeros(N,length(Spike))+inf;
    for j = 0:N-1
        dT(j+1,N:length(Spike)-(N-1)) = Spike( (N:end-(N-1))+j ) - ...
            Spike( (1:end-(N-1)*2)+j );
    end
    Criteria = zeros(size(Spike)); % Initialize to zero
    Criteria( min(dT)<=ISI_N ) = 1; % Spike passes condition if it is
    % included in a set of N spikes
    % with ISI_N <= threshold.
    % %% Assign burst numbers to each spike
    SpikeBurstNumber = zeros(size(Spike)) - 1; % Initialize to '-1'
    INBURST = 0; % In a burst (1) or not (0)
    NUM_ = 0; % Burst Number iterator
    NUMBER = -1; % Burst Number assigned
    BL = 0; % Burst Length
    for i = N:length(Spike)
        if INBURST == 0 % Was not in burst.
            if Criteria(i) % Criteria met, now in new burst.
                INBURST = 1; % Update.
                NUM_ = NUM_ + 1;
                NUMBER = NUM_;
                BL = 1;
            else %Still not in burst, continue
                % continue %
            end
        else % Was in burst.
            if ~ Criteria(i) % Criteria no longer met.
                INBURST = 0; % Update.
                if BL<N % Erase if not big enough.
                    SpikeBurstNumber(SpikeBurstNumber==NUMBER) = -1;
                    NUM_ = NUM_ - 1;
                end
                NUMBER = -1;
            elseif diff(Spike([i-(N-1) i])) > ISI_N && BL >= N
                % This conditional statement is necessary to split apart
                % consecutive bursts that are not interspersed by a tonic spike
                % (i.e. Criteria == 0). Occasionally in this case, the second
                % burst has fewer than 'N' spikes and is therefore deleted in
                % the above conditional statement (i.e. 'if BL<N').
                %
                % Skip this if at the start of a new burst (i.e. 'BL>=N'
                % requirement).
                %
                NUM_ = NUM_ + 1; % New burst, update number.
                NUMBER = NUM_;
                BL = 1; % Reset burst length.
            else % Criteria still met.
                BL = BL + 1; % Update burst length.
            end
        end
        SpikeBurstNumber(i) = NUMBER; % Assign a burst number to
        % each spike.
    end
    % %% Assign Burst information
    fprintf('Assigning Burst information.\n');
    MaxBurstNumber = max(SpikeBurstNumber);
    Burst.T_start = zeros(1,MaxBurstNumber); % Burst start time [sec]
    Burst.T_end = zeros(1,MaxBurstNumber); % Burst end time [sec]
    Burst.S = zeros(1,MaxBurstNumber); % Size (total spikes)
    Burst.C = zeros(1,MaxBurstNumber); % Size (total channels)
    for i = 1:MaxBurstNumber
        ID = find( SpikeBurstNumber==i );
        Burst.T_start(i) = Spike(ID(1));
        Burst.T_end(i) = Spike(ID(end));
        Burst.S(i) = length(ID);
        if isfield( Spike, 'C' )
            Burst.C(i) = length( unique(Spike.C(ID)) );
        end
    end
    fprintf('Finished burst detection using %0.2f minutes of spike data.\n', ...
        diff(Spike([1 end]))/60);
    end