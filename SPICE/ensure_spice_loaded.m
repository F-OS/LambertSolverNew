function ensure_spice_loaded()
    % Ensure SPICE kernels are loaded in the current process.
    global SPICE_READY 
    global KERNEL_PATHS
    if cspice_ktotal('ALL') == 0 || isempty(SPICE_READY)
        for i = 1:length(KERNEL_PATHS)
            cspice_furnsh(KERNEL_PATHS{i});
        end
        SPICE_READY = true;
    end
end