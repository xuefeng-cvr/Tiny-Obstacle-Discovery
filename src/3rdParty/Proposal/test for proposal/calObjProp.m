function [bbs] = calObjProp(E)
% Generate proposals with input fused edge response, which is similar to Edge Boxes.
% Here the Edge Boxes Toolbox from "Edge Boxes: Locating Object Proposals from Edges" 
% in ECCV 2014 is utilized for inference.


% the proposal parameters (details is seen in Edge Boxes)
alpha = 0.65;  kappa=1.2; minScore = 0.01; maxNum =1000; maxRatio=3; minArea=1000; 
O=calO(E); O=single(O); %orientation
bbs=scorebox(E,O,alpha,kappa,minScore,maxNum,maxRatio,minArea); %proposal

end

