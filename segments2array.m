function [data] = segments2array(dataSegments, windowTimes)
% Convert data from being stored as contiguous segments to as 3-D array of
% windows

% accumulate windows from all segments into array
data = [];
for s = 1:numel(dataSegments)
  
  theseTimes = windowTimes{s};
  W = size(theseTimes, 2);

  % save each window
  for w = 1:W
    thisWindow = dataSegments{s}(theseTimes(1,w):theseTimes(2,w),:);
    data = cat(3, data, thisWindow);
  end
  
end
end

