
# coding: utf-8

# In[ ]:
#check comments on lines 51/52 (numDay) and 78 (components)
# import data
import numpy as np
import json

with open('data/pyData/2705/2705_Data_S_Notch14_1_0.json') as f:
    data = json.load(f)
    pxx0 = np.array(data[0])
    label0 = data[1]
with open('data/pyData/2705/2705_Data_S_Notch14_1_1.json') as f:
    data = json.load(f)
    pxx1 = np.array(data[0])
    label1 = data[1]
with open('data/pyData/2705/2705_Data_S_Notch14_1_2.json') as f:
    data = json.load(f)
    pxx2 = np.array(data[0])
    label2 = data[1]
    
pxx = np.concatenate([pxx0, pxx1, pxx2], axis = 2)

newlabel = dict.fromkeys(label0.keys())
labelKey = list(label0.keys())
labelKey.remove('allWindows')
allkey = list(label0['allWindows'].keys())
for k in range(0, len(labelKey)):
    newlabel[labelKey[k]] = label0[labelKey[k]]

newlabel['allWindows'] = dict.fromkeys(label0['allWindows'].keys())

for k in range(0, len(allkey)):
    newlabel['allWindows'][allkey[k]] = label0['allWindows'][allkey[k]]
    newlabel['allWindows'][allkey[k]].extend(label1['allWindows'][allkey[k]])
    newlabel['allWindows'][allkey[k]].extend(label2['allWindows'][allkey[k]])

pxx = np.log(pxx)
a, b, c = pxx.shape
XS = pxx.reshape(a*b, c).T
S_labels = newlabel

# Train data ONLY on standard experiments from day 1: X, S_labels where subject contains 1
# stimON = 1 vs nonstim = 0 (baseline AND stimOFF)

days = np.zeros(len(S_labels['allWindows']['subject']))
for k in range(0, len(S_labels['allWindows']['subject'])):
    days[k] = int(S_labels['allWindows']['subject'][k][6])-1

numDay = int(np.ceil(max(days)))+1
numDay = int(4)
duration = 539
    
X_arr = np.zeros((numDay, duration), dtype = int)
Y_arr = np.zeros((numDay, duration), dtype = int)
    
for k in range(0, len(S_labels['allWindows']['subject'])):
    d = int(S_labels['allWindows']['subject'][k][6])-1
    w = S_labels['allWindows']['windowID'][k]-1
    if w < duration and d < numDay: 
        X_arr[d, w] = k
        Y_arr[d, w] = S_labels['allWindows']['stimOn'][k]

X_list = X_arr.reshape(numDay*duration, 1)
Y_list = Y_arr.reshape(numDay*duration, 1)

X_all = XS
Y_all = np.array(S_labels['allWindows']['stimOn'])



from sklearn.decomposition import FastICA
from sklearn import svm
from sklearn.model_selection import KFold, StratifiedKFold
from sklearn.metrics import roc_curve, auc

components = np.logspace(1, 2, 2, dtype = int) #np.logspace(1, 2.7783, 15, dtype = int)

roc_auc = np.zeros((numDay, (numDay-1), len(components)))
best = np.zeros((numDay, 2))
#testID = np.arange(0, Y_all.shape[0], dtype = 'int')

outer_cv = KFold(n_splits = numDay, shuffle = True)
inner_cv = KFold(n_splits = (numDay-1), shuffle = True)
t = 0

for subtrain, test in outer_cv.split(range(0, numDay)):
    v = 0
    for train, validate in inner_cv.split(subtrain):
        c = 0
        X_inner_trainingset = X_all[X_arr[subtrain[train], ].reshape((numDay-2)*duration), ]
        Y_inner_trainingset = Y_arr[subtrain[train], ].reshape((numDay-2)*duration)
        X_validate = X_all[X_arr[subtrain[validate], ], ].reshape(duration, 600)
        Y_validate = Y_all[X_arr[subtrain[validate]]].reshape(duration)

        for C in components:   
            print(test, subtrain[validate], subtrain[train], C)
            
            ica = FastICA(n_components = C, max_iter = 5000,tol = 0.0001) #tol = 0.001
            X_inner_train = ica.fit_transform(X_inner_trainingset) #pull components from ica fit transformation
            X_inner_test = ica.transform(X_validate)
            
            clf = svm.SVC(kernel = 'linear', class_weight = 'balanced', probability = True)
            y_inner_score = clf.fit(X_inner_train, Y_inner_trainingset).decision_function(X_inner_test)
            fpr, tpr, _ = roc_curve(Y_validate, y_inner_score)
            roc_auc[t, v, c] = auc(fpr, tpr)

            c += 1
        v += 1
    
    best[t, 0] = int(np.argmax(np.mean(roc_auc[t, :, :], axis = 0)))
    print('Best components | %0.0f' % (components[int(best[t, 0])]))
    
    X_outer_trainingset = X_all[X_arr[subtrain, ].reshape((numDay-1)*duration), ]
    Y_outer_trainingset = Y_arr[subtrain, ].reshape((numDay-1)*duration)
    X_test = X_all[X_arr[test, ], ].reshape(duration, 600)
    Y_test = Y_all[X_arr[test]].reshape(duration)
    
    
    ica = FastICA(n_components = components[int(best[t, 0])], max_iter = 5000,tol = 0.0001) #tol = 0.001
    X_outer_train = ica.fit_transform(X_outer_trainingset) #pull components from ica fit transformation
    X_outer_test = ica.transform(X_test)
    
    clf = svm.SVC(kernel = 'linear', class_weight = 'balanced', probability = True)
    y_outer_score = clf.fit(X_outer_train, Y_outer_trainingset).decision_function(X_outer_test)
    fpr, tpr, _ = roc_curve(Y_test, y_outer_score)
    best[t, 1] = auc(fpr, tpr)
    print('8x1 ROC AUC | %0.2f' % (best[t, 1]*100))
    t += 1

for i in range(0,numDay): best[i, 0] = components[int(best[i, 0])]
    
np.savetxt('nestedROC_AUC.txt', roc_auc.reshape(numDay*(numDay-1),len(components)), delimiter='\t')
np.savetxt('nestedTestROC_AUC.txt', best, delimiter='\t')