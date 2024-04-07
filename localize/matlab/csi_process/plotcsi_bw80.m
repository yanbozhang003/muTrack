function [] = plotcsi_bw80( csi, nfft, normalize, core_v, rxss_v, pkt_v)
%PLOTCSI Summary of this function goes here
%   Detailed explanation goes here

csi_buff = fftshift(csi,2);
head = 7; tail = 250; len = 120;
csi_buff =[ csi_buff(:,head:head+len),csi_buff(:,tail-len:tail) ];
csi_phase = rad2deg(angle(csi_buff));
for cs = 1:size(csi_buff,1)
    csi = abs(csi_buff(cs,:));
    if normalize
        csi = csi./max(csi);
    end
    csi_buff(cs,:) = csi;
end

[~,nfft] = size(csi_buff);
csi_buff(:,122) = 0;

figure
x = -(nfft/2):1:(nfft/2-1);
subplot(3,1,3)
imagesc(x,[1 size(csi_buff,1)],csi_buff)
myAxis = axis();
axis([min(x)-0.5, max(x)+0.5, myAxis(3), myAxis(4)])
set(gca,'Ydir','reverse')
xlabel('Subcarrier')
ylabel('Packet number')

max_y = max(csi_buff(:));
for cs = 1:size(csi_buff,1)
    fprintf('core : %d | rxss: %d | pkt: %d\n', core_v(cs), rxss_v(cs), pkt_v(cs));
    
    csi = csi_buff(cs,:);
    
    subplot(3,1,1)
    plot(x,csi);
    grid on
    myAxis = axis();
    axis([min(x)-0.5, max(x)+0.5, 0, max_y])
    xlabel('Subcarrier')
    ylabel('Magnitude')
    title('Channel State Information')
    text(max(x),max_y-(0.05*max_y),['Packet #',num2str(cs),' of ',num2str(size(csi_buff,1))],'HorizontalAlignment','right','Color',[0.75 0.75 0.75]);
    
    subplot(3,1,2)
    plot(x,csi_phase(cs,:));
    grid on
    myAxis = axis();
    axis([min(x)-0.5, max(x)+0.5, -180, 180])
    xlabel('Subcarrier')
    ylabel('Phase')
    disp('Press any key to continue..');
    waitforbuttonpress();
end
close

end

