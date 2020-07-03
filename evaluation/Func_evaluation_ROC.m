function Func_evaluation_ROC(topsdir,proppath,savepath,datalist)

top_list = dir([topsdir,'*tops.mat']);
probmaplist = dir([proppath,'*_probmap.mat']);
img_count = size(top_list,1);

threshs = 0:0.005:1;
idx = 1:size(threshs,2);
thr2idx = containers.Map(threshs, idx);

TP = zeros(img_count,length(threshs));
FP = zeros(img_count,length(threshs));
GT_Obstacle = zeros(img_count,length(threshs));
GT_FreeSpace = zeros(img_count,length(threshs));


obs_count = 0;
for i = 1:length(probmaplist)
    tic;
    % load data
    name = probmaplist(i).name;
    sID = str2num(name(1:4));
    iID = str2num(name(6:9));
    gt  = imread([datalist.gtInstlist{sID}(iID).folder,'/',datalist.gtInstlist{sID}(iID).name]); % read ground truth
    gt_freeobs = gt >= 1000;
    gt_free = gt == 1000;
    gt_obs = gt > 1000;
    probmap = load([proppath,name]);
    probmap = probmap.prob_map;
    % set thresholds to segment the obstacles
    for j = 1:length(threshs)
        idx = thr2idx(threshs(j));
        res_obs = probmap > threshs(j);
        TP(i,idx) = sum((res_obs(:) + gt_obs(:)) == 2);
        FP(i,idx) = sum((res_obs(:) + gt_free(:)) == 2);
        GT_Obstacle(i,idx) = sum(gt_obs(:) == 1);
        GT_FreeSpace(i,idx) = sum(gt_free(:) == 1);
    end
    t = toc;
    disp([num2str(i),':',num2str(t)]);
end

TPR = sum(TP,1) ./ sum(GT_Obstacle,1);
FPR = sum(FP,1) ./ sum(GT_FreeSpace,1);
parsave(savepath,TPR,'TPR',FPR,'FPR');
end


function [map_obs_gt] = cal_overlapmap(seg_obs_bw,gt)
X = unique(seg_obs_bw(seg_obs_bw > 0));
Y = unique(gt(gt > 1));
map_obs_gt = zeros(size(Y,1),size(X,1));
for i = 1:size(Y,1)
    y = Y(i);
    y_bw = (gt == y);
    for j = 1:size(X,1)
        x = X(j);
        x_bw = (seg_obs_bw == x);
        TP = sum((y_bw + x_bw) == 2);
        ALL = sum((y_bw + x_bw) > 0);
        map_obs_gt(i,j) = TP / ALL;
    end
end
end