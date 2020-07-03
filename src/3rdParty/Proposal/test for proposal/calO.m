function O= calO( E )
%compute approximate orientation from edges like Edge Boxes
[Ox,Oy]=gradient2(convTri(E,4));
[Oxx,~]=gradient2(Ox); [Oxy,Oyy]=gradient2(Oy);
O=mod(atan(Oyy.*sign(-Oxy)./(Oxx+1e-5)),pi);
end

