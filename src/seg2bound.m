function [ ucm ] = seg2bound(seg,E)
%add boundaries on the superpixel map
k=1;
c0 = r(k,2) - r(4,2);
r0 = r(k,1) - r(4,1);
c1 = c0 + r(k,4);
r1 = r0 + r(k,3);
S = spDetectMex('boundaries',seg,E,1,4);
end

