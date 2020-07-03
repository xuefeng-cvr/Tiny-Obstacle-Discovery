function E = upSampleEdges( E0 )
% upsample E0 by factor of two while mostly keeping edges thin
[h,w]=size(E0); h=h*2; w=w*2; E=zeros(h,w); E(1:2:h-1,1:2:w-1)=E0;
E(1:2:h-1,2:2:w-2)=min(E0(:,1:end-1),E0(:,2:end)); E(h,:)=E(h-1,:);
E(2:2:h-2,1:2:w-1)=min(E0(1:end-1,:),E0(2:end,:)); E(:,w)=E(:,w-1);
% remove single pixel segments created by thick edges in E0 (2x2 blocks)
A=single(ones(2))/4; A=conv2(single(E0>0),A)==1; [xs,ys]=find(A);
for i = 1:length(xs)
    x=(xs(i)-1)*2; y=(ys(i)-1)*2; es=ones(2,4)+1;
    if(x>2   && y>2  ), es(:,1)=[E(x-2,y-1) E(x-1,y-2)]; end
    if(x<h-2 && y>2  ), es(:,2)=[E(x+2,y-1) E(x+1,y-2)]; end
    if(x<h-2 && y<w-2), es(:,3)=[E(x+2,y+1) E(x+1,y+2)]; end
    if(x>2   && y<w-2), es(:,4)=[E(x-2,y+1) E(x-1,y+2)]; end
    [e,j]=min(max(es));
    if(j==1 || j==4), x1=x-1; else x1=x+1; end
    if(j==1 || j==2), y1=y-1; else y1=y+1; end
    E(x,y1)=e; E(x1,y)=e; E(x1,y1)=e;
    if(es(1,j)<es(2,j)), E(x,y1)=0; else E(x1,y)=0; end
end
end

