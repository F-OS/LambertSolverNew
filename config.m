function p = config()
    % Configuration and constants for LambertLab.
    
    % Default paths
    [script_path, ~, ~] = fileparts(mfilename('fullpath'));
    p.PROJECT_ROOT = script_path;
    p.DATA_DIR = fullfile(p.PROJECT_ROOT, 'data');
    p.KERNELS_DIR = fullfile(p.DATA_DIR, 'kernels');
    
    % Default kernel files
    p.DEFAULT_KERNELS = {...
        fullfile(p.KERNELS_DIR, 'naif0012.tls'), ...
        fullfile(p.KERNELS_DIR, 'de440.bsp'), ...
        fullfile(p.KERNELS_DIR, 'gm_de440.tpc'), ...
        fullfile(p.KERNELS_DIR, '20000001.bsp'), ...
        fullfile(p.KERNELS_DIR, 'mar097.bsp'), ...
        fullfile(p.KERNELS_DIR, 'pck00011.tpc') ...
    };
    % Constants
    p.AU = 149597870.7;  % km, astronomical unit
    p.MU_SUN = 1.32712440018e20;  % m^3/s^2, gravitational parameter of Sun
    p.MU_MARS = 42828.37;  % km^3/s^2, gravitational parameter of Mars
    p.RP_MIN_MARS = 300.0;  % km, minimum periapsis radius for Mars flyby
    
    % Default bodies (NAIF IDs)
    p.EARTH_ID = '399';
    p.MARS_ID = '499';
    p.SUN_ID = '10';

    p.VEL_TOL_KMS = 1e-3;  % km/s tolerance for v_inf matching
    p.ANG_TOL_DEG = 1.0;   % degree tolerance for angle matching
    p.C3_TOL = 1e-6;       % C3 tolerance for convergence


    
    % Default frame
    p.FRAME = 'J2000';
    p.CENTER = '10';

end