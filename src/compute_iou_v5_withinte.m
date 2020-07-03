function [iou_insts,perc_free] = compute_iou_v5_withinte(bbox,gt)
% Compute IoU between box and true segmentation

if max(max(gt)) < 999
    th = 1;
else
    th = 1000;
end
C = unique(gt(gt > th));

instance_num = size(C,1);
% [x,y] = find(gt > 1);
iou_insts = zeros(instance_num,size(bbox,1));
perc_free = zeros(1,size(bbox,1));
area = bbox(:,4) .* bbox(:,3);
bbox(:,3:4) = bbox(:,3:4) + bbox(:,1:2) - 1;

for k = 1:instance_num
    instmap = zeros(size(gt));
    instmap(gt == C(k)) = 1;
    
    a1 = sum(sum(instmap));
    integral_inst = cumsum(cumsum(instmap, 2), 1);
    integral_inst(2:end+1,:) = integral_inst(:,:);
    integral_inst(:,2:end+1) = integral_inst(:,:);
    integral_inst(1,:) = 0;
    integral_inst(:,1) = 0;
    
    for i = 1:size(bbox,1)
        a3 =   integral_inst(bbox(i,4)+1,bbox(i,3)+1,:) + ...
               integral_inst(bbox(i,2),bbox(i,1),:) - ...
               integral_inst(bbox(i,4)+1,bbox(i,1),:) - ...
               integral_inst(bbox(i,2),bbox(i,3)+1,:);
        a2 = area(i);
        iou_insts(k,i) = a3 / (a1 + a2 - a3);
    end
end

freespacemap = zeros(size(gt));
freespacemap(gt >= th) = 1;
integral_fs = cumsum(cumsum(freespacemap, 2), 1);
integral_fs(2:end+1,:) = integral_fs(:,:);
integral_fs(:,2:end+1) = integral_fs(:,:);
for i = 1:size(bbox,1)
    a3 = integral_fs(bbox(i,4)+1,bbox(i,3)+1,:) + integral_fs(bbox(i,2)-1+1,bbox(i,1)-1+1,:) - ...
        integral_fs(bbox(i,4)+1,bbox(i,1)-1+1,:) - integral_fs(bbox(i,2)-1+1,bbox(i,3)+1,:);
    a2 = area(i);
    perc_free(1,i) = a3 / a2;
end

end

