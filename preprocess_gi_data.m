function preprocess_gi_data(saveFile,dataOpts,notch14)
% preprocessData
%   Preprocesses data saved in saveFile 3.16.2018 add 14Hz notch filter.
%   INPUTS
%   saveFile: name of '.mat' file containing the data and labels
%       variables. And to which the fully preprocessed data will be saved
%   dataOpts: optional input. see description in saved variables section
%   LOADED VARIABLES
%   rawData: Cell array of length P. Each cell contains an MxN array of 
%       contiguously recorded data. M is the # of time points in a recording. N
%       is the # of channels. P is the # of disjoint recording segments. All
%       elements corresponding to data that was not saved (i.e. missing channel)
%       should be marked with NaNs.
%   rawWindowTimes: Cell array of length P. Each cell contains a 2xW array of
%       start and end times for windows associated with segment P in rawData. W
%       is the # of windows in segment P.
%   labels: Structure containing labeling infomation for data
%       FIELDS
%       channel: cell arrays of names for channels
%       channelArea: cell array w/ same size as channel giving area
%           assignment for each channel
%       fsRaw: sampling frequency of unprocessed data (Hz)
%       windowLength: length of data windows in seconds
%       allWindows: structure containing relevant labels pertaining to
%           individual windows. Suggested fields: date, etc. Must
%           contain 'subject' field.
%   SAVED VARIABLES
%   labels: see above
%       ADDED FIELDS
%       fs: sampling frequency of processed data (Hz)
%   dataOpts: Data preprocessing options.
%       FIELDS
%       highFreq/lowFreq: boundaries of frequencies considered by
%           the model
%       subSampFact: subsampling factor
%       normalize: string indicating how to normalize data. 'none' indicates
%           that data should not be normalized. 'segments' indicates to
%           normalize (z-score) over contiguous segments of the data.
%   dataSegments: preprocessed data. Same format as rawData. Cell array of
%       length P. Each cell contains an MxN array of contiguously recorded data.
%       M is the # of time points in a recording. N is the # of channels. P is
%       the # of disjoint recording segments.
%   windowTimes: Cell array of length P. Each cell contains a 2xW array of
%       start and end times for windows associated with segment P in
%       dataSegments. W is the # of windows in segment P.

if nargin < 2
  % input/data preprocessing parameters
  dataOpts = [];
  notch14 = true;
elseif nargin < 3
    notch14 = true;
end
dataOpts = fillDefaultDopts(dataOpts);

load(saveFile, 'labels', 'rawData', 'rawWindowTimes')

%initialize some variables
fs = labels.fsRaw;
sampsPerWindow = labels.windowLength * fs;
nSegments = numel(rawData);

% calculate subsampling info
if mod(fs,dataOpts.subSampFact)
  error('Subsampling factor is not a factor of sampling frequency.')
end
ptsPerWindow = floor(sampsPerWindow/dataOpts.subSampFact);
fsFinal = fs/dataOpts.subSampFact;
if ptsPerWindow < 2*dataOpts.highFreq
  warning('Data subsampled too low to retain desired high frequency information.')
end

%% Preprocessing

dataSegments = cell(nSegments,1);
windowTimes = cell(nSegments,1);
for d = 1:nSegments
  thisData = rawData{d};

  % 60Hz notch filters (+harmonics)
  xNotchFiltered = double(thisData);
  for f = 60:60:dataOpts.highFreq
    Wp = [(f-1) (f+1)]*2/fs; % passband
    Ws = [(f-0.25) (f+0.25)]*2/fs; % stopband
    Rp = 0.5; % Max Passband distortion
    Rs = 30; % Min stopband attenuation
    [n,Wn] = buttord(Wp,Ws,Rp,Rs);
    [z,p,k] =  butter(n,Wn,'stop');
    [sos,g] = zp2sos(z,p,k);
    xNotchFiltered = filtfilt(sos,g,xNotchFiltered);
  end
  
  if notch14
        % 14Hz notch filters (+harmonics)
      xNotchFiltered = double(thisData);
      for f = 14:14:dataOpts.highFreq
        Wp = [(f-1) (f+1)]*2/fs; % passband
        Ws = [(f-0.25) (f+0.25)]*2/fs; % stopband
        Rp = 0.5; % Max Passband distortion
        Rs = 30; % Min stopband attenuation
        [n,Wn] = buttord(Wp,Ws,Rp,Rs);
        [z,p,k] =  butter(n,Wn,'stop');
        [sos,g] = zp2sos(z,p,k);
        xNotchFiltered = filtfilt(sos,g,xNotchFiltered);
      end
  end
  
  % subsample (using custom function based off 'decimate')
  xSubsampled = decimateiir(xNotchFiltered,dataOpts.subSampFact);
  windowTimes{d} = ceil(rawWindowTimes{d} ./ dataOpts.subSampFact);
                                  
  if strcmp(dataOpts.normalize, 'segments')
    dataSegments{d} = zscore(xSubsampled);
  elseif ~strcmp(dataOpts.normalize, 'none')
    warning(['Value in dataOpts.normalize not recognized:'...
      'Data will not be normalized'])
  end
end

% update labels
labels.fs = fsFinal;
save(saveFile, 'dataSegments', 'dataOpts', 'labels', 'windowTimes', '-append')
end

function dataOpts = fillDefaultDopts(dataOpts)
% fill in default data options
if ~isfield(dataOpts,'subSampFact'), dataOpts.subSampFact = 20; end
if ~isfield(dataOpts,'normalize'), dataOpts.normalize = 'segments'; end
if ~isfield(dataOpts,'lowFreq'), dataOpts.lowFreq = 0.1; end
if ~isfield(dataOpts,'highFreq'), dataOpts.highFreq = 30; end
end
