function [iou_insts,perc_free] = compute_iou_v6(bbox,gt)
% Compute IoU between box and true bounding box

if max(max(gt)) > 999
    fsid = 1000;
else
    fsid = 1;
end
[h,w] = size(gt);
inst_box = seg2proposal(gt);
instance_num = size(inst_box,1);

iou_insts = zeros(instance_num-1,size(bbox,1));
perc_free = zeros(1,size(bbox,1));
area = bbox(:,4) .* bbox(:,3);
bbox(:,4) = bbox(:,4) + bbox(:,2) - 1;
bbox(:,3) = bbox(:,3) + bbox(:,1) - 1;
bbox(:,1:4) = round(bbox(:,1:4));

bbox(bbox(:,1) < 1,1) = 1;
bbox(bbox(:,2) < 1,2) = 1;
bbox(bbox(:,3) > w,3) = w;
bbox(bbox(:,4) > h,4) = h;
[y,~] = find(bbox(:,1:4) == 0);
y = unique(y);
bbox(y,:) = [];

for k = 1:instance_num
    instmap = zeros(size(gt));
    instmap(inst_box(k,2):(inst_box(k,2)+inst_box(k,4)),inst_box(k,1):(inst_box(k,1)+inst_box(k,3))) = 1;
    
    a1 = sum(sum(instmap));
    integral_inst = cumsum(cumsum(instmap, 2), 1);
    integral_inst(2:end+1,:) = integral_inst(:,:);
    integral_inst(:,2:end+1) = integral_inst(:,:);
    integral_inst(0,:) = 0;
    integral_inst(:,0) = 0;
    
    for i = 1:size(bbox,1)
        a3 = integral_inst(bbox(i,4)+1,bbox(i,3)+1,:) + integral_inst(bbox(i,2)-1+1,bbox(i,1)-1+1,:) - ...
               integral_inst(bbox(i,4)+1,bbox(i,1)-1+1,:) - integral_inst(bbox(i,2)-1+1,bbox(i,3)+1,:);
        a2 = area(i);
        iou_insts(k,i) = double(a3) / double(a1 + a2 - a3);
    end
end

freespacemap = zeros(size(gt));
freespacemap(gt >= fsid) = 1;
integral_fs = cumsum(cumsum(freespacemap, 2), 1);
integral_fs(2:end+1,:) = integral_fs(:,:);
integral_fs(:,2:end+1) = integral_fs(:,:);
integral_fs(0,:) = 0;
integral_fs(:,0) = 0;
for i = 1:size(bbox,1)
    a3 = integral_fs(bbox(i,4)+1,bbox(i,3)+1,:) + integral_fs(bbox(i,2)-1+1,bbox(i,1)-1+1,:) - ...
        integral_fs(bbox(i,4)+1,bbox(i,1)-1+1,:) - integral_fs(bbox(i,2)-1+1,bbox(i,3)+1,:);
    a2 = area(i);
    perc_free(1,i) = a3 / a2;
end

end

