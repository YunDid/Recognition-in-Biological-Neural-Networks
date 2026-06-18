function [sound1_ds,sound2_ds,sound1_dt,sound2_dt,sound1_dst,sound2_dst] = transform_st(evoked_data,num_bin,num_ch)

sizee=size(evoked_data);
rowDist=(1:sizee(1)/num_bin);%分割矩阵，参数：每个train刺激个数
rowDist(:,:)=num_bin;
a=mat2cell(evoked_data,rowDist);
instance_ds=zeros(length(a),num_bin);
instance_dt=zeros(length(a),num_ch);
instance_dst=zeros(length(a),1);
for j=1:length(a)
    aa=a{j,1};
    b=mean(aa,2);
    instance_ds(j,:)=b';
    bb=mean(aa,1);
    instance_dt(j,:)=bb;
    bbb=mean(bb);
    instance_dst(j,1)=bbb;
end

sound1_ds=instance_ds(1:2:end,:);
sound2_ds=instance_ds(2:2:end,:);
sound1_dt=instance_dt(1:2:end,:);
sound2_dt=instance_dt(2:2:end,:);
sound1_dst=instance_dst(1:2:end,:);
sound2_dst=instance_dst(2:2:end,:);
end