% plots a simulated image e.g. from simPipeline make target

graphics_toolkit('gnuplot');
close all;

% first column: pixel number
% second column: fractal iteration count
a = load('output.txt');
[pixel, index] = sort(a(:, 1));

% extract fractal iteration count
b = a(:, 2);

% re-shuffle as image pixels
b = b(index);

% order as image

if (numel(b) == 1920*1080)
    c = reshape(b, [1920, 1080]);
elseif (numel(b) == 640*480)
    c = reshape(b, [640, 480]);
else
    error('unsupported size - please edit');
end
    

% monitor first dimension is x
c = c.';

% show image
imagesc(c);