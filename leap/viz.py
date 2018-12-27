import numpy as np
import matplotlib.pyplot as plt
plt.switch_backend('agg')


def show_pred(net, X, Y, joint_idx=0, alpha_pred=0.7, save_path=None, show_figure=False):
    """
    Shows a prediction from the model.
        net: network to use for prediction
        idx: index into box/confmap to use or tuple of (box, confmap) with a single sample
        joint_idx: index of confmap channel to overlay
        alpha_pred: opacity of confmap overlay
    """
    # Check inputs
    # if np.isscalar(idx):
    #     X = box[idx]
    #     Y = confmap[idx]
    # if len(idx) == 2:
    #     X, Y = idx
    if X.ndim == 2:
        X = X[None,...,None]
    if X.ndim == 3:
        if X.shape[0] == 1: # missing singleton channel
            X = X[..., None]
        elif X.shape[-1] == 1 or X.shape[-1] == 3: # missing sample singleton
            X = X[None,...]
    if Y.ndim > 3:
        Y = Y.squeeze(axis=0)
        
    # Predict
    Y2 = net.predict(X)
    if type(Y2) == list:
        Y2 = Y2[-1]
    Y2 = Y2.squeeze(axis=0)
    X = X.squeeze()
    
    # Find peaks
    pks_pred = []
    pks_gt = []
    for i in range(Y.shape[-1]):
        Yi = Y[...,i]
        peak_coord = np.unravel_index(np.argmax(Yi), Yi.shape)
        pks_gt.append(peak_coord)
        
        Yi = Y2[...,i]
        peak_coord = np.unravel_index(np.argmax(Yi), Yi.shape)
        pks_pred.append(peak_coord)
    
    # Show box image
    plt.figure(figsize=(6,6))
    plt.imshow(X, cmap="gray")
    
    # Normalize channels
    for i in range(Y2.shape[-1]):
        Y2[...,i] /= Y2[...,i].max()
        
    # Show prediction overlay
    plt.imshow(Y2[:,:,joint_idx], alpha=alpha_pred)
    
    # Plot peak markers
    for i in range(Y2.shape[-1]):
        plt.plot(*pks_gt[i][::-1],   'o', markersize=12, mew=3, mec='w', mfc=[0,0,0,0])
        plt.plot(*pks_gt[i][::-1],   'o', markersize=12, mew=1, mec='g', mfc=[0,0,0,0])
        
        plt.plot(*pks_pred[i][::-1], 'x', markersize=12, mew=3, mec='w')
        plt.plot(*pks_pred[i][::-1], 'x', markersize=12, mew=1, mec='r')
        
    plt.xticks([]), plt.yticks([])
    plt.tight_layout()
    
    if save_path is not None:
        plt.savefig(save_path, bbox_inches='tight', pad_inches=0)
    if show_figure:
        plt.show();
    else:
        plt.close()

def gallery(array, ncols=4):
    """ Utility function for tiling a set of images into a grid. """
    array = np.transpose(array.squeeze(), (2,0,1))
    nindex, height, width = array.shape
    nrows = int(np.ceil(nindex / ncols))
    if nindex != nrows * ncols:
        delta = (nrows * ncols) - nindex
        array = np.concatenate((array, np.zeros((delta, height, width), dtype=array.dtype)), axis=0)

    assert len(array) == nrows * ncols
    
    result = (array.reshape(nrows, ncols, height, width)
              .swapaxes(1,2)
              .reshape(height*nrows, width*ncols))
    return result

def show_confmap_grid(net, X, Y, plot=True, save_path=None, show_figure=False):
    """ 
    Shows predictions from the model using every channel in the confmap.
    """
    if X.ndim == 2:
        X = X[None,...,None]
    if X.ndim == 3:
        if X.shape[0] == 1: # missing singleton channel
            X = X[..., None]
        elif X.shape[-1] == 1 or X.shape[-1] == 3: # missing sample singleton
            X = X[None,...]
    if Y.ndim > 3:
        Y = Y.squeeze(axis=0)
        
    # Predict
    Y2 = net.predict(X)
    if type(Y2) == list:
        Y2 = Y2[-1]
    Y2 = Y2.squeeze(axis=0)
    X = X.squeeze()
    
    # Montage
    all_Y = np.stack((Y,Y2),axis=-1).reshape(Y.shape[:2] + (-1,))
    preds = gallery(all_Y, ncols=8)
    
    if plot or save_path is not None:
        # Display
        plt.figure(figsize=(12,12))
        plt.imshow(preds)
        plt.xticks([]),plt.yticks([])
        if save_path is not None:
            plt.savefig(save_path, bbox_inches='tight', pad_inches=0)
        if show_figure:
            plt.show();
        else:
            plt.close()
    else:
        return preds

def plot_history(history, save_path=None, show_figure=False):
    """ Plots the training history. """

    loss = [x["loss"] for x in history]
    val_loss = [x["val_loss"] for x in history]

    plt.figure(figsize=(8,4))
    plt.plot(loss)
    plt.plot(val_loss)
    plt.semilogy()
    plt.grid()
    plt.xlabel("Epochs")
    plt.ylabel("Loss")
    plt.legend(["Training", "Validation"])
    
    if save_path is not None:
        plt.savefig(save_path)
    if show_figure:
        plt.show()
    else:
        plt.close()
