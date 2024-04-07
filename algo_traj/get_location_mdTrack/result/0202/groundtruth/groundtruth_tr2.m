clear;
close all

D1_tr1_x(1:8)=[4.79 4.41 4.02 3.65 3.34 2.95 2.55 2.11];
D1_tr1_x(9:12)=1.88;
D1_tr1_x(13:16)=[2.22 2.53 3.03 3.40];
D1_tr1_y(1:8)=2.68;
D1_tr1_y(9:12)=[3.01 3.47 3.86 4.30];
D1_tr1_y(13:16)=4.57;


D2_tr1_x = repmat(2.87,1,16);
D2_tr1_y = [2.31 2.72 3.12 3.55 3.94 4.27 4.72 5.12 5.50 5.90 6.33 6.78 7.18 7.59 7.98 8.31];

D3_tr1_x = repmat(2.87,1,16)+0.3;
D3_tr1_y = [2.31 2.72 3.12 3.55 3.94 4.27 4.72 5.12 5.50 5.90 6.33 6.78 7.18 7.59 7.98 8.31];

D4_tr1_x = D3_tr1_x(1:10);
D4_tr1_x(11:16) = [3.00 3.37 3.75 4.24 4.65 5.07]+0.17;
D4_tr1_y = D3_tr1_y - 0.3;
D4_tr1_y(11:16) = 6.32;

%%
Ori_dist_left = 4.09;
Ori_dist_upp  = 5.29;

Gtruth_D1.x = D1_tr1_x - Ori_dist_left;
Gtruth_D1.y = Ori_dist_upp - D1_tr1_y;

Gtruth_D2.x = D2_tr1_x - Ori_dist_left;
Gtruth_D2.y = Ori_dist_upp - D2_tr1_y;

Gtruth_D3.x = D3_tr1_x - Ori_dist_left;
Gtruth_D3.y = Ori_dist_upp - D3_tr1_y;

Gtruth_D4.x = D4_tr1_x - Ori_dist_left;
Gtruth_D4.y = Ori_dist_upp - D4_tr1_y;

Wdt = 7;
Len = 10.58;
figure('Position',[650 200 Wdt*100 Len*100])
plot(0,0,'gs',...
    'LineWidth',2,...
    'MarkerSize',10,...
    'MarkerEdgeColor','b',...
    'MarkerFaceColor',[0.5,0.5,0.5])
hold on

plot(Gtruth_D1.x,Gtruth_D1.y,'r.','MarkerSize',10);hold on
plot(Gtruth_D2.x,Gtruth_D2.y,'b.','MarkerSize',10);hold on
plot(Gtruth_D3.x,Gtruth_D3.y,'k.','MarkerSize',10);hold on
plot(Gtruth_D4.x,Gtruth_D4.y,'c.','MarkerSize',10);hold on
xlim([-Wdt/2 Wdt/2]);
ylim([-Len/2 Len/2]);

save('groundtruth_tr1.mat','Gtruth_D1','Gtruth_D2','Gtruth_D3','Gtruth_D4');