function [ bbox_f, idx ] = filt_bbox( bboxes, obsSzFilter_model,rect)
% remove the boxes with abnormal size, height and width
area_thresh = 20;

bboxes_conv = bboxes;
bboxes_conv(:,1) = bboxes_conv(:,1) + rect(1) - 1;
bboxes_conv(:,2) = bboxes_conv(:,2) + rect(2) - 1;
bboxes_conv(:,1:2) = bboxes_conv(:,1:2) + bboxes_conv(:,3:4)/2;
area_bboxes = bboxes_conv(:,3).*bboxes_conv(:,4);
idx = [];

regionY = obsSzFilter_model.regionY;
for i = 1:size(regionY,1)
    idx_r = find(...
        bboxes_conv(:,2) > regionY(i,1) ...
        & bboxes_conv(:,2) < regionY(i,2) ...
        ...
        & bboxes_conv(:,4) < obsSzFilter_model.minmaxH(i,2) + area_thresh * i ... % maximum height of bbox
        & bboxes_conv(:,4) > obsSzFilter_model.minmaxH(i,1)- area_thresh * i ... % minimum height of bbox
        & bboxes_conv(:,3) < obsSzFilter_model.minmaxW(i,2) + area_thresh * i ... % maximum width of bbox
        & bboxes_conv(:,3) > obsSzFilter_model.minmaxW(i,1)- area_thresh * i ... % minimum width of bbox
        & area_bboxes < obsSzFilter_model.minmaxSZ(i,2) + area_thresh * i... % minimum width of bbox
        & area_bboxes > obsSzFilter_model.minmaxSZ(i,1) ... % minimum width of bbox
        );
    idx = [idx;idx_r];
    
end
bbox_f = bboxes(idx,:);

end

