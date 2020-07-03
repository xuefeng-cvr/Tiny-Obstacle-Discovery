function Func_evaluation_time(timesdir,savepath)

time_list = dir([timesdir,'*times.mat']);  % Obtain the list of file saving bounding boxes
recalls = []; % [prop_num x iou_num x inst_num] [k,l,j] Taking k top proposal, l iou, whether the j obstacle is discoverd?
idx = [];     % the image index of each obstacle.
n = 1;        % count the obstacle

times = [];
for i = 1:length(time_list)   % iterate all the file saving bounding boxes
    top_name = time_list(i).name;
    time = load([timesdir,time_list(i).name]); % read the time
    time = time.time_olp;
    times = [times;time];
    disp(top_name);
end

mean_times = mean(times);
parsave(savepath,mean_times,'mean_times');
end