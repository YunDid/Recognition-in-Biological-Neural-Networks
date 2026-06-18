w=5;
wl=4;
wh=8;
%%
yl = lpfilter(eeg_data, w,si, 4);
plot(yl)
%%
yh = hpfilter(eeg_data, w,si, 4);
plot(yh)
%%
yb = bpfilter(eeg_data, wl, wh, si,4);
plot(yb)