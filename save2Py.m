function save2Py(name)

LOADFILE = 'data/giData.mat';
SAVEFILE = ['data/pyData/',name,'.json'];

load(LOADFILE, 'pxx', 'labels', 'dataOpts')

data = jsonencode({pxx, labels});

filename = sprintf(SAVEFILE);
fID = fopen(filename,'w+');
fprintf(fID,'%s',data); 
