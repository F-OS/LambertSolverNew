% MATLAB script to plot orbits of Earth and Mars from Jan 1, 1990 to Jan 1, 1992
% with data points every 6 hours, and calculate average orbital speed and eccentricity.

% Constants
mu_sun = 1.3271244e11;  % km^3/s^2, standard gravitational parameter for the Sun

% Time setup
start_time = datetime(1990, 1, 1, 0, 0, 0, 'TimeZone', 'UTC');
end_time = datetime(1992, 1, 1, 0, 0, 0, 'TimeZone', 'UTC');
step_duration = hours(6);
times = start_time:step_duration:end_time;
num_points = length(times);

% Preallocate arrays
r_earth = zeros(3, num_points);  % Positions for Earth (km)
v_earth = zeros(3, num_points);  % Velocities for Earth (km/s)
r_mars = zeros(3, num_points);   % Positions for Mars (km)
v_mars = zeros(3, num_points);   % Velocities for Mars (km/s)

% Loop over time steps to fetch positions and velocities
for i = 1:num_points
    epoch = datestr(times(i), 'yyyy-mm-ddTHH:MM:SS');
    
    % Earth (target '399')
    [r_earth(:, i), v_earth(:, i)] = rv_helio_spice('399', epoch);
    
    % Mars (target '499')
    [r_mars(:, i), v_mars(:, i)] = rv_helio_spice('499', epoch);
end

% Plot the orbits in 3D
figure;
hold on;
plot3(r_earth(1, :), r_earth(2, :), r_earth(3, :), 'b-', 'LineWidth', 1.5);  % Earth orbit in blue
plot3(r_mars(1, :), r_mars(2, :), r_mars(3, :), 'r-', 'LineWidth', 1.5);    % Mars orbit in red
plot3(0, 0, 0, 'yo', 'MarkerSize', 10, 'MarkerFaceColor', 'y');              % Sun at origin
xlabel('X (km)');
ylabel('Y (km)');
zlabel('Z (km)');
title('Orbits of Earth and Mars (Heliocentric, 1990-1992)');
legend('Earth', 'Mars', 'Sun');
grid on;
axis equal;
view(3);  % 3D view
hold off;

% Calculate average orbital speeds
speeds_earth = vecnorm(v_earth, 2, 1);  % Magnitude of velocity at each point
avg_speed_earth = mean(speeds_earth);  % Average speed (km/s)

speeds_mars = vecnorm(v_mars, 2, 1);
avg_speed_mars = mean(speeds_mars);

% Calculate eccentricity at each point and average
% For Earth
h_earth = cross(r_earth, v_earth, 1);  % Specific angular momentum
r_norm_earth = vecnorm(r_earth, 2, 1);
e_vec_earth = cross(v_earth, h_earth, 1) / mu_sun - r_earth ./ r_norm_earth;
e_earth = vecnorm(e_vec_earth, 2, 1);
avg_ecc_earth = mean(e_earth);

% For Mars
h_mars = cross(r_mars, v_mars, 1);
r_norm_mars = vecnorm(r_mars, 2, 1);
e_vec_mars = cross(v_mars, h_mars, 1) / mu_sun - r_mars ./ r_norm_mars;
e_mars = vecnorm(e_vec_mars, 2, 1);
avg_ecc_mars = mean(e_mars);

% Display results
disp('Average Orbital Speed for Earth (km/s):');
disp(avg_speed_earth);
disp('Average Eccentricity for Earth:');
disp(avg_ecc_earth);

disp('Average Orbital Speed for Mars (km/s):');
disp(avg_speed_mars);
disp('Average Eccentricity for Mars:');
disp(avg_ecc_mars);