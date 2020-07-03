function [img_marked] = drawProposals(bbox_top,top,img,gtJson_filepath)
% draw the boxes on the image, red indicates the top 10, blue indicates
% others
img_marked = showGTinIMG(img,gtJson_filepath);

if top > size(bbox_top,1)
    top = size(bbox_top,1);
end

c = 11:top; img_marked = insertShape(img_marked,'Rectangle',bbox_top(c,1:4),'Color','blue','LineWidth',1);
c = 1:10;   img_marked = insertShape(img_marked,'Rectangle',bbox_top(c,1:4),'Color','red','LineWidth',2);
end

