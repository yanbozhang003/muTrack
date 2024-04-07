function [loc_LOS,ANG_PDF_M_LOS] = func_Localizer(EST_para_result,ENV_para,mu,sigma)
%%%%%%%%%%%%%%%% translate the AoA to real angle %%%%%%%%%%%%%%%%
%%%%
%%%% EST_para_result(PathNUM,ParaNUM,SockNUM,PktNUM)
%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~,~,AP_NUM]          = size(EST_para_result); 

Ang_AP      = ENV_para.Ang_AP;
len_v       = length(Ang_AP);
ANG_PDF_LOS = zeros(1,len_v);

for ap_idx = 1:1:AP_NUM     
    [LOS_ALL,~]     = func_identify_LOS(EST_para_result(:,:,ap_idx));    
    ANG_PDF_LOS     = ANG_PDF_LOS + func_normalPDF(Ang_AP(ap_idx,:),LOS_ALL(1,2),mu,sigma);
end

[loc_ret_x,loc_ret_y,ANG_PDF_M] = PDF2Loc(ANG_PDF_LOS,ENV_para);

loc_LOS         = [loc_ret_x,loc_ret_y];
ANG_PDF_M_LOS   = ANG_PDF_M;
 
end
function [LOS,idx]    = func_identify_LOS(PathP)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%         We first look at the TOF, choose the one with smallest TOF
    %%%         If ToF is too close to each other, we choose the one with 
    %%%         largest amplitude
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [PathP_sort_tof,tof_idx]  = sortrows(PathP,1);
    [PathP_sort_amp,amp_idx]  = sortrows(PathP,-4);
    [len1,~]        = size(PathP);
    LOS     = PathP_sort_amp(1,:);
    idx     = amp_idx(1,1);
    if len1 == 1
        LOS     = PathP_sort_amp(1,:);
        idx     = amp_idx(1,1);
    else
%         if (PathP_sort_amp(1,4) - PathP_sort_amp(2,4)) > 5
% %             fprintf('LOC-1\n');
%             LOS     = PathP_sort_amp(1,:);
%             idx     = amp_idx(1,1);
%         elseif (PathP_sort_amp(1,4) - PathP_sort_amp(2,4)) > 4 && abs(PathP_sort_tof(1,1) - PathP_sort_tof(2,1)) < 10 * 10^(-9)
% %             fprintf('LOC-2\n');
%             LOS     = PathP_sort_amp(1,:);
%             idx     = amp_idx(1,1);
%         else
% %             fprintf('LOC-3\n');
%             LOS     = PathP_sort_tof(1,:);
%             idx     = tof_idx(1,1);
%         end    
    end
end
function [loc_ret_x,loc_ret_y,ANG_PDF_M] = PDF2Loc(ANG_PDF,ENV_para)
    loc_x_v     = ENV_para.loc_x_v;
    loc_y_v     = ENV_para.loc_y_v;
    len_x       = ENV_para.len_x;
    len_y       = ENV_para.len_y;
    [~,M_I]     = max(ANG_PDF);
    loc_ret_x   = loc_x_v(1,M_I);
    loc_ret_y   = loc_y_v(1,M_I);
    ANG_PDF_M   = reshape(ANG_PDF,len_y,len_x);
%     yanbo_k = (loc_ret_y-3.35)/(loc_ret_x-3.35); 
    yanbo_theta = rad2deg(atan2(loc_ret_y-3.35,loc_ret_x-3.35));
%     fprintf('theta: %f\n', yanbo_theta);
end
function pdf = func_normalPDF(Ang_AP,AoA,mu,sigma)
%     ang_err     = Ang_AP - AoA - pi/2;
    ang_err     = Ang_AP - AoA;
    pdf         = normpdf(ang_err,mu,sigma);
    AoA_degree = rad2deg(AoA);
%     fprintf('AoA: %d', AoA_degree);
end