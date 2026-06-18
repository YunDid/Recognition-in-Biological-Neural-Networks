clc
clear 
close all
maindir='/Users/mengweiwei/Desktop/te/1213-4/te/';
savedir='/Users/mengweiwei/Desktop/te/1213-4/connection/';
% mkdir /Users/mengweiwei/Desktop/te/1213-4/ connection
subdir=dir(fullfile(maindir,'*.mat'));
fileNames={subdir.name};
for i=1:length(fileNames)
    path=strcat(maindir,fileNames(i));
    data=load(path{1,1});
    TE=data.peak_TE;TE=TE - diag(diag(TE));
    CI=data.C_I;CI=CI-diag(diag(CI));
    TE_jit=data.jitter_TE;
    CI_jit=data.jitter_CI;
    %% 计算jitter100次的均值
    jit_TE=zeros(length(TE_jit),length(TE_jit));jit_CI=jit_TE;
    for k=1:length(TE_jit)
        a=TE_jit{k,1};b=CI_jit{k,1};
        for m=1:length(a(:,1))
            jit_TE(k,m)=mean(a(m,:));jit_CI(k,m)=mean(b(m,:));
        end
    end
%     te=reshape(TE',1,[]);ci=reshape(CI',1,[]);
%     jit_te=reshape(jit_TE',1,[]); jit_ci=reshape(jit_CI',1,[]);
    te=TE(:);ci=CI(:);
    jit_te=jit_TE(:);jit_ci=jit_CI(:);
    te=log10(te);jit_te=log10(jit_te);
%     rt=ceil((length(te)*2)^(1/3));
    bin=20;
    bin1=(max(max(te),max(jit_te))-min(min(te(te > -Inf),min(jit_te(jit_te > -Inf)))))/bin;
    bin2=(max(max(ci),max(jit_ci))-min(min(ci(ci > 0),min(jit_ci(jit_ci > 0)))))/bin;
    max1=max(max(te),max(jit_te));
    min1=min(min(te(te > -Inf),min(jit_te(jit_te > -Inf))));
    max2=max(max(ci),max(jit_ci));
    min2=min(min(ci(ci > 0),min(jit_ci(jit_ci > 0))));
    Bin1=[min1:bin1:(min1+bin1*19),max1+0.0001];
    Bin2=[min2:bin2:(min2+bin2*19),max2+0.0001];
    test=zeros(length(te),1);

    for x=1:bin
        c1=find(te>=Bin1(x) & te<Bin1(x+1));
        c2=find(jit_te>=Bin1(x) & jit_te<Bin1(x+1));
        for y=1:bin   
            d1=find(ci>=Bin2(y) & ci<Bin2(y+1));
            d2=find(jit_ci>=Bin2(y) & jit_ci<Bin2(y+1));
            e1=intersect(c1, d1);e2=intersect(c2, d2);
            if ~isempty(e1) || ~isempty(e2)
                rt=length(e2)/(length(e1)+length(e2));
                if rt<0.37
                    for p=1:length(e1)
                        test(e1(p))=1;
                    end
                else
                end
            else
            end
        end      
    end
    Test= reshape(test, size(TE));
    connect=TE.*Test;
    
    IT=connect-jit_TE;
    IT(IT<0)=0;
    IT2=TE-jit_TE;
    IT2(IT2<0)=0;
    
    entropy_value=data.entropy_value;
%     delay=data.TEdelays;
%     delays=zeros(length(entropy_value),length(entropy_value));
%     times=[];
%     for ii=1:length(entropy_value)
%         for jj=1:length(entropy_value)
%             tt=connect(ii,jj);
%             if ~(tt==0)
%                dd= find(delay(ii,jj,:)==tt);
%                times=[times;ii jj dd];
%                delays(ii,jj)=dd;
%             else
%             end
%         end
%     end
        %%
    %对传递熵进行归一化
    nom_connect=connect;
    g=find(entropy_value>0);
    for q=1:length(g)
        nom_connect(:,g(q))=connect(:,g(q))./entropy_value(g(q),1);%归一化
    end
    %%
    %保存数据
    delet_units=data.delet_units;
    savepath=strcat(savedir,'connect-',fileNames(i));
    save(savepath{1,1},'connect','nom_connect','IT','delet_units','IT2')
    
%     row=['01';'02';'03';'04';'05';'06';'07';'08';'09';'10';...
%         '11';'12';'13';'14';'15';'16';'17';'18';'19';'20';...
%         '21';'22';'23';'24';'25';'26';'27';'28';'29';'30';...
%         '31';'32';'33';'34';'35';'36';'37';'38';'39';'40';...
%         '41';'42';'43';'44';'45';'46';'47';'48';'49';'50';...
%         '51';'52';'53';'54';'55';'56';'57';'58';'59';'60';...
%         '61';'62';'63';'64'];
%     col={'  ','01','02','03','04','05','06','07','08','09','10',...
%         '11','12','13','14','15','16','17','18','19','20',...
%         '21','22','23','24','25','26','27','28','29','30',...
%         '31','32','33','34','35','36','37','38','39','40',...
%         '41','42','43','44','45','46','47','48','49','50',...
%         '51','52','53','54','55','56','57','58','59','60',...
%         '61','62','63','64'};
%     connection=table(row,connect(:,1),connect(:,2),connect(:,3),connect(:,4),connect(:,5),connect(:,6),connect(:,7),connect(:,8),connect(:,9),connect(:,10),connect(:,11),connect(:,12),connect(:,13),connect(:,14),connect(:,15),connect(:,16),connect(:,17),connect(:,18),connect(:,19),connect(:,20),connect(:,21),connect(:,22),connect(:,23),connect(:,24),connect(:,25),connect(:,26),connect(:,27),connect(:,28),connect(:,29),connect(:,30),connect(:,31),connect(:,32),connect(:,33),connect(:,34),connect(:,35),connect(:,36),connect(:,37),connect(:,38),connect(:,39),connect(:,40),connect(:,41),connect(:,42),connect(:,43),connect(:,44),connect(:,45),connect(:,46),connect(:,47),connect(:,48),connect(:,49),connect(:,50),connect(:,51),connect(:,52),connect(:,53),connect(:,54),connect(:,55),connect(:,56),connect(:,57),connect(:,58),connect(:,59),connect(:,60),connect(:,61),connect(:,62),connect(:,63),connect(:,64),'VariableNames',col);
%     fileName=strcat('con-',fileNames(i),'.csv');
%     substr='.mat';
%     fileName=erase(fileName,substr);
%     filepath=fullfile(savedir,fileName{1,1});
%     writetable(connection,filepath)
end