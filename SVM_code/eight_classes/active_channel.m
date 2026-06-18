function [active_ch] = active_channel(spike_data,spike_data2,spike_data3,spike_data4,t,up,down)
Namess=fieldnames(spike_data);
sti_start=extractfield(spike_data,Namess{end,1});
sti_end=extractfield(spike_data,Namess{end-1,1});
interval=[sti_end+t;sti_start(2:length(sti_start)),sti_end(length(sti_end))+0.25];

for m=6:6:length(interval)
    interval(2,m)=interval(1,m)+0.24;
end
evoked_data=zeros(length(sti_start),64);
for k=1:length(Namess)-3    %Attention
    rowNames=Namess{k,1};
    row = str2double( rowNames(21));
    column = str2double( rowNames(20));
    data=extractfield(spike_data,rowNames);
    num=(column-1)*8+row;

    for n=1:length(sti_start)
        time1=interval(1,n);
        time2=interval(2,n);
        number=length(find(data>time1 & data<=time2));
        evoked_data(n,num)=number;
    end

end



Namess2=fieldnames(spike_data2);
sti_start2=extractfield(spike_data2,Namess2{end,1});
sti_end2=extractfield(spike_data2,Namess2{end-1,1});
interval2=[sti_end2+t;sti_start2(2:length(sti_start2)),sti_end2(length(sti_end2))+0.25];
for m=6:6:length(interval2)
    interval2(2,m)=interval2(1,m)+0.24;
end
evoked_data2=zeros(length(sti_start2),64);
for k=1:length(Namess2)-3     %Attention
    rowNames=Namess2{k,1};
    row = str2double( rowNames(21));
    column = str2double( rowNames(20));
    data=extractfield(spike_data2,rowNames);
    num=(column-1)*8+row;
    %         if ~ismember(num,del_channels)
    for n=1:length(sti_start2)
        time1=interval2(1,n);
        time2=interval2(2,n);
        number=length(find(data>time1 & data<=time2));
        evoked_data2(n,num)=number;
    end
    %         else
    %         end
end

Namess3=fieldnames(spike_data3);
sti_start2=extractfield(spike_data3,Namess3{end,1});
sti_end2=extractfield(spike_data3,Namess3{end-1,1});
interval2=[sti_end2+t;sti_start2(2:length(sti_start2)),sti_end2(length(sti_end2))+0.25];
for m=6:6:length(interval2)
    interval2(2,m)=interval2(1,m)+0.24;
end
evoked_data3=zeros(length(sti_start2),64);
for k=1:length(Namess3)-3    %Attention
    rowNames=Namess3{k,1};
    row = str2double( rowNames(21));
    column = str2double( rowNames(20));
    data=extractfield(spike_data3,rowNames);
    num=(column-1)*8+row;
    %         if ~ismember(num,del_channels)
    for n=1:length(sti_start2)
        time1=interval2(1,n);
        time2=interval2(2,n);
        number=length(find(data>time1 & data<=time2));
        evoked_data3(n,num)=number;
    end
    %         else
    %         end
end

Namess4=fieldnames(spike_data4);
sti_start2=extractfield(spike_data4,Namess4{end,1});
sti_end2=extractfield(spike_data4,Namess4{end-1,1});
interval2=[sti_end2+t;sti_start2(2:length(sti_start2)),sti_end2(length(sti_end2))+0.25];
for m=6:6:length(interval2)
    interval2(2,m)=interval2(1,m)+0.24;
end

evoked_data4=zeros(length(sti_start2),64);
for k=1:length(Namess4)-3      %Attention
    rowNames=Namess4{k,1};
    row = str2double( rowNames(21));
    column = str2double( rowNames(20));
    data=extractfield(spike_data4,rowNames);
    num=(column-1)*8+row;
    %         if ~ismember(num,del_channels)
    for n=1:length(sti_start2)
        time1=interval2(1,n);
        time2=interval2(2,n);
        number=length(find(data>time1 & data<=time2));
        evoked_data4(n,num)=number;
    end
    %         else
    %         end
end

b=sum(evoked_data)+sum(evoked_data2)+sum(evoked_data3)+sum(evoked_data4);
b_up=b.*up;b_down=b.*down;

[sorted_values, sorted_indices] = sort(b_up, 'descend');
up_channels = sorted_indices(1:16);
[sorted_values2, sorted_indices2] = sort(b_down, 'descend');
down_channels = sorted_indices2(1:16);
channels=[up_channels,down_channels];
active_ch=sort(channels);
end