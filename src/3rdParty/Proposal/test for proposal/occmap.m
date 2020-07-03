function E = occmap(occ,U,x,y,edges_num,edges,junctions_num,junctions)
%%calculate the final edge map with basic and occlusion edges
tol=0.15; E=zeros(x,y);
occ=occ+tol; L=sign(occ);
for i=1:edges_num %assign occlusion confidence to each pixel
      if L(i)==1
         for j=1:edges{i,1}
              [a,b] = ind2sub([x,y],edges{i,2}(j));  
              E(a,b)=occ(i);
         end
      end
end
for i=1:junctions_num %fill every junction
         a=junctions(i,1); b=junctions(i,2);
         if a>1&&a<x&&b>1&&b<y
             if E(a-1,b)>0
                 E(a,b)=E(a-1,b);
             elseif  E(a+1,b)>0
                 E(a,b)=E(a+1,b);
             elseif E(a,b-1)>0
                 E(a,b)=E(a,b-1);
             elseif E(a,b+1)>0
                 E(a,b)=E(a,b+1);
             end
         end
end
E=E.*E+(1-E).*U; %edge map fusion
E = computeUCM( E );
end

