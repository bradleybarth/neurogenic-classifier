function odata = decimateiir(idata,r,nfilt)
%DECIMATE Resample data at a lower rate after lowpass filtering.
%   Y = DECIMATE(X,R) resamples the sequence in vector X at 1/R times the
%   original sample rate.  The resulting resampled vector Y is R times
%   shorter, i.e., LENGTH(Y) = CEIL(LENGTH(X)/R). By default, DECIMATE
%   filters the data with an 8th order Chebyshev Type I lowpass filter with
%   cutoff frequency .8*(Fs/2)/R, before resampling.
%
%   Y = DECIMATE(X,R,N) uses an N'th order Chebyshev filter.  For N greater
%   than 13, DECIMATE will produce a warning regarding the unreliability of
%   the results.  See NOTE below.
%
%
%   Note: For better results when R is large (i.e., R > 13), it is
%   recommended to break R up into its factors and calling DECIMATE several
%   times.
%
%   EXAMPLE: Decimate a signal by a factor of four
%   t = 0:.00025:1;  % Time vector
%   x = sin(2*pi*30*t) + sin(2*pi*60*t);
%   y = decimate(x,4);
%   subplot(1,2,1);
%   stem(x(1:120)), axis([0 120 -2 2])   % Original signal
%   title('Original Signal')
%   subplot(1,2,2);
%   stem(y(1:30))                        % Decimated signal
%   title('Decimated Signal')
%
%   See also DOWNSAMPLE, INTERP, RESAMPLE, FILTFILT, FIR1, CHEBY1.

%   Author(s): L. Shure, 6-4-87
%              L. Shure, 12-11-88, revised
%   Copyright 1988-2010 The MathWorks, Inc.

%   References:
%    [1] "Programs for Digital Signal Processing", IEEE Press
%         John Wiley & Sons, 1979, Chap. 8.3.

narginchk(2,4);
error(nargoutchk(0,1,nargout,'struct'));

% Validate required inputs 
validateinput(idata,r);

if fix(r) == 1
    odata = idata;
    return
end

fopt = 1;
if nargin == 2
    nfilt = 8;
else
  if nargin == 4
    if option(1) == 'f' || option(1) == 'F'
      fopt = 0;
    elseif option(1) == 'i' || option(1) == 'I'
      fopt = 1;
    else
      error(message('signal:decimate:InvalidEnum'))
    end
  end
end
if fopt == 1 && nfilt > 13
    warning(message('signal:decimate:highorderIIRs'));
end

nd = size(idata,1);
nout = ceil(nd/r);

rip = .05;	% passband ripple in dB
[b,a] = cheby1(nfilt, rip, .8/r);
while all(b==0) || (abs(filtmag_db(b,a,.8/r)+rip)>1e-6)
  nfilt = nfilt - 1;
  if nfilt == 0
    break
  end
  [b,a] = cheby1(nfilt, rip, .8/r);
end
if nfilt == 0
  error(message('signal:decimate:InvalidRange'))
end

% be sure to filter in both directions to make sure the filtered data has zero phase
% make a data vector properly pre- and ap- pended to filter forwards and back
% so end effects can be obliterated.
odata = filtfilt(b,a,idata);
nbeg = r - (r*nout - nd);
odata = odata(nbeg:r:nd,:,:);

%--------------------------------------------------------------------------
function H = filtmag_db(b,a,f)
%FILTMAG_DB Find filter's magnitude response in decibels at given frequency.

nb = length(b);
na = length(a);
top = exp(-1i*(0:nb-1)*pi*f)*b(:);
bot = exp(-1i*(0:na-1)*pi*f)*a(:);

H = 20*log10(abs(top/bot));

%--------------------------------------------------------------------------
function validateinput(x,r)
% Validate 1st two input args: signal and decimation factor

if isempty(x) || issparse(x) || ~isa(x,'double'),
    error(message('signal:decimate:invalidInput', 'X'));
end

if (abs(r-fix(r)) > eps) || (r <= 0)
    error(message('signal:decimate:invalidR', 'R'));
end

