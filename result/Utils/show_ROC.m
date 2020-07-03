function show_ROC(roc,linewidth,isSmooth,LineStyle,color)
%COMPUTE_IOU_RECALL �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��

if nargin <= 1
    LineStyle = '-';
end

tpr = roc.TPR;
fpr = roc.FPR;
tpr = tpr;

if isSmooth
    values = spcrv([...
        [fpr(1) fpr fpr(end)];...
        [tpr(1) tpr tpr(end)]],100);
    fpr = values(1,:); tpr = values(2,:);
end

if nargin == 5
    plot(fpr(1:end),tpr(1:end),'-','LineWidth',linewidth,'LineStyle',LineStyle,'Color',color);
else
    plot(fpr(1:end),tpr(1:end),'-','LineWidth',linewidth,'LineStyle',LineStyle);
end
end