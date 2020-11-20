function [d]=haversine(lat1,lon1,lat2,lon2)
% HAVERSINE FORMULA
    dlat = radians(lat2-lat1);
    dlon = radians(lon2-lon1);
    lat1 = radians(lat1);
    lat2 = radians(lat2);
    a = (sin(dlat./2)).^2 + cos(lat1) .* cos(lat2) .* (sin(dlon./2)).^2;
    %distance in radians
    c = 2 .* atan2(sqrt(a), sqrt(1-a));
    %distance in km (multiply by radius of the earth
    d = 6372.8 * c;
end

function rad = radians(degree) 
% degrees to radians
    rad = degree .* pi / 180;
end


