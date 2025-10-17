function [v1, v2] = lambert_leg(r1, r2, tof, mu, dir)
    global DLLLoaded
    if isempty(DLLLoaded)
        res = ivLam_initializeDLL(char(fullfile(config().PROJECT_ROOT, "lamsolve/")));
        if res == 0
            DLLLoaded = [1];
        else 
            error('DLL initialization failed. Check the path or DLL status.');
        end
    end 
    [v1, v2] = ivLam_zeroRev_multipleInputDLL(1, r1, r2, tof, dir);
    if isempty(v1) || isempty(v2)
        error('Velocity vectors could not be computed. Check input parameters.');
    end
    % Scale 
end