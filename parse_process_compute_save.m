function parse_process_compute_save(ID, experimentSet, notch14)
% master executable to run all MATLAB processes
% ID refers to specimen number (Rat_ID), and experiment set is a string to 
% determine which experiments to process - S: standard, L: lidocaine, C: 
% cholinergic blockers. notch14 is a boolean to apply a notch filter at 14
% Hz, or not

parse_gi_data(ID, experimentSet)
preprocess_gi_data(SAVEFILE, notch14)
compute_spectra
lbl = {'S','L','C'};
expSet = [];
for i = 1:3
  if max(lbl{i} == experimentSet)
    expSet = [expSet lbl{i}];
  end
end
name = [num2str(ID), '_Data_', expSet, '_Notch14_', num2str(notch14)];
disp(name)
save2Py(name)