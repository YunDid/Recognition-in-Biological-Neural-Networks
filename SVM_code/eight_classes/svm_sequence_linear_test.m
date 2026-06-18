function [predict_label, accu,test_ins] = svm_sequence_linear_test(test,train,testLabel,model)
test_ins=(test - repmat(min(train,[],1),size(test,1),1))*spdiags(1./(max(train,[],1)-min(train,[],1))',0,size(test,2),size(test,2));
nan_indices=isnan(test_ins);inf_indices=isinf(test_ins);
test_ins(nan_indices)=0;test_ins(inf_indices)=0;
% test_ins=test;
[predict_label, accu, ~] = libsvmpredict(testLabel, test_ins, model);
end