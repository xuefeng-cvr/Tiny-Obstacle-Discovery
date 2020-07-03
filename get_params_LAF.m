function [vars] = get_params_LAF(is_train, is_save_fv, exp_name, exp_dir, modelname)
%GET_PARAM get models and path
%
% USAGE
%  [vars] = get_param(is_train)
%
% INPUTS
%  is_train   - read training dataset or testing dataset
%  is_save_fv - whether to save the feature vector in testing
%  exp_name   - the name of this experiment
%  exp_dir    - the path to save result of experiment
%  modelname  - the filename of random forest model
%
% OUTPUTS
%  vars       - parameters (struct or name/value pairs)
%   .box_size_filter    - The size distribution of obstacles
%       .regionY        - [minY,maxY] Ordinate range of three adjancent regions which divide the search area.
%       .minmaxSZ       - [minSz,maxSz] Size range of obstacles in the three regions.
%       .minmaxW        - [minW,maxW] Width range of obstacles in the three regions.
%       .minmaxH        - [minH,maxH] Height range of obstacles in the three regions.
%   .region_LAF         - [top_left_Y,top_left_X,height,width] The multi-layers regions
%   .mod_sed            - model of structured edge detection
%   .abspath_LAF        - root path of lost and found
%   .relpath_IMG        - relative path of image directory
%   .relpath_GT         - relative path of ground truth directory
%   .relpath_TRAIN      - relative path of training set directory
%   .relpath_TEST       - relative path of testing set directory
%   .suffix_gtLabel     - suffix of ground truth label image
%   .suffix_gtInst      - suffix of ground truth instance image
%   .suffix_out         - suffix of out image
%   .abspath_out        - root path of output
%   .relpath_out_preprocess	- relative path for saving preprocess data
%   .relpath_out_cand	- relative path for saving candidates
%   .relpath_out_trData	- relative path for saving training samples
%   .relpath_test_probmaps - relative path for probability maps
%   .subdir             - relpath_TRAIN or relpath_TEST


%% dataset path setup
vars.abspath_LAF        = '/data/lostandfound/'; % change the variable to the root path of lost and found on your computer

vars.relpath_IMG        = 'leftImg8bit/';
vars.relpath_GT         = 'gtCoarse/';
vars.relpath_DISP       = 'disparity/';
vars.relpath_TRAIN      = 'train/';
vars.relpath_TEST       = 'test/';
vars.suffix_gtLabel     = '_gtCoarse_labelIds.png';
vars.suffix_gtInst      = '_gtCoarse_instanceIds.png';
vars.suffix_gtJson      = '_gtCoarse_polygons.json';
vars.suffix_disparity   = '_disparity.png';
vars.suffix_out         = 'proposal.png';
if is_train
    vars.subdir = vars.relpath_TRAIN;
else
    vars.subdir = vars.relpath_TEST;
end


if nargin > 1
    model=load('edgemodel.mat');
    load('region_LAF.mat');
    box_size_filter = load('box_size_filter.mat');
    vars.box_size_filter = box_size_filter.obs_size_filter;
    vars.region_LAF = freq_obs;
    vars.mod_sed = model.model;
    load('obsnumber.mat');
    vars.obsnumber = obsnumber;
    
    if is_train
        %% training path setup
        vars.abspath_out = [exp_dir,'/TrainingData_',exp_name,'/'];
        mkDirs([vars.abspath_out]);
        vars.relpath_out_preprocess    = 'preproc/';
        mkDirs([vars.abspath_out,vars.relpath_out_preprocess]);
        vars.relpath_out_cand   = 'cand/';
        mkDirs([vars.abspath_out,vars.relpath_out_cand]);
        vars.relpath_out_trData = 'traindata/';
        mkDirs([vars.abspath_out,vars.relpath_out_trData]);
        vars.relpath_train_allucms = 'ucms/';
        mkDirs([vars.abspath_out,vars.relpath_train_allucms]);
        load('dist_obs_trainset.mat');
    else
        %% testing path setup
        vars.abspath_test = [exp_dir,'/TestingData_',exp_name,'/'];
        vars.roc_mat = ['ROC_',exp_name,'.mat'];
        vars.recall_mat = ['recall_',exp_name,'.mat'];
        vars.time_mat = ['time_',exp_name,'.mat'];
        mkDirs([vars.abspath_test]);
        vars.relpath_test_result    = 'result/';
        mkDirs([vars.abspath_test,vars.relpath_test_result]);
        vars.relpath_test_tops   = 'top/';
        mkDirs([vars.abspath_test,vars.relpath_test_tops]);
        vars.relpath_test_times = 'times/';
        mkDirs([vars.abspath_test,vars.relpath_test_times]);
        vars.relpath_test_allucms = 'ucms/';
        mkDirs([vars.abspath_test,vars.relpath_test_allucms]);
        vars.relpath_test_probmaps = 'probmaps/';
        mkDirs([vars.abspath_test,vars.relpath_test_probmaps]);
        if is_save_fv == true
            vars.relpath_test_FeatVec = 'featvecs/';
            mkDirs([vars.abspath_test,vars.relpath_test_FeatVec]);
        end
        load('dist_obs_testset.mat');
        % load obs model
        load(modelname);
        vars.rf = rf;
    end
end
end
