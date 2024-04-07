clear;
close all

D = 2;

load('./get_location_mdTrack/result/0128/Groundtruth.mat');
figure('Position',[650 200 535 725])
plot(Gtruth_D2.x,Gtruth_D2.y,'k--');
xlim([-5.35/2 5.35/2]);ylim([-7.25/2 7.25/2]);
grid on;
hold on;

%% problem 1 (biased cluster): localization algorithm cannot give accurate
%  result. What's worse, the biase is not constant. Therefore, it's hard to
%  decide the pattern of the movement. 
%  check trace (1,2,4) of divice 2
test_tr_idx = 4; 
load(['./get_location_mdTrack/result/0128/modify/D',num2str(D),...
    '_loc_2G_20M_tr',num2str(test_tr_idx),'.mat']);

plot(Gtruth_D2.x(test_tr_idx),Gtruth_D2.y(test_tr_idx),'.',...
    'MarkerSize',36,'MarkerEdgeColor','r'); hold on
plot(loc_vec(:,1),loc_vec(:,2),'.','MarkerSize',15,...
    'MarkerEdgeColor','b');hold on

%% problem 2 (drifted samples): location estimation drifts because of 
%  hardware imperfections and environment noise. 
