function [integral_hsv] = compute_feathsv_intgeral(img)
% compute the integal map of hsv for feature extraction
hsv = rgb2hsv(img);

edges_1 = [0 15 25 45 55 80 108 140 165 190 220 255 275 290 316 330 345 361];
cot_1 = length(edges_1)-1;
edges_2 = [0 0.0625 0.1250 0.1875 0.2500 0.3125 0.3750 0.4375 0.5000 0.5625 0.6250 0.6875 0.7500 0.8125 0.8750 0.9375 1.1];
cot_2 = length(edges_2)-1;

H = hsv(:,:,1)*360;
S = hsv(:,:,2);
V = hsv(:,:,3);
h = H;
s = S;
v = V;
height = size(h,1);
width = size(h,2);

integral_h = zeros(height,width,cot_1);
integral_s = zeros(height,width,cot_2);
integral_v = zeros(height,width,cot_2);

for i=1:cot_1
    integral_h(:,:,i) = cumsum(cumsum(H>=edges_1(i)&H<edges_1(i+1), 2), 1);
end
for i=1:cot_2
    integral_s(:,:,i) = cumsum(cumsum(S>=edges_2(i)&S<edges_2(i+1), 2), 1);
    integral_v(:,:,i) = cumsum(cumsum(V>=edges_2(i)&V<edges_2(i+1), 2), 1);
end
integral_hsv = zeros(height,width,cot_1+2*cot_2);

integral_hsv(:,:,1:cot_1) = integral_h;
integral_hsv(:,:,cot_1+1:cot_2+cot_1) = integral_s;
integral_hsv(:,:,cot_2+cot_1+1:2*cot_2+cot_1) = integral_v;

integral_hsv(2:end+1,:,:) = integral_hsv(:,:,:);
integral_hsv(:,2:end+1,:) = integral_hsv(:,:,:);
integral_hsv(1,:,:) = 0;
integral_hsv(:,1,:) = 0;

end

