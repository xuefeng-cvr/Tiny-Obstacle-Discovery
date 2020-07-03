function [edgMap,S] = calEdge(I,model)
% Obtain the initial edge map with the Structured Edge Detection Toolbox
% from "Fast Edge Detection Using Structured Forests" in PAMI 2015
model.opts.nms=-1; model.opts.nThreads=4;
model.opts.multiscale=0; model.opts.sharpen=2;
opts = spDetect;  %% set up opts
opts.nThreads = 4;  % number of computation threads
opts.k = 1024;     % controls scale of superpixels (big k -> big sp)
opts.alpha = .5;    % relative importance of regularity versus data terms
opts.beta = .9;     % relative importance of edge versus color terms
opts.merge = 0;     % set to small value to merge nearby superpixels at end
[E,~,~,segs]=edgesDetect(I,model);
[S,~] = spDetect(I,E,opts); 
[~,~,edgMap]=spAffinities(S,E,segs,opts.nThreads); 
end