# LEAP

![LEAP Estimates Animal Pose](https://raw.githubusercontent.com/talmo/leap/master/examples/supp_mov1-long_clip.gif "LEAP Estimates Animal Pose")

_Full movie: [YouTube](https://youtu.be/ZmLQNbCbstk)_

This repository contains code for **LEAP** (_**L**EAP **E**stimates **A**nimal **P**ose_), a framework for animal body part position estimation via deep learning.

**Preprint:** [Pereira et al., bioRxiv (2018)](https://doi.org/10.1101/331181)

We are still working on documentation and preparing parts of the code. See the Features section below for an overview and status of each component.

We recommend starting with the (Tutorial: Training Leap From Scratch)[https://github.com/talmo/leap/wiki/Tutorial:-Training-LEAP-from-scratch].

## Features
- [ ] Tracking and alignment code
- [x] Cluster sampling GUI
- [x] Skeleton creation GUI (`create_skeleton`)
- [x] GUI for labeling new dataset (`label_joints`)
- [x] Network training through the labeling GUI
- [x] MATLAB (`predict_box.m`) and Python (`leap.training`) interfaces for predicting on new data
- [ ] GUI for predicting on new data
- [x] Training data + labels for main fly dataset used in analyses
- [x] Trained network for predicting on main fly dataset
- [ ] Analysis/figure generation code
- [ ] Documentation
- [ ] Examples of usage

## Installation
### MATLAB dependencies
GUIs and analyses are implemented in MATLAB, but is not required for using the neural network functionality implemented in Python.

We use MATLAB R2018a with the following toolboxes: Parallel Computing Toolbox, Statistics and Machine Learning Toolbox, Computer Vision Toolbox, Image Processing Toolbox, Signal Processing Toolbox.

All MATLAB external toolboxes are included in the `leap/toolbox` subfolder. Just add the `leap` subdirectory to the [MATLAB Search Path](https://www.mathworks.com/help/matlab/matlab_env/what-is-the-matlab-search-path.html) to access all functionality:
```matlab
addpath(genpath('leap'))
```

### Python dependencies
All neural network and GPU functionality is implemented in Python. The library was designed to be easy to use by providing commandline interfaces, but it can also be used programatically if the MATLAB GUIs are not required.

For the Python environment, we recommend [Anaconda 5.1.0](https://www.anaconda.com/download/) with Python 3.6.4.

The versions below were used during development of LEAP but other versions will also likely work.

Libraries required are easily installable via the pip package manager:
```
pip install -Iv numpy==1.14.1
pip install -Iv h5py==2.7.1
pip install -Iv clize==4.0.3
```

You will also need OpenCV 3 with Python bindings. We recommend using [skvark's excellent precompiled packages](https://github.com/skvark/opencv-python):
```
pip install -Iv opencv-python==3.4.0.12
```

For GPU support, you'll want to first install the CUDA drivers with CuDNN and then install these packages:
```
pip install -Iv tensorflow-gpu==1.6.0
pip install -Iv keras==2.1.4
```
See the [TensorFlow installation guide](https://www.tensorflow.org/install/) for more info.

## Usage
Refer to the (Tutorial: Training Leap From Scratch)[https://github.com/talmo/leap/wiki/Tutorial:-Training-LEAP-from-scratch].

### Preprocessing

### GUI Workflow
1. **Cluster sampling**: Call `cluster_sample` from MATLAB commandline to launch GUI.
2. **Create skeleton**: Call `create_skeleton` from MATLAB commandline to launch GUI.
3. **Label data and train**: Call `label_joints` from MATLAB commandline to launch GUI.
4. **Batch estimation**: _Coming soon._

### Programmatic API
See `leap/training.py` and `leap/predict_box.py` for more info.

## Contact and more information
Reach out to us via email: Talmo Pereira (`talmo@princeton.edu`)
