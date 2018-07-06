function [gcArray, f] = g_causality(data, fs, fres, separateWindows, momax)
% Frequency-domain granger causality
%    Estimates frequency-domain granger causality from x->y and y->x. Estimates
%    are given for all frequency bands given by f.
%    
%    INPUTS 
%    x, y: Signals. Each should be a NxW matrix of time windows (N: Time
%        points per window; W: number of windows).
%    fres: number of frequencies to evaluate (not including dc component)
%    fs: Sampling rate (Hz)
%    separateWindows: (optional) boolean indicating whether to model windows seperately
%    momax: maximum model order for model order estimation
%    OUTPUTS
%    gcArray: spectral granger causality estimates
%    f: frequencies corresponding to the elements of gcArray
%
% This function requires the MVGC toolbox. Portions of this code were taken from mvgc_demo script of that toolbox.

%VERBOSE = false;

if nargin < 5
  momax = ceil(fs/5); % fifth of a second     

  if nargin < 4
    separateWindows = true;
  end
end

data = permute( data, [2,1,3]);

% Calculate information criteria up to specified maximum model order.
% fprintf('Comparing model orders...\n')
% [~,~,order,~] = tsdata_to_infocrit(data, momax, 'LWR', VERBOSE) %;
order = momax;

f = sfreqs(fres, fs);

if separateWindows
% loop over each window seperately
  [C,~,W] = size(data);
  F = numel(f);
  gcArray = zeros(C,C,F,W);
else
% run through loop once using all windows
  W = 1;
  thisData = data;
end

a = tic;
for w = 1:W
  if separateWindows
    thisData = data(:, :, w);
    fprintf('Starting window %d: %2.1fs elapsed\n', w, toc(a))
  end

  for c1 = 1:C
    for c2 = 1:C
      if c1 == c2, continue, end
      gcArray(c1,c2,:,w) = GCCA_tsdata_to_smvgc(thisData, c2, c1, order, ...
          fres, 'OLS');
    end
  end
