% estimate power spectra
SAVEFILE = 'data/giData.mat';
FREQS_PER_DECADE = 10;

load(SAVEFILE, 'dataSegments', 'labels', 'dataOpts', 'windowTimes')

logLow = log10(dataOpts.lowFreq); logHigh = log10(dataOpts.highFreq);
nFreqs = ceil((logHigh - logLow) * FREQS_PER_DECADE);
f = logspace(logLow, logHigh, nFreqs);

data = segments2array(dataSegments, windowTimes);

[A,B,C] = size(data);
xReshaped = reshape(data, A, B*C);
[pxx, f] = pwelch(xReshaped, round(A / 5), [], f, labels.fs, 'power');
labels.f = f;
pxx = reshape(pxx, [], B, C);

save(SAVEFILE, 'pxx', 'labels', '-append')