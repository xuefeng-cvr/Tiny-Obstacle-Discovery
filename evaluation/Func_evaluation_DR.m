function Func_evaluation_DR(topsdir,savepath,datalist)

top_list    = dir([topsdir,'*tops.mat']);   % Obtain the list of file saving bounding boxes
D1_prop_num = 0:5:1000;                     % The 1st dimension, save the threshold of the top proposals number
D2_ious     = 0.5:0.05:1;                   % The 2nd dimension, save the threshold of the IoU between proposal and groundtruth proposal

recalls     = []; % [prop_num x iou_num x inst_num] [k,l,j] Taking k top proposal, l iou, whether the j obstacle is discoverd?
idx         = []; % the image index of each obstacle.
n           = 1;  % count the obstacle

for i = 1:length(top_list)              % iterate all the file saving bounding boxes
    top_name = top_list(i).name;
    sID = str2double(top_name(1:4));    % index of scene
    iID = str2double(top_name(6:9));    % index of image
    top = load([topsdir,top_list(i).name]); % read the bounding boxes
    top = top.bbtop;
    gt  = imread([datalist.gtInstlist{sID}(iID).folder,'/',datalist.gtInstlist{sID}(iID).name]); % read ground truth
    inst_num        = length(unique(gt(gt>1000)));
    [iou,~]         = compute_iou_v6(top,gt); % [obstacle_num x bbox_num]compute the iou between each proposal and each obstacle
    [~, types]      = seg2proposal(gt); % obtain the label of each obstacle
    recall  = zeros(length(D1_prop_num),length(D2_ious),inst_num);
    
    if ~isempty(top)
        for j = 1:inst_num                          % loop different obstacle
            idx = [idx; [sID,iID,types(j)]];        % record the obstacle information
            for k = 1:length(D1_prop_num)           % loop different threshold of the top proposals number
                for l = 1:length(D2_ious)           % loop different threshold of ious
                    count = D1_prop_num(k);
                    if D1_prop_num(k) > size(iou,2) % if the proposal number is insufficient
                        count = size(iou,2);
                    end
                    recall(k,l,j) = any(iou(j,1:count) > D2_ious(l)); % if any proposal have the iou larger than threshold, the corresponding obstacle is discoverd
                end
            end
        end
    end
    recalls(:,:,n:n+inst_num-1) = recall;
    n = n + inst_num;
    disp(top_name);
end
parsave(savepath,recalls,'recalls',idx,'idx');
end