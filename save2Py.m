LOADFILE = 'data/giData.mat';
SAVEFILE = 'data/pyData/notch14Data_C.json';

load(LOADFILE, 'pxx', 'labels', 'dataOpts')

data = jsonencode({pxx, labels});

filename = sprintf(SAVEFILE);
fID = fopen(filename,'w+');
fprintf(fID,'%s',data); 