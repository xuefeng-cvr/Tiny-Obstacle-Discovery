function E = calOcc(I,w2c,KernelRegression)
[x,y,z] = size(I);
%%segmentation
Eedge=calEdge(I);
overseg_image=(Eedge<=0.05);
[label_image,label_num]=bwlabel(overseg_image);
%%obtain region info
[regions_num,regions,region_map]=get_info_of_regions2(label_num,label_image);
%%obtain junction info
[junctions_num,junctions,junction_map]=get_info_of_junctions(region_map);
%%obtain edge info
[edges_num,edges,edge_map,junction_edge_map,edge_junction_map,edge_region_map]=get_info_of_edges(region_map,junctions_num,junctions,junction_map);
%%calculate edge feature (mean strength, hsi histogram, colorname, texture, filter response)
edge_mean_strength_map=calculate_edge_mean_strength(Eedge,edges_num,edges);
region_hsi_hist_map = calculate_region_hsi_hist_fast( region_map,regions, I );
%tmp = load('w2crs'); w2c = tmp.w2crs;
region_colornaming_hist_map = calculate_region_colornaming_hist_fast(region_map,regions,I,w2c);
region_texture_map=calculate_region_texture(regions_num,region_map,I);
region_3d = cal_3_feature2(I,regions,region_map);
%%construct edge feature sample
features = get_features(edge_region_map,edge_mean_strength_map,region_hsi_hist_map,region_colornaming_hist_map,region_texture_map,region_3d);

%%regression for occlusion (test)
%load('KRR.mat'); %regression model
occ=KernelPrediction(KernelRegression,features);
%%occlusion map and fusion
E=occmap(occ,Eedge,x,y,edges_num,edges,junctions_num,junctions); E=single(E);

end

