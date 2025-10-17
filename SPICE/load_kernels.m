function load_kernels(paths)
    % Load SPICE kernels from provided paths (idempotent).
    if nargin < 1 || isempty(paths)
        paths = config().DEFAULT_KERNELS;
    end
    global KERNEL_PATHS
    global SPICE_READY
    cspice_kclear();
    for i = 1:length(paths)
        kernel = paths{i};
        if ~exist(kernel, 'file')
            error('Kernel file not found: %s', kernel);
        end
        fprintf('Loading kernel: %s\n', kernel);
        try
            cspice_furnsh(kernel);
            fprintf('Successfully loaded %s\n', kernel);
        catch e
            error('Error loading kernel %s: %s', kernel, e.message);
        end
    end
    KERNEL_PATHS = paths;
    SPICE_READY = true;
end