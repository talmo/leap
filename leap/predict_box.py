import h5py
import numpy as np
import os
from time import time
import keras
import keras.models
from keras.layers import Lambda
import tensorflow as tf
import re
from clize import run

from .utils import find_weights, find_best_weights, preprocess    
from .layers import Maxima2D

def tf_find_peaks(x):
    """ Finds the maximum value in each channel and returns the location and value.
    Args:
        x: rank-4 tensor (samples, height, width, channels)
        
    Returns:
        peaks: rank-3 tensor (samples, [x, y, val], channels)
    """
    
    # Store input shape
    in_shape = tf.shape(x)
    
    # Flatten height/width dims
    flattened = tf.reshape(x, [in_shape[0], -1, in_shape[-1]])
    
    # Find peaks in linear indices
    idx = tf.argmax(flattened, axis=1)
    
    # Convert linear indices to subscripts
    rows = tf.floor_div(tf.cast(idx,tf.int32), in_shape[1])
    cols = tf.floormod(tf.cast(idx,tf.int32), in_shape[1])
    
    # Dumb way to get actual values without indexing
    vals = tf.reduce_max(flattened, axis=1)
    
    # Return N x 3 x C tensor
    return tf.stack([
        tf.cast(cols, tf.float32),
        tf.cast(rows, tf.float32),
        vals
    ], axis=1)


def convert_to_peak_outputs(model, include_confmaps=False):
    """ Creates a new Keras model with a wrapper to yield channel peaks from rank-4 tensors. """
    if type(model.output) == list:
        confmaps = model.output[-1]
    else:
        confmaps = model.output
    
    if include_confmaps:
        return keras.Model(model.input, [Lambda(tf_find_peaks)(confmaps), confmaps])
    else:
        # return keras.Model(model.input, Lambda(tf_find_peaks)(confmaps))
        return keras.Model(model.input, Maxima2D()(confmaps))


def predict_box(box_path, model_path, out_path, *, box_dset="/box", epoch=None, verbose=True, overwrite=False, save_confmaps=False):
    """
    Predict and save peak coordinates for a box. 

    :param box_path: path to HDF5 file with box dataset
    :param model_path: path to Keras weights file or run folder with weights subfolder
    :param out_path: path to HDF5 file to save results to
    :param box_dset: name of HDF5 dataset containing box images
    :param epoch: epoch to use if run folder provided instead of Keras weights file
    :param verbose: if True, prints some info and statistics during procesing
    :param overwrite: if True and out_path exists, file will be overwritten
    :param save_confmaps: if True, saves the full confidence maps as additional datasets in the output file (very slow)
    """
    
    if verbose:
        print("model_path:", model_path)
        
    # Find model weights
    model_name = None
    weights_path = model_path
    if os.path.isdir(model_path):
        model_name = os.path.basename(model_path)
        
        weights_paths, epochs, val_losses = find_weights(model_path)
        
        if epoch == None and len(val_losses) > 0:
            weights_path = weights_paths[np.argmin(val_losses)]
        elif epoch == "final" or (epoch == None and len(val_losses) == 0):
            weights_path = os.path.join(model_path, "final_model.h5")
        else:
            weights_path = weights_paths[epoch]
    
    # Input data
    box = h5py.File(box_path,"r")[box_dset]
    num_samples = box.shape[0]
    if verbose:
        print("Input:", box_path)
        print("box.shape:", box.shape)

    # Create output path
    if out_path[-3:] != ".h5":
        if model_name == None:
            out_path = os.path.join(out_path, os.path.basename(box_path))
        else:
            out_path = os.path.join(out_path, model_name, os.path.basename(box_path))
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
    
    model_name = os.path.basename(model_path)

    if verbose:
        print("Output:", out_path)
    
    t0_all = time()
    if os.path.exists(out_path):
        if overwrite:
            os.remove(out_path)
            print("Deleted existing output.")
        else:
            print("Error: Output path already exists.")
            return

    # Load and prepare model
    model = keras.models.load_model(weights_path)
    model_peaks = convert_to_peak_outputs(model, include_confmaps=save_confmaps)
    if verbose:
        print("weights_path:", weights_path)
        print("Loaded model: %d layers, %d params" % (len(model.layers), model.count_params()))
        
    # Load data and preprocess (normalize)
    t0 = time()
    X = preprocess(box[:])
    if verbose:
        print("Loaded [%.1fs]" % (time() - t0))
    
    # Evaluate
    t0 = time()
    if save_confmaps:
        Ypk, confmaps = model_peaks.predict(X)
        
        # Quantize
        confmaps_min = confmaps.min()
        confmaps_max = confmaps.max()
        confmaps = (confmaps - confmaps_min) / (confmaps_max - confmaps_min)
        confmaps = (confmaps * 255).astype('uint8')

        # Reshape
        confmaps = np.transpose(confmaps, (0, 3, 2, 1))
    else:
        Ypk = model_peaks.predict(X)
    prediction_runtime = time() - t0
    if verbose:
        print("Predicted [%.1fs]" % prediction_runtime)
        print("Prediction performance: %.3f FPS" % (num_samples / prediction_runtime))
    
    # Save
    t0 = time()
    with h5py.File(out_path, "w") as f:
        f.attrs["num_samples"] = num_samples
        f.attrs["img_size"] = X.shape[1:]
        f.attrs["box_path"] = box_path
        f.attrs["box_dset"] = box_dset
        f.attrs["model_path"] = model_path
        f.attrs["weights_path"] = weights_path
        f.attrs["model_name"] = model_name

        ds_pos = f.create_dataset("positions_pred", data=Ypk[:,:2,:].astype("int32"), compression="gzip", compression_opts=1)
        ds_pos.attrs["description"] = "coordinate of peak at each sample"
        ds_pos.attrs["dims"] = "(sample, [x, y], joint) === (sample, [column, row], joint)"

        ds_conf = f.create_dataset("conf_pred", data=Ypk[:,2,:].squeeze(), compression="gzip", compression_opts=1)
        ds_conf.attrs["description"] = "confidence map value in [0, 1.0] at peak"
        ds_conf.attrs["dims"] = "(sample, joint)"

        if save_confmaps:
            ds_confmaps = f.create_dataset("confmaps", data=confmaps, compression="gzip", compression_opts=1)
            ds_confmaps.attrs["description"] = "confidence maps"
            ds_confmaps.attrs["dims"] = "(sample, channel, width, height)"
            ds_confmaps.attrs["range_min"] = confmaps_min
            ds_confmaps.attrs["range_max"] = confmaps_max

        total_runtime = time() - t0_all
        f.attrs["total_runtime_secs"] = total_runtime
        f.attrs["prediction_runtime_secs"] = prediction_runtime
    
    if verbose:
        print("Saved [%.1fs]" % (time() - t0))

        print("Total runtime: %.1f mins" % (total_runtime / 60))
        print("Total performance: %.3f FPS" % (num_samples / total_runtime))
        
        
if __name__ == "__main__":
    run(predict_box)