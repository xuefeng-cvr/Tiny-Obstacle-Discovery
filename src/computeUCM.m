function U = computeUCM( E )
% creates ultrametric contour map from SP contours
E = upSampleEdges(E);
S=bwlabel(E==0,8); S=S(2:2:end,2:2:end)-1;
S(end,:)=S(end-1,:); S(:,end)=S(:,end-1);
E(end+1,:)=E(end,:); E(:,end+1)=E(:,end);
U=ucm_mean_pb(E,S); U=U(1:2:end-2,1:2:end-2);

end