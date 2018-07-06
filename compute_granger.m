% estimate power spectra
SAVEFILE = 'data/giData.mat';
FREQS_PER_DECADE = 10;

load(SAVEFILE, 'dataSegments', 'labels', 'dataOpts', 'windowTimes')

% evaluate at every 0.1Hz up to nyquist
fs = labels.fs;
f = 0.1:0.1:floor(10*fs/2)/10;
nFreq = numel(f);

data = segments2array(dataSegments, windowTimes);

fprintf('Ignore following warnings \n')
run('mvgc/startup.m')
gcArray = g_causality( data, fs, nFreq );

labels.f = f;

save(SAVEFILE, 'gcArray', 'labels', '-append')
