function show_AR(recalls,cnts,linewidth,LineStyle,color)

if nargin <= 3
    LineStyle = '-';
end


[ncnts,nious,ninsts] = size(recalls);
AR1_iou = zeros(1,ncnts);
for i = 1:nious
    cnts_AR1_iou = reshape(recalls(:,i,:),[ncnts,ninsts])';
    AR1_iou = AR1_iou + sum(cnts_AR1_iou)/size(cnts_AR1_iou,1);
end
AR1_iou = AR1_iou / nious;
if nargin == 5
    plot(cnts,AR1_iou,'LineWidth',linewidth,'LineStyle',LineStyle,'Color',color);
else
    plot(cnts,AR1_iou,'LineWidth',linewidth,'LineStyle',LineStyle);
end
end

