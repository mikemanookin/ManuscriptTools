function W = polarWaves(theta_deg, m, se, varargin)
% POLARWAVES  Cartesian waves for drawing a tuning curve with error bars on polar axes.
%
%   W = polarWaves(theta_deg, m, se)
%   W = polarWaves(theta, m, se, 'Rings', [0.5 1], 'Rmax', 40)
%
% Canonical copy: ManuscriptTools/Matlab/MatlabToIgorTools/polarWaves.m (the A1 paper's
% motion.polarWaves is the same function). Draw the result in Igor with PolarPlots.ipf;
% see ManuscriptTools/docs/IgorPolarPlots.md.
%
% Igor Pro has no radial error bars, so the polar plot is built from ordinary XY
% traces on a square (Plan) axis system. Angles are directions of motion in degrees,
% counter-clockwise from +x; negative means are clipped to 0 (a radius cannot be
% negative). Returns a struct of paired x/y waves ready for makeAxisStruct / line():
%
%   W.curve_x, W.curve_y   mean tuning curve, closed (first point repeated)
%   W.err_x,   W.err_y     radial error bars: for every direction the segment from
%                          (m - se) to (m + se), segments separated by NaN so Igor
%                          and MATLAB draw them as disconnected lines
%   W.pts_x,   W.pts_y     the mean points alone (for markers)
%   W.grid_x,  W.grid_y    reference rings at 'Rings' x Rmax (NaN-separated) plus
%                          the horizontal and vertical axis lines
%   W.rmax                 radius of the outer ring: max(m + se) ('RmaxFrom' 'sem', default) or
%                          max(m) ('RmaxFrom' 'mean'), rounded UP to a round number
%                          (1, 1.5, 2, 2.5, 3, 4, 5, 6, 8 x 10^k; 'Nice' true) unless 'Rmax' given
%   W.theta, W.r, W.se     the inputs after sorting / clipping
%
% OPTIONS  'Rings' (fractions of Rmax to draw, default [0.5 1]); 'Rmax' ([] = from data);
%          'RmaxFrom' 'sem' | 'mean'; 'Nice' (true) round Rmax up to a round number so the
%          outer ring reads e.g. 25 sp/s rather than 24.8;
%          'Vector' ([dsi pref_dir]: adds W.vec_x / W.vec_y, a segment from the origin
%          of length dsi * Rmax at pref_dir).

ip = inputParser;
ip.addParameter('Rings', [0.5 1], @isnumeric);
ip.addParameter('Rmax', [], @(x) isempty(x) || isnumeric(x));
ip.addParameter('RmaxFrom', 'sem', @ischar);
ip.addParameter('Nice', true, @islogical);
ip.addParameter('Vector', [], @(x) isempty(x) || numel(x) == 2);
ip.parse(varargin{:});
opt = ip.Results;

[th, order] = sort(mod(double(theta_deg(:)), 360));
r = max(double(m(:)), 0); r = r(order);
se = double(se(:)); se = se(order); se(isnan(se)) = 0;
a = th * pi / 180;

W = struct();
W.theta = th'; W.r = r'; W.se = se';
rmax = opt.Rmax;
if isempty(rmax)
    if strcmpi(opt.RmaxFrom, 'mean'), rmax = max(r); else, rmax = max(r + se); end
    if opt.Nice, rmax = niceCeil(rmax); end
end
if ~(rmax > 0), rmax = 1; end
W.rmax = rmax;

W.curve_x = [r .* cos(a); r(1) * cos(a(1))]';
W.curve_y = [r .* sin(a); r(1) * sin(a(1))]';
W.pts_x = (r .* cos(a))'; W.pts_y = (r .* sin(a))';

lo = max(r - se, 0); hi = r + se;
ex = [lo .* cos(a), hi .* cos(a), nan(size(a))]'; ey = [lo .* sin(a), hi .* sin(a), nan(size(a))]';
W.err_x = ex(:)'; W.err_y = ey(:)';

phi = linspace(0, 2 * pi, 181)';
gx = []; gy = [];
for f = opt.Rings(:)'
    gx = [gx; f * rmax * cos(phi); NaN]; gy = [gy; f * rmax * sin(phi); NaN]; %#ok<AGROW>
end
gx = [gx; -rmax; rmax; NaN; 0; 0]; gy = [gy; 0; 0; NaN; -rmax; rmax];
W.grid_x = gx'; W.grid_y = gy';

if ~isempty(opt.Vector) && all(~isnan(opt.Vector))
    pd = opt.Vector(2) * pi / 180;
    W.vec_x = [0, opt.Vector(1) * rmax * cos(pd)];
    W.vec_y = [0, opt.Vector(1) * rmax * sin(pd)];
end
end

function v = niceCeil(x)
% smallest of {1,1.5,2,2.5,3,4,5,6,8,10} x 10^k that is >= x (24.8 -> 25, 36.6 -> 40, 12 -> 15)
if ~(x > 0), v = 1; return; end
e = 10^floor(log10(x));
steps = [1 1.5 2 2.5 3 4 5 6 8 10];
v = steps(find(steps * e >= x * (1 - 1e-9), 1)) * e;
end
