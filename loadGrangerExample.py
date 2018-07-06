import json
import numpy as np

def loadGrangerFeatures(loadstring, IDnumber, fBounds=(0.1,30)):

    # the granger toolbox in matlab doesn't allow easy selection of the frequency range to be computed, so we have to select that here
    (fLow, fHigh) = fBounds

    with open(loadstring.format(IDnumber, IDnumber)) as f:
        data = json.load(f)
    gcArray = np.array(data[0])
    labels = data[1]
    
    gcArray = np.swapaxes(gcArray, 0,3)
    gcArray = np.swapaxes(gcArray, 1,2)
    
    # only take desired frequencies, skipping DC component
    fIdx = [k+1 for (k, f) in enumerate(labels['f']) if fLow <= f <= fHigh]
    gcArray = gcArray[:,:, fIdx, :]
    
    # take off-diagonal components of gcArray to not include self-causality
    r1, c1 = np.triu_indices( gcArray.shape[0], k=1)
    r2, c2 = np.tril_indices( gcArray.shape[0], k=-1)
    # concatenate window/freq information for relevant brain pairs
    gcFeatures = np.concatenate((gcArray[r1,c1,:,:], gcArray[r2,c2,:,:]))
    # reshape features
    gcFeatures = np.swapaxes( gcFeatures, 0, 1 )
    a, b, c = gcFeatures.shape
    gcFeatures = gcFeatures.reshape(a*b, c).T

    return (gcFeatures, labels)