clear;
close all

% Lets assume we have 7 trajectories with 100 datapoints each. 
% For example datapoints can be generated using randn
trajectories = randn(100,7);
% Taking mean across the trajectories (that is 2nd dimension) will give a single trajectory
trajectory = mean(trajectories,2);
p = 0.1; % define the error measure weightage (Give path matching closely with datapoint for high value of p)
% p must be between 0 and 1.
x_data = linspace(1,100,100); % Just to have 2D sense of trajectories

plot(x_data,trajectory,'k.','MarkerSize',20);hold on

path = csaps(x_data,trajectory,p);
fnplt(path); % show the path
% Here path is a structure which contains the polynomial coefficient between each successive pair of datapoint.