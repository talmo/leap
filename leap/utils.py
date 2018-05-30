import os
import numpy as np
import re
from time import time
import h5py

def versions():
    """ Prints version strings for finicky libraries. """
    import keras
    import tensorflow as tf
    import h5py

    print("Keras:", str(keras.__version__))
    print("Tensorflow:", str(tf.__version__))
    print("h5py:\n", h5py.version.info)
    print("numpy:",np.version.full_version)


def find_weights(model_path):
    """ Returns paths to saved weights in the run's subfolder.  """
    weights_folder = os.path.join(model_path, "weights")
    weights_paths = sorted(os.listdir(weights_folder))
    weights_paths = [x for x in weights_paths if "weights" in x]
    matches = [re.match("weights[.]([0-9]+)-([0-9.]+)[.]h5", x).groups() for x in weights_paths]
    epochs = np.array([int(x[0]) for x in matches])
    val_losses = np.array([np.float(x[1]) for x in matches])
    
    weights_paths = [os.path.join(weights_folder, x) for x in weights_paths]
    return weights_paths, epochs, val_losses


def find_best_weights(model_path):
    """ Returns the path to the model weights with the lowest validation loss. """
    weights_paths, epochs, val_losses = find_weights(model_path)
    if len(val_losses) > 0:
        idx = np.argmin(val_losses)
        return weights_paths[idx]
    else:
        return None


def load_dataset(data_path, X_dset="box", Y_dset="confmaps", permute=(0,3,2,1)):
    """ Loads and normalizes datasets. """
    
    # Load
    t0 = time()
    with h5py.File(data_path,"r") as f:
        X = f[X_dset][:]
        Y = f[Y_dset][:]
    print("Loaded %d samples [%.1fs]" % (len(X), time() - t0))
    
    # Adjust dimensions
    t0 = time()
    X = preprocess(X, permute)
    Y = preprocess(Y, permute)
    print("Permuted and normalized data. [%.1fs]" % (time() - t0))
    
    return X, Y

def preprocess(X, permute=(0,3,2,1)):
    """ Normalizes input data. """
    
    # Add singleton dim for single images
    if X.ndim == 3:
        X = X[None,...]
    
    # Adjust dimensions
    X = np.transpose(X, permute)
    
    # Normalize
    if X.dtype == "uint8":
        X = X.astype("float32") / 255
    
    return X