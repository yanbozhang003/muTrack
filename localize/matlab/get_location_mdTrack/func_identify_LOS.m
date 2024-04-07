function [LOS,idx]    = func_identify_LOS(PathP)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%         We first look at the TOF, choose the one with smallest TOF
    %%%         If ToF is too close to each other, we choose the one with 
    %%%         largest amplitude
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [PathP_sort_tof,tof_idx]  = sortrows(PathP,1);
    [PathP_sort_amp,amp_idx]  = sortrows(PathP,-4);
    [len1,~]        = size(PathP);
    if len1 == 1
        LOS     = PathP_sort_amp(1,:);
        idx     = amp_idx(1,1);
    else
        if (PathP_sort_amp(1,4) - PathP_sort_amp(2,4)) > 8
%             fprintf('LOC-1\n');
            LOS     = PathP_sort_amp(1,:);
            idx     = amp_idx(1,1);
        elseif (PathP_sort_amp(1,4) - PathP_sort_amp(2,4)) > 4 && abs(PathP_sort_tof(1,1) - PathP_sort_tof(2,1)) < 10 * 10^(-9)
%             fprintf('LOC-2\n');
            LOS     = PathP_sort_amp(1,:);
            idx     = amp_idx(1,1);
        else
%             fprintf('LOC-3\n');
            LOS     = PathP_sort_tof(1,:);
            idx     = tof_idx(1,1);
        end    
    end
end