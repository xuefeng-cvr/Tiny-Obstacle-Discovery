function [depth] = Disp2Depth(disp,fx,baseline,delta)
% convert disparity map to depth map
depth = zeros(size(disp));
idx = find(disp > 100);
depth(idx) = fx * baseline./ (double(disp(idx)) ./ delta);
end

