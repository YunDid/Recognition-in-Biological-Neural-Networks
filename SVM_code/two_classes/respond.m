function [sound1,sound2]=respond(sti_data,interval,p)

a=1.5/p;
b=interval(:,1)';
bin_start=[];
for i=1:a
    bin_start=[bin_start,b];
    b=b+p;    
end
bin_start=sort(bin_start);
bin_end=bin_start+p;
bin=[bin_start;bin_end];
evoked_data=zeros(length(bin_start),length(sti_data));
for j=1:length(sti_data)
    data=sti_data{j,1};
    for n=1:length(bin_start)
        time1=bin(1,n);
        time2=bin(2,n);
        number=length(find(data>time1 & data<=time2));
        evoked_data(n,j)=number;
    end
end

num_bin=a;
num_ch=length(sti_data);
sizee=size(evoked_data);
rowDist=(1:sizee(1)/num_bin);%分割矩阵，参数：每个train刺激个数
rowDist(:,:)=num_bin;
c=mat2cell(evoked_data,rowDist);
sound1=zeros(num_bin,num_ch);
sound2=zeros(num_bin,num_ch);
for k=1:2:length(c)
    aa=c{k,1};
    sound1=sound1+aa;
end
sound1=sound1'/(length(c)/2);
for k=2:2:length(c)
    aa=c{k,1};
    sound2=sound2+aa;
end
sound2=sound2'/(length(c)/2);   
end



