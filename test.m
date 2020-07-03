%% test of obstacle detection
clc; clear; close all;
warning('off');
addpath(genpath(pwd));

%% set parameters and load dataset
is_train = false;
is_save_fv = false;
exp_dir = '/data/Experiment';
exp_name = '2020_07_03';
modelname = 'OD_rfmodel_2020_07_03_50.mat';
vars = get_params_LAF(is_train, is_save_fv, exp_name, exp_dir, modelname);
datalist = get_datalists_LAF(vars);
hlayer = size(vars.region_LAF,1);

%% detect obstacle in each test image
for i=1:size(datalist.imgslist,1)
   parfor j=1:size(datalist.imgslist{i},1)
        
        t_all = tic;
        fileprefix = sprintf('%04d_%04d',i,j);
        disp(fileprefix);
        
        img                 = imread([datalist.imgslist{i}(j).folder,'/',datalist.imgslist{i}(j).name]);
        gtJson_filepath     = [datalist.gtJsonlist{i}(j).folder,'/',datalist.gtJsonlist{i}(j).name];
        top_savename        = [vars.abspath_test,vars.relpath_test_tops,fileprefix,'_tops.mat'];
        edge_savename       = [vars.abspath_test,vars.relpath_test_allucms,fileprefix,'_ucms.mat'];
        box_savename        = [vars.abspath_test,vars.relpath_test_tops,fileprefix,'_tops.mat'];
        time_savename       = [vars.abspath_test,vars.relpath_test_times,fileprefix,'_times.mat'];
        pm_savename         = [vars.abspath_test,vars.relpath_test_probmaps,fileprefix,'_probmap.mat'];
        res_box_savename    = [vars.abspath_test,vars.relpath_test_result,fileprefix,'_resbox.png'];
        res_seg_savename    = [vars.abspath_test,vars.relpath_test_result,fileprefix,'_resseg.png'];
        
        if ~exist([vars.abspath_test,vars.relpath_test_tops,fileprefix,'_tops.mat'],'file')
            %% detect the obstacle-aware occlusion edge map
            t_edge = tic;
            if ~exist(edge_savename,'file')
                [ucms] = compute_obsEdge_fast_v4(img, vars.mod_sed, vars.region_LAF);
                parsave(edge_savename,ucms,'ucms');
            else
                ucms = load(edge_savename);
                ucms = ucms.ucms;
            end
            time_edge = toc(t_edge);
            
            bbox_all = [];
            feat_all = [];
            tl_olp = 0;
            tl_filt = 0;
            tl_feat = 0;
            tl_all = 0;
            % compute integral map for hsv feature
            [integral] = compute_feathsv_intgeral(img);
            %% detect obstacles in all layers
            for k = 1:size(vars.region_LAF,1)
                t_1 = tic;
                img_cut = img(vars.region_LAF(k,1) : (vars.region_LAF(k,3)+vars.region_LAF(k,1)) ,vars.region_LAF(k,2) : (vars.region_LAF(k,2)+vars.region_LAF(k,4)),:);
                integral_cut = integral(vars.region_LAF(k,1) : (vars.region_LAF(k,3)+vars.region_LAF(k,1)+1) ,vars.region_LAF(k,2) : (vars.region_LAF(k,2)+vars.region_LAF(k,4)+1),:);
                % obtain the proposal by Object-level Proposal
                t_olp = tic;
                [bbox_olp,O] = get_proposal(ucms{k});
                time_olp = toc(t_olp);
                % filt the proposal with abnormal sizes
                t_filt = tic;
                [bbox_olp,idx_filtBBox] = filt_bbox(bbox_olp,vars.box_size_filter,[vars.region_LAF(k,2), vars.region_LAF(k,1)]);
                time_filt = toc(t_filt);
                % feature extraction
                t_f = tic;
                feat = compute_feature_20_v2_fast(bbox_olp,img_cut,ucms{k},[2048,1024],[vars.region_LAF(k,2), vars.region_LAF(k,1)],integral_cut);
                time_f = toc(t_f);
                % change the coordinate system to the original image
                bbox_olp(:,1) = bbox_olp(:,1) + vars.region_LAF(k,2);
                bbox_olp(:,2) = bbox_olp(:,2) + vars.region_LAF(k,1);
                
                bbox_all = [bbox_all;bbox_olp];
                feat_all = [feat_all;feat];
                
                time_t1 = toc(t_1);
                tl_all = tl_all + time_t1;
                tl_olp = tl_olp + time_olp;
                tl_filt = tl_filt + time_filt;
                tl_feat = tl_feat + time_f;
                disp(['picture ',sprintf('%04d_%04d : %02d ',i,j,k),' all ',num2str(time_t1),' s ; olp',num2str(time_olp),' s ; filt',num2str(time_filt),' s; feature ',num2str(time_f),' s ; AllBox ',num2str(size(bbox_olp,1)),' ; FiltedBox ',num2str(size(bbox_olp,1))]);
            end
            %% predicting by random forest
            t_pre = tic;
            [class_scores, prediction_per_tree, nodes] = regRF_predict(feat_all,vars.rf);
            [scores, ids] = sort(class_scores,'descend');
            time_pre = toc(t_pre);
            if isrow(scores); scores = scores'; end
            bbox_all = [bbox_all(ids,:),scores];
            idx_scores = find(scores > 0.25);
            bbox_top = bbox_all(idx_scores,:);
            %% generate the results
            probmap = get_probmap(bbox_top,size(img));
            result_box = drawProposals(bbox_top,200,img,gtJson_filepath);
            result_seg = get_obsmap(img,bbox_top,200);
            %% save result
            imwrite(result_seg,res_seg_savename);
            imwrite(result_box,res_box_savename);
            parsave(pm_savename,probmap,'prob_map');
            parsave(time_savename,tl_all,'time_all',time_edge,'time_edge',tl_olp,'time_olp',tl_filt,'time_filt',tl_feat,'time_feat',time_pre,'time_predict');
            parsave(box_savename,bbox_top,'bbtop');
        end
        close all;
        time_all = toc(t_all);
        disp([fileprefix,' : ', num2str(time_all),' s']);
    end
end

Func_evaluation_DR([vars.abspath_test,vars.relpath_test_tops],...
    ['./result/',vars.recall_mat],...
    datalist);

Func_evaluation_ROC([vars.abspath_test,vars.relpath_test_tops],...
    [vars.abspath_test,vars.relpath_test_probmaps],...
    ['./result/',vars.roc_mat],...
    datalist);