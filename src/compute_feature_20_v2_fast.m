function [feat] = compute_feature_20_v2_fast(bbox,img,ucm,im_size,pos,integralhsv)

param.pos = pos;
param.im_size = im_size;
[H,W] = size(ucm);
hsv = rgb2hsv(img);

bbox(:,3:4) = bbox(:,1:2) + bbox(:,3:4) - 1;
bbox(bbox(:,1) < 1,1) = 1;
bbox(bbox(:,2) < 1,2) = 1;
bbox(bbox(:,3) > W,3) = W;
bbox(bbox(:,4) > H,4) = H;
bbox(:,3:4) = bbox(:,3:4) - bbox(:,1:2) + 1;

windows = bbox;
windows(:,1:2) = windows(:,1:2) + windows(:,3:4)./2;

pb_feat = calMaxPb(windows,ucm);
bb_feat = calBBFeat(windows,param);
hsistd_feat = calHsiStdFeat(windows,img);
hsi_feat = calHSVdist(bbox,integralhsv);

feat = [pb_feat bb_feat hsistd_feat hsi_feat];

end

function hsv_dist = calHSVdist(bbox,integralhsv) %bbox [ x y w h ] / the indexes of pixels in integralhsv are plused by 1
w = size(integralhsv,2) - 1;
h = size(integralhsv,1) - 1;
b_bbox = zeros(size(bbox));

f_bbox = bbox;

f_bbox(:,3) = f_bbox(:,1) + f_bbox(:,3) - 1;
f_bbox(:,4) = f_bbox(:,2) + f_bbox(:,4) - 1;

b_bbox(:,1) = bbox(:,1) - bbox(:,3)/2;
b_bbox(:,2) = bbox(:,2) - bbox(:,4)/2;
b_bbox(:,3) = bbox(:,1) + bbox(:,3) + bbox(:,3)/2;
b_bbox(:,4) = bbox(:,2) + bbox(:,4) + bbox(:,4)/2;
b_bbox(b_bbox(:,1)<1,1) = 1;
b_bbox(b_bbox(:,2)<1,2) = 1;
b_bbox(b_bbox(:,3)>w,3) = w;
b_bbox(b_bbox(:,4)>h,4) = h;

b_bbox = int16(b_bbox);
f_bbox = int16(f_bbox);

hsiFeat_back = zeros(size(b_bbox,1),49);
hsiFeat_fore = zeros(size(b_bbox,1),49);

for i = 1:size(b_bbox,1)
    inte = integralhsv(b_bbox(i,4)+1,b_bbox(i,3)+1,:) + ...
        integralhsv(b_bbox(i,2),b_bbox(i,1),:) - ...
        integralhsv(b_bbox(i,4)+1,b_bbox(i,1),:) - ...
        integralhsv(b_bbox(i,2),b_bbox(i,3)+1,:);
    hsiFeat_back(i,:) = reshape(inte,[1 49]);
end

for i = 1:size(f_bbox,1)
    inte = integralhsv(f_bbox(i,4)+1,f_bbox(i,3)+1,:) + ...
        integralhsv(f_bbox(i,2),f_bbox(i,1),:) - ...
        integralhsv(f_bbox(i,4)+1,f_bbox(i,1),:) - ...
        integralhsv(f_bbox(i,2),f_bbox(i,3)+1,:);
    hsiFeat_fore(i,:) = reshape(inte,[1 49]);
end

hsiFeat_fore(:,1) = hsiFeat_fore(:,1) + hsiFeat_fore(:,17); hsiFeat_fore(:,17) = [];
hsiFeat_back(:,1) = hsiFeat_back(:,1) + hsiFeat_back(:,17); hsiFeat_back(:,17) = [];
hsv_dist = zeros(size(b_bbox,1),3);
hsiFeat_back = hsiFeat_back - hsiFeat_fore;

for i = 1:size(b_bbox,1)
    subs_BF_h = pdist2(hsiFeat_back(i,1:16),hsiFeat_fore(i,1:16),'cosine');
    subs_BF_s = pdist2(hsiFeat_back(i,17:32),hsiFeat_fore(i,17:32),'cosine');
    subs_BF_i = pdist2(hsiFeat_back(i,33:48),hsiFeat_fore(i,33:48),'cosine');
    hsv_dist(i,:) = [subs_BF_h,subs_BF_s,subs_BF_i];
end
end

function hsiStd_feat = calHsiStdFeat(windows,img)
HSV = rgb2hsv(img);
windows(:,1:2) = windows(:,1:2) - windows(:,3:4)./2;
hsiStd_feat = hsvStd_fast(windows,HSV);
end

