function [ins,evoked_data]=instance(sti_data,interval,p)

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
[ins] = transform(evoked_data,a,length(sti_data));
end