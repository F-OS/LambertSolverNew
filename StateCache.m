% Earth-Mars transfer screening (no flyby).

% Assume rv_helio_spice and best_lambert_branch are defined elsewhere.
% Assume EARTH_ID and MARS_ID are defined as strings, e.g., EARTH_ID = '399'; MARS_ID = '499';

classdef StateCache < handle
    % Cache for SPICE state vectors to avoid repeated expensive calls.
    properties
        cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    
    methods
        function obj = StateCache()
        end
        
        function [r, v] = get(obj, target, t_jd)
            key = sprintf('%s_%.15f', target, t_jd);
            if isKey(obj.cache, key)
                rv = obj.cache(key);
                r = rv(1:3);
                v = rv(4:6);
            else
                [r, v] = rv_helio_spice(target, t_jd);
                obj.cache(key) = [r(:); v(:)];
            end
        end
        
        function clear(obj)
            if ~isempty(obj.cache)
                remove(obj.cache, keys(obj.cache));
            end
        end
        
        function sz = size(obj)
            sz = obj.cache.Count;
        end
    end
end