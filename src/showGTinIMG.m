function [ img ] = showGTinIMG(img, gt_json_file)
%draw the segmentation of road and obstacles on the image
jsonData = loadjson(gt_json_file);
freespace = jsonData.objects{1,1}.polygon;
freespace = freespace';
freespace = freespace(:)';
img = insertShape(img,'FilledPolygon',freespace, 'Color', {'blue'},'Opacity',0.3);

for i = 2:size(jsonData.objects,2)-1
    if isempty(str2num(jsonData.objects{1,i}.label))
        continue;
    end
    obs = jsonData.objects{1,i}.polygon;
    obs = obs';
    obs = obs(:)';
    img = insertShape(img,'FilledPolygon',obs, 'Color', {'green'},'Opacity',0.7);
end
end