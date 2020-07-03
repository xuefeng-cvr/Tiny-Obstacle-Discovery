function [ seg ] = ucm2seg( ucm )
%convert a ultrametric contour map to the corresponding superpixel map

ucm2 = upSampleEdges(ucm); 
ucm2(end+1,:) = ucm2(end,:); 
ucm2(:,end+1) = ucm2(:,end);

seg2 = bwlabel(ucm2 == 0,8);
seg = seg2(2:2:end,2:2:end);

end

