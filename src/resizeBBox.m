function [ bbox_resize ] = resizeBBox( bbox, resizefactor,imsize,ucm,O )
% resize the bounding boxes with resizefactor

bbox_resize = zeros(size(bbox,1),4);
bbox_resize(:,1) = bbox(:,1) + resizefactor(1);
bbox_resize(:,2) = bbox(:,2) + resizefactor(2);
bbox_resize(:,3) = bbox(:,3) + resizefactor(3);
bbox_resize(:,4) = bbox(:,4) + resizefactor(4);

h = imsize(1);
w = imsize(2);

bbox_resize(bbox_resize(:,1) < 1,1) = 1;
bbox_resize(bbox_resize(:,2) < 1,2) = 1;

idx_w_extend = find(bbox_resize(:,3)+bbox_resize(:,1) > w);
bbox_resize(idx_w_extend,3) = w - bbox_resize(idx_w_extend,1);

idx_h_extend = find(bbox_resize(:,4)+bbox_resize(:,2) > h);
bbox_resize(idx_h_extend,4) = h - bbox_resize(idx_h_extend,2);

bbox_reScore = scoreboxesMex(ucm,O,0.65,0.75,0,1e3,0.1,0.5,0.5,6,1000,2,1.5,single(bbox_resize));

bbox_resize = bbox_reScore(:,1:5);
bbox_resize(isnan(bbox_resize)) = 0;

end

