clear;
close all

load('./data/spotFi_20M_2G_tr14.mat');
load('./data/Calib/spotFi_fastcalib_20M_2G.mat');

[n_rx,n_tx,n_sc,n_pkt] = size(CSI_struct);

pha_diff = [zeros(1,n_sc);pha_diff_rx12;pha_diff_rx13];
pha_diff_exp = exp(-1i*pha_diff);

% n_pkt = 200;
CSI_sanit = zeros(n_rx,n_pkt);
AoA_vec = zeros(1,1);
for pkt_idx = 1:1:n_pkt
    pkt_idx

    CSI_sanit_tmp = squeeze(CSI_struct(:,1,:,pkt_idx)) .* pha_diff_exp;    
    CSI_sanit(:,pkt_idx) = squeeze(mean(CSI_sanit_tmp(:,26:27),2));
    
    x = CSI_sanit(:,pkt_idx);
%     x = squeeze(CSI_struct(:,1,27,pkt_idx));

    M = 3;
    P = 1;
    c = 3e8;
    f_carrier = 2.437e9;
    lamda = c/f_carrier;
    % d = lamda/2;
    d = 5.75e-2;
%     d = 2.8e-2;
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
    
%     drawnow();
    waitforbuttonpress();
    [~,I] = max(Pmusic);
    AoA_vec(pkt_idx,1) = theta(I);
end

plot(AoA_vec,'k.-')