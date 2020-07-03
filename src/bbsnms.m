function  bbs1=bbsnms(bbs,beta,maxBoxes)
      [bbs,~]=sortrows(bbs,-5);
      bbskept=zeros(0,5);
      i=1;
      j=size(bbs,1);
      
      n=j;
      m=0;
      while(i<n&&m<maxBoxes)
           
            keep=1;
            
            for j=1:m
                  if keep
                        keep=iou(bbs(i,:),bbskept(j,:))<beta;
                  end
            end
            if keep
                  m=m+1;
                  bbskept(m,:)=bbs(i,:);
            end
            i=i+1;
      end
      bbs1=bbskept;
end
function iou1=iou(bb1,bb2)
      left=max(bb1(1),bb2(1));
      right=min(bb1(1)+bb1(3),bb2(1)+bb2(3));
      top=max(bb1(2),bb2(2));
      bottom=min(bb1(2)+bb1(4),bb2(2)+bb2(4));
      if left>right||top>bottom
            iou1=0;
      else
            area=(right-left)*(bottom-top);
            iou1=area/(bb1(3)*bb1(4)+bb2(3)*bb2(4)-area);
      end
end