function [dep_times, tof_days, c3_grid, vinf_out_x, vinf_out_y, vinf_out_z, ...
    vinf_in_x, vinf_in_y, vinf_in_z, vM_x, vM_y, vM_z, rM_x, rM_y, rM_z] = ...
    screen_em_grid_cached(dep_start, dep_end, dep_step_days, tof_min_days, ...
    tof_max_days, tof_step_days, dep_body, arr_body, coarse_refine, coarse_factor)
    % Screen Earth-Mars grid with caching and return grids.
    if nargin < 7
        dep_body = config().EARTH_ID;
    end
    if nargin < 8
        arr_body = config().MARS_ID;
    end
    if nargin < 9
        coarse_refine = false;
    end
    if nargin < 10
        coarse_factor = 4;
    end
    
    dep_start_t = to_time(dep_start);
    dep_end_t = to_time(dep_end);
    
    % Create base grids
    base_dep_times = dep_start_t:dep_step_days:dep_end_t;
    base_tof_days = tof_min_days:tof_step_days:tof_max_days;
    
    if coarse_refine
        % Run coarse grid first
        coarse_dep_step = max(1, dep_step_days * coarse_factor);
        coarse_tof_step = max(1, coarse_factor);
        coarse_dep_times = dep_start_t:coarse_dep_step:dep_end_t;
        coarse_tof_days = tof_min_days:coarse_tof_step:tof_max_days;
        
        fprintf('Running coarse grid: %dx%d = %d points\n', ...
            length(coarse_dep_times), length(coarse_tof_days), ...
            length(coarse_dep_times) * length(coarse_tof_days));
        
        % Compute coarse grid
        coarse_results = compute_grid_chunk(...
            coarse_dep_times, coarse_tof_days, dep_body, arr_body);
        
        % Find promising regions (C3 < some threshold)
        valid_c3 = coarse_results.c3_grid(~isnan(coarse_results.c3_grid));
        if isempty(valid_c3)
            c3_threshold = Inf;
        else
            c3_threshold = prctile(valid_c3, 25);  % Bottom 25% of C3 values
        end
        promising_mask = coarse_results.c3_grid < c3_threshold;
        
        if ~any(promising_mask(:))
            fprintf('No promising regions found in coarse grid, using all points\n');
            promising_mask = true(size(coarse_results.c3_grid));
        end
        
        % Create refined grid around promising points
        [dep_times, tof_days] = create_refined_grid(...
            coarse_dep_times, coarse_tof_days, promising_mask, ...
            dep_step_days, base_tof_days, dep_start_t, dep_end_t);
        
        fprintf('Refined to %dx%d = %d points\n', ...
            length(dep_times), length(tof_days), length(dep_times) * length(tof_days));
    else
        dep_times = base_dep_times;
        tof_days = base_tof_days;
    end
    
    % Compute the final grid
    results = compute_grid_chunk(dep_times, tof_days, dep_body, arr_body);
    
    c3_grid = results.c3_grid;
    vinf_out_x = results.vinf_out_x;
    vinf_out_y = results.vinf_out_y;
    vinf_out_z = results.vinf_out_z;
    vinf_in_x = results.vinf_in_x;
    vinf_in_y = results.vinf_in_y;
    vinf_in_z = results.vinf_in_z;
    vM_x = results.vM_x;
    vM_y = results.vM_y;
    vM_z = results.vM_z;
    rM_x = results.rM_x;
    rM_y = results.rM_y;
    rM_z = results.rM_z;
end

function t_jd = to_time(t)
    % Convert input to TDB JD.
    if ischar(t) || isstring(t)
        dt = datetime(t);
        t_jd = juliandate(dt, 'juliandate');
    else
        t_jd = t;  % Assume already JD
    end
end

