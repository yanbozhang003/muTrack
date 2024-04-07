clear;
close all

BW = 20;                  % bandwidth 
rx_config = [0 1 2 3];    
n_Tx = 1;                 % Tx antenna number, currently only support 1
Band = 5;                 % frequency band 5GHz

tr_idx = 6;
fileName = ['spotFi_',num2str(BW),'M_',num2str(Band),'G_','Nrx',num2str(length(rx_config)),'_tr',num2str(tr_idx)];
FILE = ['../data/',fileName,'.mat'];

load(FILE);
load('../data/calib/constPhsDiff_tr1.mat');
[n_rx,n_tx,n_sc,n_pkt] = size(CSI_struct);
if n_sc == 56
    sc_idle_idx = [8 22 35 49];
end

CSI_struct(:,:,sc_idle_idx,:) = [];
[~,~,n_sc,~] = size(CSI_struct);

pha_diff_exp = exp(-1i*pha_diff);
pha_diff_exp = pha_diff_exp(rx_config+1,:);

n_pkt = 1;
CSI_sanit = zeros(4,n_pkt);
for pkt_idx = 1:1:n_pkt
    CSI_sanit_tmp = squeeze(CSI_struct(:,1,:,pkt_idx)) .* pha_diff_exp;  
%     CSI_sanit(:,pkt_idx) = squeeze(mean(CSI_sanit_tmp(:,26:27),2));
    CSI_sanit(:,pkt_idx) = squeeze(CSI_sanit_tmp(:,27));
end

x = CSI_sanit;
M = 4;
P = 2;
lamda = 5.6e-2;
d = lamda/2;
% eigen analysis
R = x*x'; % Data covarivance matrix
[N,V] = eig(R); % Find the eigenvalues and eigenvectors of R
NN = N(:,1:M-P); % Estimate noise subspace

% peak searching
theta = -90 : 0.5 : 90; % Peak search
for ii = 1 : length(theta)
SS = zeros(1,length(M));
for jj = 0 : M-1
SS(1+jj) = exp(-1i*2*jj*pi*d*sin(theta(ii)/180*pi)/lamda);
end
PP = SS*NN*NN'*SS';
Pmusic(ii) = abs(1/ PP);
end

Pmusic = 10*log10(Pmusic/max(Pmusic)); % Spatial spectrum function
plot(theta,Pmusic,'k.-','LineWidth',1.5)
% [pks,locs] = findpeaks(Pmusic,theta)
% text(locs,pks,num2str((1:numel(pks))'))
xlabel('angle \theta/degree','FontSize',15)
% ylabel('spectrum function P(\theta) /dB')
ylabel('Normalized power (dB)','FontSize',15);
% title('DOA estimation based on MUSIC algorithm ')
grid on