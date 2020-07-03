function show_prop_recall(recalls,thresh_idx_iou,cnts,linewidth,LineStyle,color)

if nargin <= 4
    LineStyle = '-';
end

[ncnts,~,ninsts] = size(recalls);
cnts_recalls1 = reshape(recalls(:,thresh_idx_iou,:),[ncnts,ninsts])';
plot1 = sum(cnts_recalls1)/size(cnts_recalls1,1);

if nargin == 6
    plot(cnts,plot1,'LineWidth',linewidth,'LineStyle',LineStyle,'Color',color);
else
    plot(cnts,plot1,'LineWidth',linewidth,'LineStyle',LineStyle);
end
end

