%%calculate the appearing frequncy of obstacle

clc; clear; close all; warning('off');
addpath(genpath(pwd));
is_train = true;
is_save_fv = false;
ModelType = 1;

vars = get_params_LAF(is_train);
datalist = get_datalists(vars);

mask = zeros(1024,2048);
n_layers = 4;
bbox_obs = [];
center = [];
area = [];
bottom = [];

for i=1:length(datalist.imgslist)
    len = length(datalist.imgslist{i});
    for j=1:len
        j
        tic;
        gt  = imread([datalist.gtInstlist{i}(j).folder,'/',datalist.gtInstlist{i}(j).name]);
        idx = find(gt > 1000);
        type = unique(gt(gt>1000));
        [h,w] = size(gt);
        class_num = numel(type);
        
        for c = 1:class_num
            [y1,x1] = find(gt == type(c));
            maxX = max(x1);
            maxY = max(y1);
            minX = min(x1);
            minY = min(y1);
            center = [center;mean(y1),mean(x1)];
            bottom = [bottom;h - maxY];
            bbox_obs = [bbox_obs;[minX,minY,maxX-minX+1,maxY-minY+1]];
            area = [area;length(x1)];
        end
        
        toc
    end
end

PseudoDistance_ = [bottom(:,1),area];
PseudoDistance_(:,1) = (PseudoDistance_(:,1)-min(PseudoDistance_(:,1)))/ max(PseudoDistance_(:,1));
PseudoDistance_(:,2) = (PseudoDistance_(:,2)-min(PseudoDistance_(:,2)))/ max(PseudoDistance_(:,2));

[Idx,type,sum_Dist]=kmeans(PseudoDistance_,n_layers);

for i = 1:n_layers
    eval(['bbox_',num2str(i),'=','bbox_obs(Idx == ',num2str(i),',:);']);
end
top = [];
region = [];
for i = 1:n_layers
    j = num2str(i);
    eval(['bbox_',j,'(:,3:4) = bbox_',j,'(:,1:2) + bbox_',j,'(:,3:4) - 1;']);
    eval(['min_',j,'= min(bbox_',j,'(:,1:2));']);
    eval(['max_',j,'= max(bbox_',j,'(:,3:4));']);
    eval(['freq_',j,'= [min_',j,',max_',j,'-min_',j,'];']);
    eval(['freq_obs = [freq_obs;freq_',j,'];']);
end
region(:,3:4) = region(:,3:4) + region(:,1:2) - 1;
region(:,2) = min(region(:,2));
[~,ind] = sort(region(:,1));
region = region(ind,:);
a = region(:,[2,4]);
region(:,[2,4]) = region(:,[1,3]);
region(:,[1,3]) = a;
region = region(end:-1:1,:);
region(:,3:4) = region(:,3:4) - region(:,1:2) + 1;
region(1:2, 2) = region(1:2, 2) + region(1:2, 4)/6;
region(1:2, 1) = region(1:2, 1) - region(1:2, 3)/6;
region(1:2, 4) = region(1:2, 4) - region(1:2, 4)/2;
region(1:2, 3) = region(1:2, 3) + region(1:2, 3)/2;
region(3, 2) = region(3, 2) + region(3, 4)/5;
region(3, 1) = region(3, 1) - region(3, 3)/5;
region(3, 4) = region(3, 4) - region(3, 4)/3;
region(4, 2) = 1;
region(4, 1) = region(4, 1) - region(4, 3)/2.5;
region(4, 4) = region(4, 4) + region(4, 4)/10;
region(4, 3) = region(4, 3) + region(4, 3)/2;

