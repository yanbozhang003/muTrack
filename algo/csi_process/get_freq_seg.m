function [ret1, ret2] = get_freq_seg(BW_input)
    if BW_input == 20
        left_h = 2; left_t = 29;
        right_h = 37; right_t = 64;
    end
    if BW_input == 40
        left_h = 3; left_t = 59;
        right_h = 71; right_t = 127;
    end
    if BW_input == 80
        left_h = 3; left_t = 123;
        right_h = 135; right_t = 255;
    end
    
    ret1 = left_h:left_t; 
    ret2 = right_h:right_t;
end

