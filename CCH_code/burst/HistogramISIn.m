function [n]=HistogramISIn( SpikeTimes, N, Steps )
figure;hold on
map=hsv(length(N));
cnt=0;
for FRnum=N
    cnt=cnt+1;
    ISI_N = SpikeTimes( FRnum:end ) - SpikeTimes( 1:end-(FRnum-1) );
    n=histc( ISI_N*1000, Steps*1000 );
    n=smooth(n,'lowess');
    plot(Steps*1000,n/sum(n),'.-', 'color', map(cnt,:))
end
xlabel 'ISI, T_i - T_{i-(N-1) _{ }} [ms]' 
ylabel 'Probability [%]' 
set(gca,'xscale','log') 
set(gca,'yscale','log')