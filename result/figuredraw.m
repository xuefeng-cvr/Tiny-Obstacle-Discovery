%% #############################################################################
%% ROC #########################################################################
%% #############################################################################
roc_1l = load('ROC_2020_07_03.mat');

cs = rand(1,3);
figure;
show_ROC(roc_1l,2,0,'-',cs(1,:));hold on;
xlabel('False Positive Rate(FPR)');
ylabel('True Positive Rate(TPR)');
title('50% top draw on the map');
legend('ICRA','Location','southeast');
axis([0 0.04 0 1]);
grid on;
set(gca,'FontSize',15);
set(gcf, 'position', [0 0 600 550]);
set(gca,'FontName','times new roman');

%% #############################################################################
%% recall ######################################################################
%% #############################################################################
recalls_1 = load('recall_2020_07_03.mat'); recalls_1 = recalls_1.recalls;

[ncnts,nious,ninsts] = size(recalls_1);
cnts = 0:5:1000; %201
ious = 0.5:0.05:1;  %11
iou_thresh = 0.7;
thresh_idx_cnt = 201;
thresh_idx_iou = 5;

figure
show_iou_recall(recalls_1,thresh_idx_cnt,ious,2,'-',cs(1,:)); hold on;
xlabel('IoU overlap threshold'), ylabel('Recalls');
grid on;
set(gca,'FontSize',16);
set(gcf, 'position', [0 0 600 550]);
ylim([0 1])
legend('ICRA','Location','southeast');
title('Proposals = 1000','fontname','Times New Roman','Color','k','FontSize',21);
set(gca,'FontName','times new roman');


figure
show_prop_recall(recalls_1,thresh_idx_iou,cnts,2,'-',cs(1,:)); hold on;
xlabel('Proposals'), ylabel('Recalls');
grid on;
set(gca,'FontSize',16);
set(gcf, 'position', [0 0 600 550]);
ylim([0 0.6])
legend('ICRA','Location','southeast');
title('IoU = 0.7','fontname','Times New Roman','Color','k','FontSize',21);
set(gca,'FontName','times new roman');


figure
show_AR(recalls_1,cnts,2,'-',cs(1,:)); hold on;
xlabel('Proposals'), ylabel('Average Recalls');
grid on;
set(gca,'FontSize',16);
set(gcf, 'position', [0 0 600 550]);
set(gca,'FontName','times new roman')
ylim([0 0.6])
legend('ICRA','Location','southeast');
title('IoU between [0.5 1]','fontname','Times New Roman','Color','k','FontSize',21);