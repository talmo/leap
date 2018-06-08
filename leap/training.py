import numpy as np
import h5py
import os
from time import time
from scipy.io import loadmat, savemat
import re
import shutil
import clize

import keras
from keras.callbacks import ReduceLROnPlateau, ModelCheckpoint, LambdaCallback

try:
    from . import models
    from .image_augmentation import PairedImageAugmenter, MultiInputOutputPairedImageAugmenter
    from .viz import show_pred, show_confmap_grid, plot_history
except:
    import models
    from image_augmentation import PairedImageAugmenter, MultiInputOutputPairedImageAugmenter
    from viz import show_pred, show_confmap_grid, plot_history
    from utils import load_dataset

def train_val_split(X, Y, val_size=0.15, shuffle=True):
    """ Splits datasets into training and validation sets. """
    
    if val_size < 1:
        val_size = int(np.round(len(X) * val_size))
        
    idx = np.arange(len(X))
    if shuffle:
        np.random.shuffle(idx)
    
    val_idx = idx[:val_size]
    idx = idx[val_size:]
    
    return X[idx], Y[idx], X[val_idx], Y[val_idx], idx, val_idx


def create_run_folders(run_name, base_path="models", clean=False):
    """ Creates subfolders necessary for outputs of training. """
    
    def is_empty_run(run_path):
        weights_path = os.path.join(run_path, "weights")
        has_weights_folder = os.path.exists(weights_path)
        return not has_weights_folder or len(os.listdir(weights_path)) == 0
    
    run_path = os.path.join(base_path, run_name)
    
    if not clean:
        initial_run_path = run_path
        i = 1
        while os.path.exists(run_path): #and not is_empty_run(run_path):
            run_path = "%s_%02d" % (initial_run_path, i)
            i += 1
            
    if os.path.exists(run_path):
        shutil.rmtree(run_path)
        
    os.makedirs(run_path)
    os.makedirs(os.path.join(run_path, "weights"))
    os.makedirs(os.path.join(run_path, "viz_pred"))
    os.makedirs(os.path.join(run_path, "viz_confmaps"))
    print("Created folder:", run_path)
    
    return run_path



class LossHistory(keras.callbacks.Callback):
    def __init__(self, run_path):
        super().__init__()
        self.run_path = run_path
    
    def on_train_begin(self, logs={}):
        self.history = []

    def on_epoch_end(self, batch, logs={}):
        # Append to log list
        self.history.append(logs.copy())

        # Save history so far to MAT file
        savemat(os.path.join(self.run_path, "history.mat"),
                {k: [x[k] for x in self.history] for k in self.history[0].keys()})

        # Plot graph
        plot_history(self.history, save_path=os.path.join(self.run_path, "history.png"))


def create_model(net_name, img_size, output_channels, **kwargs):
    """ Wrapper for initializing a network for training. """
    # compile_model = getattr(models, net_name)

    compile_model = dict(
        leap_cnn=models.leap_cnn,
        hourglass=models.hourglass,
        stacked_hourglass=models.stacked_hourglass,
        ).get(net_name)
    if compile_model == None:
        return None

    return compile_model(img_size, output_channels, **kwargs)

