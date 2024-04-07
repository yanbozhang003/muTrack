function ENV_para = para_cal(rx_x,rx_y,step)
land_Mark   = zeros(3,2);
land_Mark(:,1)  = rx_x';
land_Mark(:,2)  = rx_y';

 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Geo Grid Array %%%%%%%%%%%%%%%%%%%%%%%%%
% step    = 0.1;
x_min   = 0;
x_max   = 6.77;
loc_x   = x_min:step:x_max;
len_x   = length(loc_x);

y_min   = 0;
y_max   = 9.4;
loc_y   = y_min:step:y_max;
len_y   = length(loc_y);
 
loc_x_v = repmat(loc_x,length(loc_y),1);
loc_x_v = loc_x_v(:)';
loc_y_v = repmat(loc_y,1,length(loc_x));
len_v   = length(loc_x_v);

P       = zeros(2,len_v);
P(1,:)  = loc_x_v;
P(2,:)  = loc_y_v;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Location to AoA %%%%%%%%%%%%%%%%%%%%%%%%%
vec_AP      = P - repmat(land_Mark(1,:)',1,len_v);
complexN    = complex(vec_AP(1,:),vec_AP(2,:));
Ang_AP1     = angle(complexN);

vec_AP      = P - repmat(land_Mark(2,:)',1,len_v);
complexN    = complex(vec_AP(1,:),vec_AP(2,:));
Ang_AP2     = angle(complexN);

vec_AP      = P - repmat(land_Mark(3,:)',1,len_v);
complexN    = complex(vec_AP(1,:),vec_AP(2,:));
Ang_AP3     = angle(complexN);

Ang_AP      = [Ang_AP1;Ang_AP2;Ang_AP3];

ENV_para.Ang_AP     = Ang_AP;
 
ENV_para.loc_x_v    = loc_x_v;
ENV_para.loc_y_v    = loc_y_v;
ENV_para.loc_x      = loc_x;
ENV_para.loc_y      = loc_y;
ENV_para.len_x      = len_x;
ENV_para.len_y      = len_y;
ENV_para.land_Mark  = land_Mark;
end