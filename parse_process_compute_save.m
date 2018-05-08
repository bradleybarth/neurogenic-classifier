function parse_process_compute_save(ID, notch14)
% master executable to run all MATLAB processes
% ID refers to specimen number (Rat_ID), and notch14 is a boolean to apply 
% a notch filter at 14 Hz, or not

lbl = {'S','L','C'};
for i = 1:3
    parse_gi_data(ID, lbl{i})
    disp([lbl{i},': parsed '])
    preprocess_gi_data(notch14)
    disp([lbl{i},': preprocessed '])
    compute_spectra
    disp([lbl{i},': spectra computed '])
    name = [num2str(ID), '_Data_', lbl{i}, '_Notch14_', num2str(notch14)];
    disp(name)
    save2Py(name)
    disp([lbl{i},': saved '])
end