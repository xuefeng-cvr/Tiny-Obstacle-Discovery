function [ rect ] = instancePart( gt,instID,k )
% clip a rectangle region with the obstacle as the center
[r,c] = size(gt);
[y,x] = find(gt == instID);
xl = min(x);
xh = max(x);
yl = min(y);
yh = max(y);
w = xh - xl;
h = yh - yl;
if h > w , length = h;else length = w;end
thresh = k * length;
if thresh < 100, thresh = 100;end

if h<thresh, h = (thresh-h)/2;else h = thresh; end % if object is small ,use small box, if object is large, use big box.
yh = yh + h;yl = yl - h; 
if w<thresh, w = (thresh-w)/2;else w = thresh; end 
xh = xh + w;xl = xl - w;
if yl<1, yl = 1; end
if xl<1, xl = 1; end
if yh>r, yh = r; end
if xh>c, xh = c; end

rect.yl = yl; % rect info
rect.yh = yh;
rect.xl = xl;
rect.xh = xh;

end

