function [r_km, v_kms] = rv_helio_spice(target, epoch)
    % Return heliocentric position (km) and velocity (km/s) for target at epoch.
    % Returns plain arrays (no units) to avoid expensive ops inside tight loops.
    % target: SPICE name or ID (string or numeric). epoch: ISO time string (UTC).
    ensure_spice_loaded();
    validate_time_range(epoch, target);
    et = cspice_str2et(epoch);
    tgt = upper(char(target));
    [state, ~] = cspice_spkezr(tgt, et, config().FRAME, 'NONE', config().CENTER);
    % state: [rx, ry, rz, vx, vy, vz] with km and km/s
    r_km = state(1:3);
    v_kms = state(4:6);
end