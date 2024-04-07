
function ret = func_sanitCSI(pha_in)

    [n_rx, n_tx, n_sc] = size(pha_in);
    pha_sanit = zeros(n_rx, n_tx, n_sc);

    for txAnt_idx = 1:1:n_tx
        pha = squeeze(pha_in(:,1,:));
        pha_unwrap = unwrap(pha,[],2);

        % remove slope: M1
        pha_unwrap_avg = mean(pha_unwrap,1);

        p = polyfit(1:1:length(pha_unwrap_avg),pha_unwrap_avg,1);
        pha_unwrap = pha_unwrap - repmat([1:1:length(pha_unwrap_avg)]*p(1),n_rx,1);
        %  for rxAnt_idx = 1:1:n_rx
        %      CSI_pha_tmp = squeeze(CSI_pha(rxAnt_idx,:));
        %      CSI_amp_tmp = squeeze(CSI_amp(rxAnt_idx,:));
        %      CSI_sanit(rxAnt_idx,:) = CSI_amp_tmp .* exp(1i*wrapToPi(CSI_pha_tmp));
        %  end

        % remove slope: M2
        %     for rxAnt_idx = 1:1:n_rx
        %         CSI_pha_tmp = squeeze(CSI_pha(rxAnt_idx,:));
        %         CSI_amp_tmp = squeeze(CSI_amp(rxAnt_idx,:));
        %         
        %         p = polyfit(1:1:length(CSI_pha_tmp),CSI_pha_tmp,1);
        %         CSI_pha_tmp = CSI_pha_tmp - [1:1:length(CSI_pha_tmp)]*p(1);
        %         
        %         CSI_sanit(rxAnt_idx,:) = CSI_amp_tmp .* exp(1i*wrapToPi(CSI_pha_tmp));
        %     end

        % remove cliff
        for rxAnt_idx = 1:1:n_rx
            CSI_sanit_pha = squeeze(pha_unwrap(rxAnt_idx,:));
            
            for i = 1:1:5
                CSI_pha_diff = diff(CSI_sanit_pha);
                subc_r_idx = find(isoutlier(CSI_pha_diff,'movmed',10)==1);
                for idx = 1:1:3
                    if ~isempty(subc_r_idx)
                        if find(subc_r_idx(end)==[n_sc n_sc-1 n_sc-2 n_sc-3 n_sc-4 n_sc-5])
                            subc_r_idx(end) = [];
                        end
                    end
                end
                subc_r_left = [1;subc_r_idx'+1];
                subc_r_right = [subc_r_idx';n_sc];
                subchannel_range = [subc_r_left subc_r_right];

                subc_r_len = diff(subchannel_range');
                short_range_idx = find(subc_r_len<=2);
                if ~isempty(short_range_idx)
                    for idx = 1:1:length(short_range_idx)
                        subchannel_range(short_range_idx(idx),2) = subchannel_range(short_range_idx(idx)+1,2);
                    end
                    subchannel_range(short_range_idx+1,:) = [];
                end

                [n_subchannel,~] = size(subchannel_range);
                fit_win_len = 3;
                for align_idx = 1:1:n_subchannel-1
                    pha_ref = CSI_sanit_pha(subchannel_range(align_idx,1):subchannel_range(align_idx,2));
                    pha_align = CSI_sanit_pha(subchannel_range(align_idx+1,1):subchannel_range(align_idx+1,2));
                    L = length(pha_ref);
                    
                    if numel(pha_ref) >= fit_win_len
                        fit_win_x = 1:1:fit_win_len;
                        fit_win_y = pha_ref(L-fit_win_len+1:end);

                        pred_x = 1:1:(fit_win_len+1);
                        p = polyfit(fit_win_x, fit_win_y, 1);
                        pred_y = polyval(p,pred_x);
                    else
                        pred_y = mean(pha_ref);
                    end

            %         plot(fit_win_x,fit_win_y,'k.-'); hold on
            %         plot(pred_x, pred_y, 'r.-'); hold on

                    pha_gap = pha_align(1) - pred_y(end);
                    CSI_sanit_pha(subchannel_range(align_idx+1,1):subchannel_range(align_idx+1,2)) = CSI_sanit_pha(subchannel_range(align_idx+1,1):subchannel_range(align_idx+1,2)) - pha_gap;
                end
            end
            pha_sanit(rxAnt_idx,txAnt_idx,:) = wrapToPi(CSI_sanit_pha);
        end
    end
    ret = pha_sanit;