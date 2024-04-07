function subc_idx = get_subchannel(BW_input)
    if BW_input == 20
        subc_idx = [1 28 29 56];
    end
    if BW_input == 80
        subc_idx = [1 58 59 121 122 242];
    end
end

