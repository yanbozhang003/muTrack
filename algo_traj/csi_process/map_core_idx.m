function index = map_core_idx(core, rx_cfg)
    if length(rx_cfg) == 4
        index = core + 1;
    end

    if length(rx_cfg) == 3
        index = core + 1;
        if index == 4
            index = 3;
        end
    end
    
    if length(rx_cfg) == 2
        if isequal(rx_cfg, [0 1])
            index = core+1;
        end
        if isequal(rx_cfg, [0 3])
            index = core + 1;
            if index == 4
                index = 2;
            end
        end
        if isequal(rx_cfg, [0 2])
            index = core + 1;
            if index == 3
                index = 2;
            end
        end
        if isequal(rx_cfg, [1 3])
            if core == 1
                index = core;
            end
            if core == 3
                index = core - 1;
            end
        end
    end
    
    if length(rx_cfg) == 1
        index = 1;
    end
end

