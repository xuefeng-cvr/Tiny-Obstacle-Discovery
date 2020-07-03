function [ucms,Es] = compute_obsEdge_fastest_v5( I, model, freq_obs)
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

r = freq_obs;
r(:,3:4) = r(:,1:2)+r(:,3:4)-1;

maxMag = size(freq_obs,1);
Es = cell(maxMag,1);
ucms = cell(maxMag,1);

c0 = zeros(3,1);
r0 = zeros(3,1);
c1 = zeros(3,1);
r1 = zeros(3,1);
for k = 1:maxMag - 1
    c0(k) = r(k,2) - r(end,2) + 1;
    r0(k) = r(k,1) - r(end,1) + 1;
    c1(k) = r(k,4) - r(end,2) + 1;
    r1(k) = r(k,3) - r(end,1) + 1;
end
img = I(r(end,1) : r(end,3), r(end,2) : r(end,4), :);


[Es{4},O,~,segs] = edgesDetect(img,model);
for k = 1:maxMag - 1
    Es{k} = zeros(size(Es{4}));
    Es{k} = Es{4}(r0(k):r1(k),c0(k):c1(k));
end
for k = 1:maxMag - 1
    Es{4}(r0(k):r1(k),c0(k):c1(k)) = Es{4}(r0(k):r1(k),c0(k):c1(k)) + Es{k};
end
[sp,~] = spDetect(img,Es{4},opts);
[~,~,edgeo]=spAffinities(sp,Es{4},segs,opts.nThreads);

ucms{4} = single(edgeo);
for k = 1:maxMag - 1
    ucms{k} = ucms{4}(r0(k):r1(k),c0(k):c1(k));
    idx = ucms{k}(1:end,1)~=0 & ((ucms{k}(1:end,2)~=0 & [ucms{k}(2:end,1)~=0;0] & [ucms{k}(2:end,2)~=0;0]) | ucms{k}(1:end,2)==0);
    ucms{k}(idx,1) = 0;
    idx = ucms{k}(1,1:end)~=0 & ((ucms{k}(2,1:end)~=0 & [ucms{k}(1,2:end)~=0,0] & [ucms{k}(2,2:end)~=0,0]) | ucms{k}(2,1:end)==0);
    ucms{k}(1,idx) = 0;
    idx = ucms{k}(1:end,end)~=0 & ((ucms{k}(1:end,end-1)~=0 & [ucms{k}(2:end,end)~=0;0] & [ucms{k}(2:end,end-1)~=0;0]) | ucms{k}(1:end,end-1)==0);
    ucms{k}(idx,end) = 0;
    idx = ucms{k}(end,1:end)~=0 & ((ucms{k}(end-1,1:end)~=0 & [ucms{k}(end,2:end)~=0,0] & [ucms{k}(end-1,2:end)~=0,0]) | ucms{k}(end-1,1:end)==0);
    ucms{k}(end,idx) = 0;
end
end

