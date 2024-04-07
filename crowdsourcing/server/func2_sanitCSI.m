
function ret = func_sanitCSI(pha_in)
    THRESHOLD = 0.2;

    [n_rx, n_tx, n_sc] = size(pha_in);
    pha_sanit = zeros(n_rx,n_tx,n_sc);
        

    for tx_idx = 1:1:n_tx
        pha = squeeze(pha_in(:,tx_idx,:));

        %% phase sanit
        CSI_pha = unwrap(pha,[],2);

        % remove slope: M1
        CSI_pha_avg = mean(CSI_pha,1);

        p = polyfit(1:1:length(CSI_pha),CSI_pha_avg,1);
        CSI_pha = CSI_pha - repmat([1:1:length(CSI_pha)]*p(1),n_rx,1);

        for rx_idx = 1:1:n_rx
            CSI_plt_pha = CSI_pha(rx_idx,:);
            
            for idx = 1:1:n_sc-1
                h = CSI_plt_pha(idx+1)-CSI_plt_pha(idx);
                if abs(h) >= THRESHOLD
                    CSI_plt_pha(idx+1:end) = CSI_plt_pha(idx+1:end)-h;
                end
            end
            pha_sanit(rx_idx,tx_idx,:) = wrapToPi(CSI_plt_pha);
        end
    end
    ret = pha_sanit;
    