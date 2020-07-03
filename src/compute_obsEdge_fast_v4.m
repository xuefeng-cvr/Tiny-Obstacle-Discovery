function [ucms,Es,imgs] = compute_obsEdge_fast_v4( I, model, freq_obs)
%COMPUTE_OBSEDGE Summary of this function goes here
%   Detailed explanation goes here

model.opts.nms=-1; model.opts.nThreads=4;
model.opts.multiscale=0; model.opts.sharpen=2;
opts = spDetect;  %% set up opts
opts.nThreads = 4;  % number of computation threads
opts.k = 1024;     % controls scale of superpixels (big k -> big sp)
opts.alpha = .5;    % relative importance of regularity versus data terms
opts.beta = .9;     % relative importance of edge versus color terms
opts.merge = 0;     % set to small value to merge nearby superpixels at end

nlayer = size(freq_obs,1);
imgs = cell(nlayer,1);
Es = cell(nlayer,1);
O = cell(nlayer,1);
sp = cell(nlayer,1);
segs = cell(nlayer,1);
ucms = cell(nlayer,1);
bb = freq_obs;
bb(:,3:4) = bb(:,1:2)+bb(:,3:4)-1;

tic;
for k = 1:nlayer
    tic;
    imgs{k} = I(bb(k,1):bb(k,3),bb(k,2):bb(k,4),:);
    [Es{k},O{k},~,segs{k}]=edgesDetect(imgs{k},model);
    if k ~= 1
        x1 = bb(k-1,2) - bb(k,2) + 1;
        y1 = bb(k-1,1) - bb(k,1) + 1;
        x2 = bb(k-1,4) - bb(k,2) + 1;
        y2 = bb(k-1,3) - bb(k,1) + 1;
        Es{k}(y1:y2,x1:x2) = Es{k}(y1:y2,x1:x2) + Es{k-1};
    end
end

for k = 1:nlayer
    if k ~= nlayer
        c0 = freq_obs(k,2) - freq_obs(nlayer,2) + 1;
        r0 = freq_obs(k,1) - freq_obs(nlayer,1) + 1;
        c1 = c0 + freq_obs(k,4) - 1;
        r1 = r0 + freq_obs(k,3) - 1;
        Es{k} = Es{nlayer}(r0:r1,c0:c1);
    end
    [sp{k},~] = spDetect(imgs{k},Es{k},opts);
    [~,~,edgeo]=spAffinities(sp{k},Es{k},segs{k},opts.nThreads);
    ucms{k} = single(edgeo);
end
end