function results = compute_grid_chunk(dep_times, tof_days, dep_body, arr_body)
    % Compute grid chunk serially.
    n_dep = length(dep_times);
    n_tof = length(tof_days);
    
    % Initialize result arrays
    c3_grid = nan(n_dep, n_tof);
    vinf_out_x = nan(n_dep, n_tof);
    vinf_out_y = nan(n_dep, n_tof);
    vinf_out_z = nan(n_dep, n_tof);
    vinf_in_x = nan(n_dep, n_tof);
    vinf_in_y = nan(n_dep, n_tof);
    vinf_in_z = nan(n_dep, n_tof);
    vM_x = nan(n_dep, n_tof);
    vM_y = nan(n_dep, n_tof);
    vM_z = nan(n_dep, n_tof);
    rM_x = nan(n_dep, n_tof);
    rM_y = nan(n_dep, n_tof);
    rM_z = nan(n_dep, n_tof);
    
    % Serial computation with shared cache
    cache = StateCache();
    
    % Prefetch all required states
    for i = 1:n_dep
        cache.get(dep_body, dep_times(i));
    end
    
    for i = 1:n_dep
        dep = dep_times(i);
        for j = 1:n_tof
            tof = tof_days(j);
            arr = dep + tof;
            cache.get(arr_body, arr);
        end
    end
    
    fprintf('Prefetched %d state vectors\n', cache.size());
    
    for i = 1:n_dep
        dep = dep_times(i);
        for j = 1:n_tof
            tof = tof_days(j);
            arr = dep + tof;
            try
                [~, c3_val, v_inf_dep, v_inf_arr, r_arr, v_arr_planet, ~] = ...
                    compute_em_c3_tof_cached(dep, arr, cache, dep_body, arr_body);
                c3_grid(i, j) = c3_val;
                vinf_out_x(i, j) = v_inf_dep(1);
                vinf_out_y(i, j) = v_inf_dep(2);
                vinf_out_z(i, j) = v_inf_dep(3);
                vinf_in_x(i, j) = v_inf_arr(1);
                vinf_in_y(i, j) = v_inf_arr(2);
                vinf_in_z(i, j) = v_inf_arr(3);
                vM_x(i, j) = v_arr_planet(1);
                vM_y(i, j) = v_arr_planet(2);
                vM_z(i, j) = v_arr_planet(3);
                rM_x(i, j) = r_arr(1);
                rM_y(i, j) = r_arr(2);
                rM_z(i, j) = r_arr(3);
            catch
                % Leave as NaN
            end
        end
    end
    
    results = struct(...
        'c3_grid', c3_grid, ...
        'vinf_out_x', vinf_out_x, ...
        'vinf_out_y', vinf_out_y, ...
        'vinf_out_z', vinf_out_z, ...
        'vinf_in_x', vinf_in_x, ...
        'vinf_in_y', vinf_in_y, ...
        'vinf_in_z', vinf_in_z, ...
        'vM_x', vM_x, ...
        'vM_y', vM_y, ...
        'vM_z', vM_z, ...
        'rM_x', rM_x, ...
        'rM_y', rM_y, ...
        'rM_z', rM_z ...
    );
end

function [refined_dep_times, refined_tof_days] = create_refined_grid(...
    coarse_dep_times, coarse_tof_days, promising_mask, fine_dep_step, ...
    fine_tof_days, dep_start, dep_end)
    % Create refined grid around promising coarse grid points.
    refined_dep_times_set = [];
    refined_tof_days_set = [];
    
    n_coarse_dep = length(coarse_dep_times);
    n_coarse_tof = length(coarse_tof_days);
    
    for i = 1:n_coarse_dep
        for j = 1:n_coarse_tof
            if promising_mask(i, j)
                % Add this coarse point and surrounding fine points
                coarse_dep = coarse_dep_times(i);
                coarse_tof = coarse_tof_days(j);
                
                % Add points in a window around this promising point
                dep_window = fine_dep_step * 2;  % ±2 steps
                tof_window = 4;  % ±4 days
                
                dep_min = max(dep_start, coarse_dep - dep_window);
                dep_max = min(dep_end, coarse_dep + dep_window);
                
                % Add fine departure times in this window
                dep_times_window = dep_min:fine_dep_step:dep_max;
                refined_dep_times_set = [refined_dep_times_set, dep_times_window];
                
                % Add TOF values in window
                tof_min = max(fine_tof_days(1), coarse_tof - tof_window);
                tof_max = min(fine_tof_days(end), coarse_tof + tof_window);
                tof_values = fine_tof_days(fine_tof_days >= tof_min & fine_tof_days <= tof_max);
                refined_tof_days_set = [refined_tof_days_set, tof_values];
            end
        end
    end
    
    % Convert back to arrays
    refined_dep_times = sort(unique(refined_dep_times_set));
    refined_tof_days = sort(unique(refined_tof_days_set));
end

function [tof_days, min_C3, v_inf_dep, v_inf_arr, r_arr, v_arr_planet, used] = ...
    compute_em_c3_tof_cached(dep_time, arr_time, cache, dep_body, arr_body, prograde, lowpath)
    % Compute (tof_days, C3, v_inf_dep, v_inf_arr, r_arr, v_arr_planet, branch) for Earth-Mars pair using cache.
    if nargin < 6
        prograde = [];
    end
    if nargin < 7
        lowpath = [];
    end
    
    dep_t = to_time(dep_time);
    arr_t = to_time(arr_time);
    if arr_t <= dep_t
        error('Arrival time must be after departure time');
    end
    
    % Sun-centered states (cached)
    [r_dep, v_dep_planet] = cache.get(dep_body, dep_t);
    [r_arr, v_arr_planet] = cache.get(arr_body, arr_t);
    
    % Time of flight
    tof_days = arr_t - dep_t;
    
    % Try Lambert branches
    res = best_lambert_branch(r_dep, v_dep_planet, r_arr, tof_days, prograde, lowpath);
    if isempty(res)
        error('No Lambert solution found for %s to %s transfer from %f to %f (TOF: %.1f days)', ...
            dep_body, arr_body, dep_t, arr_t, tof_days);
    end
    [min_C3, v_dep_best, v_arr_best, used] = deal(res{:});
    
    % v_inf relative to planets
    v_inf_dep = v_dep_best - v_dep_planet;
    v_inf_arr = v_arr_best - v_arr_planet;
    
    min_C3 = double(min_C3);
end
