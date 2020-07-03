function [gtbox,bbox] = calObj(E,gt)
% Generate proposals with input fused edge response, which is similar to Edge Boxes.
% Here the Edge Boxes Toolbox from "Edge Boxes: Locating Object Proposals from Edges" 
% in ECCV 2014 is utilized for inference.
%
%INPUTS
%  E         - input fused edge response corresponding to an image
%  gt         - [mx4] ground truth bounding boxes, [x y w h]
% OUTPUTS
%  bbox   - [nx6] proposal bounding boxes and results, [x y w h score match]
%  gtbox  - [mx5] ground truth bounding boxes and results, [x y w h match]

% the proposal parameters (details is seen in Edge Boxes)
alpha = 0.65;  kappa=1.2; minScore = 0.01; maxNum =1000; maxRatio=3; minArea=1000; 
O=calO(E); O=single(O); %orientation
bbs=scorebox(E,O,alpha,kappa,minScore,maxNum,maxRatio,minArea); %proposal
E=E./max(max(E)); E=single(E); %normalization
O=calO(E); O=single(O); %orientation
bbsNorm=scorebox(E,O,alpha,kappa,minScore,maxNum,maxRatio,minArea); %proposal with norm input
 [gtbox,bbox]=bbGt('evalRes',gt,bbs,bbsNorm,0.7); %evaluate
end

