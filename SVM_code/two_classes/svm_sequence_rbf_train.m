function [model,bestcv,bestg,bestc,train_ins] = svm_sequence_rbf_train(train,trainLabel)
%将训练集每个特征缩放到0~1
train_ins=(train - repmat(min(train,[],1),size(train,1),1))*spdiags(1./(max(train,[],1)-min(train,[],1))',0,size(train,2),size(train,2));
nan_indices=isnan(train_ins);
train_ins(nan_indices)=0;
%%
%%rbf计算最优参数c和g
bestcv = 0;
for log2c = -1:3
    for log2g = -4:1
        cmd = [' -v 5 -c ', num2str(2^log2c), ' -g ', num2str(2^log2g)];
        cv = libsvmtrain(trainLabel, train_ins, cmd);
        if (cv >= bestcv)
            bestcv = cv; bestc = 2^log2c; bestg = 2^log2g;
        end
        fprintf('%g %g %g (best c=%g, g=%g, rate=%g)\n', log2c, log2g, cv, bestc, bestg, bestcv);
    end
end
para=['-c ',num2str(bestc),' -g ',num2str(bestg)];
%%
%训练
model = libsvmtrain(trainLabel, train_ins, para);
%     savepath=strcat(savedir,'sequence.mat');
%     save(savepath,'PredictLabel','accuracy')
% save('SVM_linear_results.mat','PredictLabel','accuracy')