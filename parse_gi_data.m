% parse GI recordings into a nice format and save
clear, clc

% Constants
CHANS = [3 4 5 7 8 9 10 11 12 13 14 15 17 18 19 20 21 22 23 24 25 27 28 29];
REF = [1 2];
LOAD_FOLDER = {'./Data/RatID_2705/ID.2705 1_9/standard_d1/' './Data/RatID_2705/ID.2705 1_9/standard_d2/' ...
  './Data/RatID_2705/ID.2705 1_9/standard_d3/' './Data/RatID_2705/ID.2705 1_9/standard_d4/' './Data/RatID_2705/ID.2705 1_9/standard_d5/' ...
  './Data/RatID_2705/ID.2705 1_9/standard_d6/' './Data/RatID_2705/ID.2705 1_9/standard_d7/' './Data/RatID_2705/ID.2705 1_9/standard_d8/' ...
  './Data/RatID_2705/ID.2705 1_9/standard_d9/'};
% LOAD_FOLDER = {'./Data/RatID_2705/ID.2705 1_9/lidocaineSNS_1/' './Data/RatID_2705/ID.2705 1_9/lidocaineSNS_2/' ...
%   './Data/RatID_2705/ID.2705 1_9/lidocaineSNS_3/' './Data/RatID_2705/ID.2705 1_9/lidocaineSham_1/' ...
%   './Data/RatID_2705/ID.2705 1_9/lidocaineSham_2/' './Data/RatID_2705/ID.2705 1_9/lidocaineSham_3/'};
% LOAD_FOLDER = {'./Data/RatID_2705/ID.2705 1_9/atropine_1/' './Data/RatID_2705/ID.2705 1_9/atropine_2/' ...
% './Data/RatID_2705/ID.2705 1_9/atropine_3/' './Data/RatID_2705/ID.2705 1_9/hexamethonium_1/' ...
% './Data/RatID_2705/ID.2705 1_9/hexamethonium_2/' './Data/RatID_2705/ID.2705 1_9/hexamethonium_3/'};
SAVEFILE = 'data/giData.mat';
WINDOW_DURATION = 10; % seconds
BASELINE_TIME = 30; % minutes
CONDITION_TIME = 15; % minutes
% After baseline, 15 min stim on, followd by 15 min off. On-off
% then repeated a second time. 

rawData = {};
rawWindowTimes = {};

for f = 1:numel(LOAD_FOLDER)
  thisFolder = LOAD_FOLDER{f};
  folderContents = dir(thisFolder);
  segmentsProcessed = numel(rawData);
  nProcessed = 0;
  initLoopVars = true;
  K = length(folderContents);
  for k = 1:K
    filename = folderContents(k).name;
    segmentIdx = segmentsProcessed + k;
    
    % skip undesired files
    if ~contains(filename, '.rhd'), continue, end
    
    % load data
    [loadedData, time, fs] = ...
      read_Intan_RHD2000_file_inline(filename, thisFolder);
    
    % subtract common reference
    thisData = loadedData(CHANS, :);
    reference = mean(loadedData(REF, :));
    thisData = bsxfun(@minus, thisData, reference);
    
    if initLoopVars
      % initialize variables to be filled over loop iterations
      if ~segmentsProcessed
        labels.windowLength = WINDOW_DURATION;
        labels.fsRaw = fs;
        labels.channel = cellstr(string(CHANS));
        labels.channelArea = labels.channel;
        labels.allWindows.subject = {};
        labels.allWindows.baseline = [];
        labels.allWindows.stimOn = [];
        labels.allWindows.stimOff = [];
        labels.allWindows.windowID = [];
      end
      
      rawData = [rawData; cell(K, 1)];
      rawWindowTimes = [rawWindowTimes; cell(K, 1)];
      initLoopVars = false;
    end
    
    % segment into time windows
    [C,nSamples] = size(thisData);
    N = labels.fsRaw * labels.windowLength;
    W = floor(nSamples ./ N);
    rawData{segmentIdx} = thisData';
    
    % add window start & end points to labels
    windowStarts = 1 : N : (W-1) * N + 1;
    windowEnds = N : N : W * N;
    rawWindowTimes{segmentIdx} = [windowStarts; windowEnds];
    
    % add condition to labels
    sampsPerMin = 60 * fs;
    stim1Start = BASELINE_TIME * sampsPerMin;
    stim1End = (BASELINE_TIME + CONDITION_TIME) * sampsPerMin;
    stim2Start = (BASELINE_TIME + 2*CONDITION_TIME) * sampsPerMin;
    stim2End = (BASELINE_TIME + 3*CONDITION_TIME) * sampsPerMin;
    windowEnds = windowEnds + nProcessed;
    isBaseline = windowEnds < stim1Start;
    stimOn = ((windowEnds > stim1Start) & (windowEnds < stim1End)) | ...
             ((windowEnds > stim2Start) & (windowEnds < stim2End));
    stimOff = ((windowEnds > stim1End) & (windowEnds < stim2Start)) | ...
             (windowEnds > stim2End);
    labels.allWindows.baseline = [labels.allWindows.baseline; ...
                        isBaseline'];
    labels.allWindows.stimOn = [labels.allWindows.stimOn; ...
                        stimOn'];
    labels.allWindows.stimOff = [labels.allWindows.stimOff; ...
                        stimOff'];
    labels.allWindows.windowID = [labels.allWindows.windowID; ...
                        ((1:W)+(k-3)*6)'];
    disp([f 99 ((1:W)+(k-3)*6)])
    
    % add subject name to labels
    subjectID = cell(W, 1);
    name=find(LOAD_FOLDER{f}=='/',2,'last');
    subjectID(:) = {strcat('Rat_',LOAD_FOLDER{f}([name(1)+1 name(2)-3 name(2)-1]))};
    labels.allWindows.subject = [labels.allWindows.subject; subjectID];
    
    nProcessed = nProcessed + nSamples;
  end
end

% remove empty cells
emptyCells = cellfun('isempty', rawData);
rawData(emptyCells) = [];
rawWindowTimes(emptyCells) = [];

save(SAVEFILE, 'rawData', 'rawWindowTimes', 'labels', '-v7.3')