function [active_ch,up_channels,down_channels] = active_channel(spike_data,t,up,down)
Namess=fieldnames(spike_data);
sti_start=extractfield(spike_data,Namess{end-2,1});
sti_end=extractfield(spike_data,Namess{end-3,1});
interval=[sti_end+t;sti_start(2:length(sti_start)),sti_end(length(sti_end))+0.25];
for m=6:6:length(interval)
    interval(2,m)=interval(1,m)+0.24;
end
evoked_data=zeros(length(sti_start),64);
for k=2:2:length(Namess)-4     %Attention
    rowNames=Namess{k,1};
    row = str2double( rowNames(13));
    column = str2double( rowNames(12));
    data=extractfield(spike_data,rowNames);
    num=(column-1)*8+row;
    %         if ~ismember(num,del_channels)
    for n=1:length(sti_start)
        time1=interval(1,n);
        time2=interval(2,n);
        number=length(find(data>time1 & data<=time2));
        evoked_data(n,num)=number;
    end
    %         else
    %         end
end
b=sum(evoked_data);
b_up=b.*up;b_down=b.*down;
[sorted_values, sorted_indices] = sort(b_up, 'descend');
up_channels = sorted_indices(1:16);
[sorted_values2, sorted_indices2] = sort(b_down, 'descend');
down_channels = sorted_indices2(1:16);
channels=[up_channels,down_channels];
active_ch=sort(channels);
end