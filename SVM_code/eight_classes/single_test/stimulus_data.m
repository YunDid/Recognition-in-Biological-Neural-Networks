function [sti_data,interval2] = stimulus_data(spike_data,active_ch,t)
Namess=fieldnames(spike_data);
sti_start=extractfield(spike_data,Namess{end,1});
sti_end=extractfield(spike_data,Namess{end-1,1});
interval=[sti_end;sti_end+t]';
interval2=[sti_start(1:6:end);sti_start(1:6:end)+1.5]';
% interval=[sti_end+t;sti_start(2:length(sti_start)),sti_end(length(sti_end))+0.25];
% for m=6:6:length(interval)
%     interval(2,m)=interval(1,m)+0.24;
% end
% evoked_data=zeros(length(sti_start),64);
sti_data=cell(length(active_ch),1);
a=0;
for k=2:2:length(Namess)-2     %Attention
    rowNames=Namess{k,1};
    row = str2double( rowNames(13));
    column = str2double( rowNames(12));
    data=extractfield(spike_data,rowNames);
    num=(column-1)*8+row;
    if ismember(num,active_ch)
        % 初始化逻辑索引数组
        logical_index = false(size(data));
        
        % 对每个区间进行迭代
        for i = 1:size(interval2, 1)
            % 找到落在当前区间内的索引
            within_range = data >= interval2(i, 1) & data <= interval2(i, 2);
            % 将这些索引标记为 true
            logical_index = logical_index | within_range;
        end
        
        % 使用逻辑索引获取落在指定区间内的元素
        stim_data = data(logical_index);
        if ~t==0
            logical_index = false(size(stim_data));
            for i = 1:size(interval, 1)
                % 找到落在当前区间内的索引
                within_range2 = stim_data >= interval(i, 1) & stim_data <= interval(i, 2);
                % 将这些索引标记为 true
                logical_index = logical_index | within_range2;
            end
            sti = stim_data(~logical_index);
        else
            sti=stim_data;
        end
        a=a+1;
        sti_data{a,1}=sti;
%         disp(['进度：',num2str(a),'/32']);
    else
    end
end