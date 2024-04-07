function pwr = func_pwr(Xn)
% [~,len2] = size(Xn);
x_tmp   = abs(Xn) .^2;
pwr     = sum(x_tmp(:));
% pwr     = pwr ./ len2;
% pwr = sum((abs(Xn)));

end