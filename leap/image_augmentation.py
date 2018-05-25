import cv2
import numpy as np
import keras
from keras.utils import Sequence

def transform_imgs(X, theta=(-180,180), scale=1.0):
    """ Transforms sets of images with the same random transformation across each channel. """
    
    # Sample random rotation and scale if range specified
    if not np.isscalar(theta):
        theta = np.ptp(theta) * np.random.rand() + np.min(theta)
    if not np.isscalar(scale):
        scale = np.ptp(scale) * np.random.rand() + np.min(scale)
    
    # Standardize X input to a list
    single_img = type(X) == np.ndarray
    if single_img:
        X = [X,]
    
    # Find image parameters
    img_size = X[0].shape[:2]
    ctr = (img_size[0] / 2, img_size[0] / 2)
    
    # Compute affine transformation matrix
    T = cv2.getRotationMatrix2D(ctr, theta, scale)
    
    # Make sure we don't overwrite the inputs
    X = [x.copy() for x in X]
    
    # Apply to each image
    for i in range(len(X)):
        if X[i].ndim == 2:
            # Single channel image
            X[i] = cv2.warpAffine(X[i], T, img_size)
        else:
            # Multi-channel image
            for c in range(X[i].shape[-1]):
                X[i][...,c] = cv2.warpAffine(X[i][...,c], T, img_size)
    
    # Pull the single image back out of the list
    if single_img:
        X = X[0]
    
    return X


class PairedImageAugmenter(Sequence):
    def __init__(self, X, Y, batch_size=32, shuffle=False, theta=(-180,180), scale=1.0):
        self.X = X
        self.Y = Y
        self.batch_size = batch_size
        self.theta = theta
        self.scale = scale
        
        self.num_samples = len(X)
        all_idx = np.arange(self.num_samples)
        if shuffle:
            np.random.shuffle(all_idx)
        
        self.batches = np.array_split(all_idx, np.ceil(self.num_samples / self.batch_size))
        
    def __len__(self):
        return len(self.batches)
    
    def __getitem__(self, batch_idx):
        idx = self.batches[batch_idx]
        X = self.X[idx]
        Y = self.Y[idx]
        
        for i in range(len(X)):
            X[i], Y[i] = transform_imgs((X[i],Y[i]), theta=self.theta, scale=self.scale)
        return X, Y

    
class MultiInputOutputPairedImageAugmenter(PairedImageAugmenter):
    def __init__(self, input_names, output_names, *args, **kwargs):
        if type(input_names) != list:
            input_names = [input_names,]
        if type(output_names) != list:
            output_names = [output_names,]
        self.input_names = input_names
        self.output_names = output_names
        super().__init__(*args, **kwargs)
        
    def __getitem__(self, batch_idx):
        X,Y = super().__getitem__(batch_idx)
        return ({k: X for k in self.input_names}, {k: Y for k in self.output_names})
    