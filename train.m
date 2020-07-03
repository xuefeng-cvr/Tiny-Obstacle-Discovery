clc; clear; close all; warning('off');
addpath(genpath(pwd));
is_train = true;
exp_dir = '/data/Experiment';
exp_name = '2020_07_03';
vars = get_params_LAF(is_train, 0, exp_name, exp_dir, 0);
datalist = get_datalists_LAF(vars);

%% edge detection and pre-processing
for i=1:length(datalist.imgslist)
    len = length(datalist.imgslist{i});
    parfor j=1:len
        tic;
        pref = sprintf('%04d_%04d',i,j);
        if ~exist(fullfile(vars.abspath_out,vars.relpath_out_preprocess,[pref,'_1_preprocess.mat']),'file')
            % read the image and ground truth
            img     = imread([datalist.imgslist{i}(j).folder,'/',datalist.imgslist{i}(j).name]);
            gtInst  = imread([datalist.gtInstlist{i}(j).folder,'/',datalist.gtInstlist{i}(j).name]);
            inst_id  = unique(gtInst(gtInst>1000));
            % take ground truth and image around the obstacles;
            for k=1:size(inst_id,1)
                thresh = 15;
                area_sampling   = instancePart(gtInst,inst_id(k),thresh); 
                imgPart         = img(area_sampling.yl:area_sampling.yh,area_sampling.xl:area_sampling.xh,:);
                gtInstPart      = gtInst(area_sampling.yl:area_sampling.yh,area_sampling.xl:area_sampling.xh);
                occ             = calEdge(imgPart,vars.mod_sed);
                preprocess_name = fullfile(vars.abspath_out,vars.relpath_out_preprocess,[pref,'_',num2str(k), '_preprocess.mat']);
                parsave(preprocess_name,occ,'occ',imgPart,'imgPart',gtInstPart,'gtInstPart',area_sampling,'rect');
            end
        end
        t = toc;
        disp(['Preprocess',num2str(j),' ---> ',num2str(t),' s']);
    end
end

%% proposal and feature extraction
prelist = dir([vars.abspath_out,vars.relpath_out_preprocess,'*.mat']);
n_samples = 40;
onlyground = 1;
parfor i=1:size(prelist,1)
    tpfe = tic;
    pref = prelist(i).name(1:12);
    iouFname = [vars.abspath_out,vars.relpath_out_trData,pref,'train_data_20D.mat'];
    
    if ~exist(iouFname,'file')
        disp([num2str(i),' ',pref]);
        %% load data
        pre_data        = load([vars.abspath_out,vars.relpath_out_preprocess,prelist(i).name]);
        area_sampling   = pre_data.rect;                  % get image patch info, x,y,h,w information
        occ             = single(pre_data.occ);           % load occ of image patch
        img             = pre_data.imgPart;               % load original image patch
        gtInst          = pre_data.gtInstPart;            % load gtInst of image patch
        
        %% compute bounding boxes by Object-level Proposal
        tOLP = tic;
        [bbox,O] = get_proposal(occ);
        disp(['bounding boxes: OLP ',num2str(i),' ---> ',num2str(toc(tOLP)),' s']);
        [bbox_filter,idx_filtBBox] = filt_bbox(bbox,vars.box_size_filter,[area_sampling.xl,area_sampling.yl]); % seek the proper bounding boxes
        [iou_fusion,overlap_freespace] = compute_iou_v5_withinte(bbox_filter,gtInst);

        %% compute iou of box of ground truth
        inst_id = unique(gtInst(gtInst>1000));
        bbox_gt = zeros(size(inst_id,1),5); % re-score these bounding boxes
        for k=1:size(inst_id,1)
            [y1,x1] = find(gtInst == inst_id(k));
            maxX_s = max(x1)+1;   if maxX_s > size(gtInst,2), maxX_s = size(gtInst,2); end
            maxY_s = max(y1)+3;   if maxY_s > size(gtInst,1), maxY_s = size(gtInst,1); end
            minX_s = min(x1)-2;   if minX_s < 1, minX_s = 1; end
            minY_s = min(y1)-1;   if minY_s < 1, minY_s = 1; end
            h = maxY_s - minY_s;  w = maxX_s - minX_s;
            b = scoreboxMex(occ,O,0.65,0.75,0,1e3,0.1,0.5,0.5,3,1000,2,1.2,minX_s,minY_s,maxX_s-minX_s,maxY_s-minY_s);
            bbox_gt(k,:) = [minX_s,minY_s,w,h,b(5)];
        end
        iou_gt = compute_iou_v5_withinte(bbox_gt,gtInst); 
        iou_gt = max(iou_gt,[],1)';
        
        %% Training sample selection
        % select positive samples for training
        [iou_desc,index_iou] = sort(iou_fusion,2,'descend');
        ids_pos = index_iou(:,1:2);
        ids_pos = ids_pos(:);
        
        % More objects than samples asked
        if (length(ids_pos) > n_samples), ids_pos = ids_pos(1:n_samples); end
        
        % select boxes on the road
        idx_freespacebox = find(overlap_freespace > 0.4);
        idx_backgroundbox = find(overlap_freespace <= 0.4);
        
        % select negative samples from the road for training
        ids_rest = setdiff(idx_freespacebox,ids_pos);
        if (size(iou_fusion,2)-length(ids_pos)) > n_samples
            if length(ids_rest) > n_samples-length(ids_pos)
                ids_neg = ids_rest(randperm(length(ids_rest),n_samples-length(ids_pos)));
            else
                ids_neg = ids_rest(randperm(length(ids_rest),length(ids_rest)));
            end
        end
        
        if isrow(ids_neg), ids_neg = ids_neg';end
        ids_sample = [ids_pos; ids_neg];
        bbox_sample = bbox_filter(ids_sample,:);
        
        %% feature extraction
        tfeature = tic;
        [integral_hsv] = compute_feathsv_intgeral(img);
        feat = compute_feature_20_v2_fast([bbox_sample;bbox_gt],img,occ,[2048,1024],[area_sampling.xl,area_sampling.yl],integral_hsv);
        disp(['features',num2str(i),' ---> ',num2str(toc(tfeature)),' s']);
        
        %% save training samples
        max_iou = max(iou_fusion,[],1)';
        trainD_20 = [feat,[max_iou(ids_sample);iou_gt]];
        parsave([vars.abspath_out,vars.relpath_out_trData,pref,'traindata_20D.mat'],...
            feat,'feat',bbox_filter,'bbox',iou_fusion,'iou_fusion',trainD_20,'trainD');  
    end
    disp(['Cal one sample',num2str(i),' ---> ',num2str(toc(tpfe)),' s']);
end

%% training random forest
datalist20 = dir([vars.abspath_out,vars.relpath_out_trData,'*traindata_20D.mat']);
features20 = [];
ious20 = [];

for i=1:size(datalist20,1)
    disp(['read data ',datalist20(i).name(1:12),]);
    data20 = load([vars.abspath_out,vars.relpath_out_trData,datalist20(i).name]); 
    features20 = [features20;data20.trainD(:,1:end-1)];
    ious20 = [ious20;data20.trainD(:,end)];
end

save([pwd,'/model/samples_feat20D_',exp_name,'.mat'],'features20','ious20');
rf = regRF_train(features20,double(ious20),50);
save([pwd,'/model/OD_rfmodel_',exp_name,'_',num2str(50),'.mat'],'rf');
disp('Training done');