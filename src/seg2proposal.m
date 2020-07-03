function [instance_box,types] = seg2proposal(gt)
% get the boxes of the instances in the ground truth
if max(max(gt)) > 999
    C = unique(gt(gt > 1000));
    [x,y] = find(gt > 1000);
else
    C = unique(gt(gt > 1));
    [x,y] = find(gt > 1);
end
instance_num = size(C,1);
instance_box = zeros(instance_num,4);
types = zeros(instance_num,1);

for k = 1:instance_num
    maxX = 1;
    maxY = 1;
    minX = size(gt,1);
    minY = size(gt,2);
    for i=1:size(x,1)
        if C(k) == gt(x(i),y(i))
            maxX = max(maxX, x(i));
            minX = min(minX, x(i));
            maxY = max(maxY, y(i));
            minY = min(minY, y(i));
        end
    end
    instance_box(k,:) = [minY, minX, maxY-minY, maxX-minX];
    types(k,:) = C(k);
end
end