def train(data_path, *, 
    base_output_path="models",
    run_name=None, 
    data_name=None,
    net_name="leap_cnn",
    clean=False, 
    box_dset="box", 
    confmap_dset="confmaps", 
    val_size=0.15, 
    preshuffle=True,
    filters=64, 
    rotate_angle=15, 
    epochs=50, 
    batch_size=32, 
    batches_per_epoch=50, 
    val_batches_per_epoch=10, 
    viz_idx=0, 
    reduce_lr_factor=0.1, 
    reduce_lr_patience=3, 
    reduce_lr_min_delta=1e-5, 
    reduce_lr_cooldown=0, 
    reduce_lr_min_lr=1e-10,
    save_every_epoch=False,
    amsgrad=False,
    upsampling_layers=False,
    ):
    """
    Trains the network and saves the intermediate results to an output directory.

    :param data_path: Path to an HDF5 file with box and confmaps datasets
    :param base_output_path: Path to folder in which the run data folder will be saved
    :param run_name: Name of the training run. If not specified, will be formatted according to other parameters.
    :param data_name: Name of the dataset for use in formatting run_name
    :param net_name: Name of the network for use in formatting run_name
    :param clean: If True, deletes the contents of the run output path
    :param box_dset: Name of the box dataset in the HDF5 data file
    :param confmap_dset: Name of the confidence maps dataset in the HDF5 data file
    :param preshuffle: If True, shuffle prior to splitting the dataset, otherwise validation set will be the last frames
    :param val_size: Fraction of dataset to use as validation
    :param filters: Number of filters to use as baseline (see create_model)
    :param rotate_angle: Images will be augmented by rotating by +-rotate_angle
    :param epochs: Number of epochs to train for
    :param batch_size: Number of samples per batch
    :param batches_per_epoch: Number of batches per epoch (validation is evaluated at the end of the epoch)
    :param val_batches_per_epoch: Number of batches for validation
    :param viz_idx: Index of the sample image to use for visualization
    :param reduce_lr_factor: Factor to reduce the learning rate by (see ReduceLROnPlateau)
    :param reduce_lr_patience: How many epochs to wait before reduction (see ReduceLROnPlateau)
    :param reduce_lr_min_delta: Minimum change in error required before reducing LR (see ReduceLROnPlateau)
    :param reduce_lr_cooldown: How many epochs to wait after reduction before LR can be reduced again (see ReduceLROnPlateau)
    :param reduce_lr_min_lr: Minimum that the LR can be reduced down to (see ReduceLROnPlateau)
    :param save_every_epoch: Save weights at every epoch. If False, saves only initial, final and best weights.
    :param amsgrad: Use AMSGrad variant of optimizer. Can help with training accuracy on rare examples (see Reddi et al., 2018)
    :param upsampling_layers: Use simple bilinear upsampling layers as opposed to learned transposed convolutions
    """

    # Load
    print("data_path:", data_path)
    box, confmap = load_dataset(data_path, X_dset=box_dset, Y_dset=confmap_dset)
    viz_sample = (box[viz_idx], confmap[viz_idx])
    box, confmap, val_box, val_confmap, train_idx, val_idx = train_val_split(box, confmap, val_size=val_size, shuffle=preshuffle)
    print("box.shape:", box.shape)
    print("val_box.shape:", val_box.shape)

    # Pull out metadata
    img_size = box.shape[1:]
    num_output_channels = confmap.shape[-1]
    print("img_size:", img_size)
    print("num_output_channels:", num_output_channels)

    # Build run name if needed
    if data_name == None:
        data_name = os.path.splitext(os.path.basename(data_path))[0]
    if run_name == None:
        # Ex: "WangMice-DiegoCNN_v1.0_filters=64_rot=15_lrfactor=0.1_lrmindelta=1e-05"
        # run_name = "%s-%s_filters=%d_rot=%d_lrfactor=%.1f_lrmindelta=%g" % (data_name, net_name, filters, rotate_angle, reduce_lr_factor, reduce_lr_min_delta)
        run_name = "%s-%s_epochs=%d" % (data_name, net_name, epochs)
    print("data_name:", data_name)
    print("run_name:", run_name)

    # Create network
    model = create_model(net_name, img_size, num_output_channels, filters=filters, amsgrad=amsgrad, upsampling_layers=upsampling_layers, summary=True)
    if model == None:
        print("Could not find model:", net_name)
        return

    # Initialize run directories
    run_path = create_run_folders(run_name, base_path=base_output_path, clean=clean)
    savemat(os.path.join(run_path, "training_info.mat"), 
            {"data_path": data_path, "val_idx": val_idx, "train_idx": train_idx,
             "base_output_path": base_output_path, "run_name": run_name, "data_name": data_name,
             "net_name": net_name, "clean": clean, "box_dset": box_dset, "confmap_dset": confmap_dset,
             "preshuffle": preshuffle, "val_size": val_size, "filters": filters, "rotate_angle": rotate_angle,
             "epochs": epochs, "batch_size": batch_size, "batches_per_epoch": batches_per_epoch,
             "val_batches_per_epoch": val_batches_per_epoch, "viz_idx": viz_idx, "reduce_lr_factor": reduce_lr_factor,
             "reduce_lr_patience": reduce_lr_patience, "reduce_lr_min_delta": reduce_lr_min_delta,
             "reduce_lr_cooldown": reduce_lr_cooldown, "reduce_lr_min_lr": reduce_lr_min_lr, 
             "save_every_epoch": save_every_epoch, "amsgrad": amsgrad, "upsampling_layers": upsampling_layers})

    # Save initial network
    model.save(os.path.join(run_path, "initial_model.h5"))
    input_layers = [x.name for x in model.input_layers]
    output_layers = [x.name for x in model.output_layers]

    # Data augmentation
    if len(input_layers) > 1 or len(output_layers) > 1:
        train_datagen = MultiInputOutputPairedImageAugmenter(input_layers, output_layers, box, confmap, batch_size=batch_size, shuffle=True, theta=(-rotate_angle, rotate_angle))
        val_datagen = MultiInputOutputPairedImageAugmenter(input_layers, output_layers, val_box, val_confmap, batch_size=batch_size, shuffle=True, theta=(-rotate_angle, rotate_angle))
    else:
        train_datagen = PairedImageAugmenter(box, confmap, batch_size=batch_size, shuffle=True, theta=(-rotate_angle, rotate_angle))
        val_datagen = PairedImageAugmenter(val_box, val_confmap, batch_size=batch_size, shuffle=True, theta=(-rotate_angle, rotate_angle))

    # Initialize training callbacks
    history_callback = LossHistory(run_path=run_path)
    reduce_lr_callback = ReduceLROnPlateau(monitor="val_loss", factor=reduce_lr_factor, 
                                          patience=reduce_lr_patience, verbose=1, mode="auto",
                                          epsilon=reduce_lr_min_delta, cooldown=reduce_lr_cooldown,
                                          min_lr=reduce_lr_min_lr)
    if save_every_epoch:
        checkpointer = ModelCheckpoint(filepath=os.path.join(run_path, "weights/weights.{epoch:03d}-{val_loss:.9f}.h5"), verbose=1, save_best_only=False)
    else:
        checkpointer = ModelCheckpoint(filepath=os.path.join(run_path, "best_model.h5"), verbose=1, save_best_only=True)
    viz_grid_callback = LambdaCallback(on_epoch_end=lambda epoch, logs: show_confmap_grid(model, *viz_sample, plot=True, save_path=os.path.join(run_path, "viz_confmaps/confmaps_%03d.png" % epoch), show_figure=False))
    viz_pred_callback = LambdaCallback(on_epoch_end=lambda epoch, logs: show_pred(model, *viz_sample, save_path=os.path.join(run_path, "viz_pred/pred_%03d.png" % epoch), show_figure=False))
    
    # Train!
    epoch0 = 0
    t0_train = time()
    training = model.fit_generator(
            train_datagen,
            initial_epoch=epoch0,
            epochs=epochs,
            verbose=1,
    #         use_multiprocessing=True,
    #         workers=8,
            steps_per_epoch=batches_per_epoch,
            max_queue_size=512,
            shuffle=False,
            validation_data=val_datagen,
            validation_steps=val_batches_per_epoch,
            callbacks = [
                reduce_lr_callback,
                checkpointer,
                history_callback,
                viz_pred_callback,
                viz_grid_callback
            ]
        )

    # Compute total elapsed time for training
    elapsed_train = time() - t0_train
    print("Total runtime: %.1f mins" % (elapsed_train / 60))
        
    # Save final model
    model.history = history_callback.history
    model.save(os.path.join(run_path, "final_model.h5"))





if __name__ == "__main__":
    # Turn interactive plotting off
    # plt.ioff()

    # Wrapper for running from commandline
    clize.run(train)
