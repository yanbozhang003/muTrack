function D_idx = get_Device_idx(macStr)
    switch macStr
        case '3A:DD:A8:63:AB:39'        % iphone mac1
            D_idx = 1;
        case '7A:A6:1E:29:88:17'
            D_idx = 1;                  % iphone mac2
        case '6C:B7:49:05:3E:F4'
            D_idx = 2;
        case 'B0:E5:ED:66:44:2F'
            D_idx = 3;
        case '40:4E:36:5C:0F:62'
            D_idx = 4;
        otherwise
            error('MAC address does not found!')
    end
end

