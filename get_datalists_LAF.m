function datalists = get_datalists_LAF(vars)
%GET_DATALISTS 
SceneName = dir([vars.abspath_LAF,vars.relpath_IMG,vars.subdir]);
SceneName(1:2)=[];
fname = fieldnames(SceneName);
hasFolder = 0;
for i = 1:size(fname,1)
    if isequal(fname{i},'folder')
        hasFolder = 1;
    end
end

imgslist = cell(length(SceneName),1);
gtLabellist = cell(length(SceneName),1);
gtInstlist = cell(length(SceneName),1);
gtJsonlist = cell(length(SceneName),1);
disparitylist = cell(length(SceneName),1);

for i=1:size(SceneName,1)
    imgslist{i} = dir([vars.abspath_LAF,vars.relpath_IMG,vars.subdir,SceneName(i).name,'/*.png']);
    gtLabellist{i} = dir([vars.abspath_LAF,vars.relpath_GT,vars.subdir,SceneName(i).name,'/*',vars.suffix_gtLabel]);
    gtInstlist{i} = dir([vars.abspath_LAF,vars.relpath_GT,vars.subdir,SceneName(i).name,'/*',vars.suffix_gtInst]);
    gtJsonlist{i} = dir([vars.abspath_LAF,vars.relpath_GT,vars.subdir,SceneName(i).name,'/*',vars.suffix_gtJson]);
    disparitylist{i} = dir([vars.abspath_LAF,vars.relpath_DISP,vars.subdir,SceneName(i).name,'/*',vars.suffix_disparity]);
    if ~hasFolder
        for j = 1:size(gtInstlist{i},1)
            imgslist{i}(j).folder = [vars.abspath_LAF,vars.relpath_IMG,vars.subdir,SceneName(i).name,'/'];
            gtLabellist{i}(j).folder = [vars.abspath_LAF,vars.relpath_GT,vars.subdir,SceneName(i).name,'/'];
            gtInstlist{i}(j).folder = [vars.abspath_LAF,vars.relpath_GT,vars.subdir,SceneName(i).name,'/'];
            gtJsonlist{i}(j).folder = [vars.abspath_LAF,vars.relpath_GT,vars.subdir,SceneName(i).name,'/'];
            disparitylist{i}(j).folder = [vars.abspath_LAF,vars.relpath_DISP,vars.subdir,SceneName(i).name,'/'];
        end
    end
end

datalists.imgslist = imgslist;
datalists.gtLabellist = gtLabellist;
datalists.gtInstlist = gtInstlist;
datalists.gtJsonlist = gtJsonlist;
datalists.disparitylist = disparitylist;
end

