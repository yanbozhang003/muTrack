function [stop,p_diff] = xDTrack_stop_condition(PathP_old,PathP,opt)

time_d      = abs(PathP_old(:,1) - PathP(:,1));
time_v      = sum(time_d(:));

aoa_d       = abs(PathP_old(:,2) - PathP(:,2));
aoa_v       = sum(aoa_d(:));

time_dif    = time_v / opt.delay_step;
aoa_dif     = aoa_v / opt.angle_step;

num         = 4;
if time_v < num * opt.delay_step && aoa_v < num *opt.angle_step 
    stop    = 1;
else     
%     fprintf('time dif: %d | aoa_dif: %d \n',time_dif,aoa_dif);
    stop    = 0;
end

p_diff       = time_dif + aoa_dif;
end