function [prob_map] = get_probmap(bbox,imsize)

% bounding boxes NMS
top_nms = bbsnms(bbox(:,[1 2 3 4 6]),0.7,1000);
prob_map = zeros(imsize(1),imsize(2));

% accumulate proposal with the predicted IoU
for i = 1:size(top_nms,1) * 0.5
    w = top_nms(i,:);
    weight = top_nms(i,5);
    prob_map(w(2):w(2)+w(4)-1,w(1):w(1)+w(3)-1) = prob_map(w(2):w(2)+w(4)-1,w(1):w(1)+w(3)-1) + weight * ones(w(4),w(3));
end

% normalization
prob_map = prob_map ./ max(prob_map(:));
end

