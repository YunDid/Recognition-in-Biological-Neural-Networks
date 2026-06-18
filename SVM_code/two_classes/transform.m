function [sound1,sound2] = transform(evoked_data,num_bin,num_ch)

sizee=size(evoked_data);
rowDist=(1:sizee(1)/num_bin);%分割矩阵，参数：每个train刺激个数
rowDist(:,:)=num_bin;
a=mat2cell(evoked_data,rowDist);
instance=zeros(length(a),num_bin*num_ch);
for j=1:length(a)
    aa=a{j,1};
    aaa=[];
    for l=1:num_bin
        aaa=[aaa,aa(l,:)];%和为一行
    end
    instance(j,:)=aaa;
end
sound1=instance(1:2:end,:);
sound2=instance(2:2:end,:);
end