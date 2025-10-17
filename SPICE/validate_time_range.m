function validate_time_range(t, target)
    % Validate that the target has ephemeris data for the given time.
    % Raises error with helpful message if data is not available.
    try
        et = cspice_str2et(t);
        if isnumeric(target)
            [~, ~] = cspice_spkez(target, et, config().FRAME, 'NONE', config().SUN_ID);
        else
            targ = upper(char(target));
            [~, ~] = cspice_spkezr(targ, et, config().FRAME, 'NONE', config().CENTER);
        end
    catch e
        if contains(string(e.identifier), 'SPICE') && contains(e.message, 'insufficient')  % Approximate check for SPKINSUFFDATA
            if ~isnumeric(target)
                try
                    target_id = cspice_bodn2c(upper(string(target)));
                catch
                    target_id = [];
                end
            else
                target_id = target;
            end
            if isempty(target_id)
                error('Unknown target ''%s''. Cannot check coverage.', target);
            end
            loaded_kernels = cspice_ktotal('ALL');
            coverage_info = {};
            for i = 0:loaded_kernels-1
                [kernel, ~, ~, ~] = cspice_kdata(i, 'ALL', 1000, 1000, 1000);
                try
                    spk_info = cspice_spkobj(kernel);
                    if any(spk_info == target_id)
                        coverage = cspice_spkcov(kernel, target_id);
                        if ~isempty(coverage)
                            start_et = coverage(1);
                            end_et = coverage(end);
                            start_time = cspice_et2utc(start_et, 'ISOC', 0);
                            end_time = cspice_et2utc(end_et, 'ISOC', 0);
                            coverage_info{end+1} = sprintf('%s: %s to %s', kernel, start_time, end_time);
                        end
                    end
                catch
                    % pass
                end
            end
            if isempty(coverage_info)
                coverage_msg = 'No kernels found with coverage for this target';
            else
                coverage_msg = strjoin(coverage_info, newline);
            end
            error('No ephemeris data available for target ''%s'' at %s.\nAvailable coverage:\n%s\nConsider updating your kernel set or checking the target ID.', target, t, coverage_msg);
        else
            error('SPICE error for target ''%s'' at %s: %s', target, t, e.message);
        end
    end
end