function pb_feat = calMaxPb(windows,ucm)
% bbox(:,3:4) = bbox(:,1:2)+bbox(:,3:4);
pb_feat = zeros(size(windows,1),7);

r = windows(:,1:4); % original window
r(:,1:2) = r(:,1:2) - r(:,3:4) / 2;
r(:,3:4) = r(:,1:2) + r(:,3:4) - 1;
r = uint16(r);
r(r(:,3) > size(ucm,2),3) = size(ucm,2);
r(r(:,4) > size(ucm,1),4) = size(ucm,1);


r_c = windows(:,1:4); % center window
r_c(:,3:4) = r_c(:,3:4) / 2;
r_c(:,1:2) = r_c(:,1:2) - r_c(:,3:4) / 2;
r_c(:,3:4) = r_c(:,1:2) + r_c(:,3:4) - 1;
r_c = uint16(r_c);

% calculate integral map
edge_map = ucm > 0;
[edge_map_inte] = compute_integralMap(edge_map);
[ucm_inte] = compute_integralMap(ucm);

for i = 1:size(windows,1)
    ucmPatch = ucm(r(i,2):r(i,4),r(i,1):r(i,3));
    ucmPatch_no0 = ucmPatch(ucmPatch(:) > 0);
    
    mostpb = mode(ucmPatch_no0(:));
    mostpercent = numel(find(ucmPatch_no0(:) == mostpb)) / length(ucmPatch_no0(:));
    maxpb = max(ucmPatch_no0(:));                     % max edge strength
    
    meanpb = ...
        (ucm_inte(r(i,4)+1,r(i,3)+1) + ...
        ucm_inte(r(i,2),r(i,1)) - ...
        ucm_inte(r(i,4)+1,r(i,1)) - ...
        ucm_inte(r(i,2),r(i,3)+1))/ (windows(i,3)*windows(i,4));
    edgedensity = ...
        (edge_map_inte(r(i,4)+1,r(i,3)+1) + ...
        edge_map_inte(r(i,2),r(i,1)) - ...
        edge_map_inte(r(i,4)+1,r(i,1)) - ...
        edge_map_inte(r(i,2),r(i,3)+1))/ (windows(i,3)*windows(i,4));
    meanpb_c = ...
        (ucm_inte(r_c(i,4)+1,r_c(i,3)+1) + ...
        ucm_inte(r_c(i,2),r_c(i,1)) - ...
        ucm_inte(r_c(i,4)+1,r_c(i,1)) - ...
        ucm_inte(r_c(i,2),r_c(i,3)+1))/ (windows(i,3)*windows(i,4)/4);
    edgedensity_c = ...
        (edge_map_inte(r_c(i,4)+1,r_c(i,3)+1) + ...
        edge_map_inte(r_c(i,2),r_c(i,1)) - ...
        edge_map_inte(r_c(i,4)+1,r_c(i,1)) - ...
        edge_map_inte(r_c(i,2),r_c(i,3)+1))/ (windows(i,3)*windows(i,4)/4);
    
    if isempty(mostpercent) || isnan(mostpercent), mostpercent = 0; end
    if isempty(mostpb) || isnan(mostpb), mostpb = 0; end
    if isempty(maxpb) || isnan(maxpb), maxpb = 0; end
    
    pb_feat(i,:) = [maxpb,mostpb,mostpercent,meanpb_c,edgedensity_c,meanpb,edgedensity];
end

end

function bb_feat = calBBFeat(windows,param)
% pos = param.pos;
im_size = param.im_size;
pos = param.pos;   
bb_feat = zeros(size(windows,1),7);

bb_feat(:,1) = windows(:,3).*windows(:,4) / (im_size(1)*im_size(2));    % normalized pixel area
bb_feat(:,2) = windows(:,3)./windows(:,4);    % aspect ratio
bb_feat(:,3) = windows(:,5);    % Occlusion score
% 
% bb_feat(:,4) = (windows(:,1) + pos(1) - 1)./ im_size(1);% x
% bb_feat(:,5) = (windows(:,2) + pos(2) - 1)./ im_size(2);% y
bb_feat(:,4) = windows(:,1)./ im_size(1);% x
bb_feat(:,5) = windows(:,2)./ im_size(2);% y
bb_feat(:,6) = windows(:,3)./ im_size(1);% w
bb_feat(:,7) = windows(:,4)./ im_size(2);% h
end

function map = get_map(X,Y,v,H,W)
map = zeros(H,W);
for i = 1:size(X,1)
    map(Y(i),X(i)) = v(i);
end
end