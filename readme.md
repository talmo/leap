# LEAP

![LEAP Estimates Animal Pose](https://raw.githubusercontent.com/talmo/leap/master/docs/supp_mov1-long_clip.gif "LEAP Estimates Animal Pose")

_Full movie: [YouTube](https://youtu.be/ZmLQNbCbstk)_

This repository contains code for **LEAP** (_**L**EAP **E**stimates **A**nimal **P**ose_), a framework for animal body part position estimation via deep learning.

**Preprint:** [Pereira et al., bioRxiv (2018)](https://doi.org/10.1101/331181)

We are still working on documentation and preparing parts of the code. See the Features section below for an overview and status of each component.

We recommend starting with the [Tutorial: Training Leap From Scratch](https://github.com/talmo/leap/wiki/Tutorial:-Training-LEAP-from-scratch).

## Features
- [ ] Tracking and alignment code
- [x] Cluster sampling GUI
- [x] Skeleton creation GUI (`create_skeleton`)
- [x] GUI for labeling new dataset (`label_joints`)
- [x] Network training through the labeling GUI
- [x] MATLAB (`predict_box.m`) and Python (`leap.predict_box`) interfaces for predicting on new data
- [ ] GUI for predicting on new data
- [x] Training data + labels for main fly dataset used in analyses
- [x] Trained network for predicting on main fly dataset
- [ ] Analysis/figure generation code
- [ ] Documentation
- [x] Examples of usage

## Installation
### Pre-requisites
All neural network and GPU functionality is implemented in Python. The library was designed to be easy to use by providing commandline interfaces, but it can also be used programatically if the MATLAB GUIs are not required.

For the Python environment, we recommend [Anaconda 5.1.0](https://www.anaconda.com/download/) with Python 3.6.4. Note that **Python 2.x is not supported**.

For GPU support, you'll want to first install the CUDA drivers with CuDNN and then install these packages:
```bash
pip install -Iv tensorflow-gpu==1.6.0
pip install -Iv keras==2.1.4
```
See the [TensorFlow installation guide](https://www.tensorflow.org/install/) for more info.

If you don't have a GPU that supports CUDA, install the regular TensorFlow distribution:
```bash
pip install tensorflow
```

Please note that CPU execution will be MUCH slower (10-20x) than on a GPU. Consider investing in a GPU for your machine if you're thinking of using LEAP routinely.

### Automated installation
To get started with using LEAP, open up MATLAB and download the repository:
```matlab
>> !git clone https://github.com/talmo/leap.git
```

Then, install the package and add to the MATLAB path:
```matlab
>> cd leap
>> install_leap
```

That's it!

To avoid having to run this function every time you start MATLAB, save the [MATLAB Search Path](https://www.mathworks.com/help/matlab/matlab_env/what-is-the-matlab-search-path.html) after running it (or just add the `leap` subfolder to your permanent path).

### Manual: MATLAB dependencies
GUIs and analyses are implemented in MATLAB, but is not required for using the neural network functionality implemented in Python.

We use **MATLAB R2018a** with the following toolboxes: Parallel Computing Toolbox, Statistics and Machine Learning Toolbox, Computer Vision Toolbox, Image Processing Toolbox, Signal Processing Toolbox.

All MATLAB external toolboxes are included in the `leap/toolbox` subfolder. Just add the `leap` subdirectory to the [MATLAB Search Path](https://www.mathworks.com/help/matlab/matlab_env/what-is-the-matlab-search-path.html) to access all functionality:
```matlab
addpath(genpath('leap'))
```

### Manual: Python dependencies
The versions below were used during development of LEAP but other versions will also likely work.

Libraries required are easily installable via the pip package manager:
```bash
pip install -Iv numpy==1.14.1
pip install -Iv h5py==2.7.1
pip install -Iv clize==4.0.3
```

You will also need OpenCV 3 with Python bindings. We recommend using [skvark's excellent precompiled packages](https://github.com/skvark/opencv-python):
```bash
pip install -Iv opencv-python==3.4.0.12
```

You can install this library as a python package by downloading this git repository:

```bash
git clone https://github.com/talmo/leap.git
```

then typing:
```bash
pip install -e leap # installs the leap directory using pip
```

If you are using [anaconda](https://conda.io/docs/user-guide/getting-started.html)
to manage different python environments, it is highly recommended that you use this
matlab script to manage your python envs within matlab:
[condalab](https://github.com/wingillis/condalab) (see their readme for how to use it)

## Usage
Refer to the [Tutorial: Training Leap From Scratch](https://github.com/talmo/leap/wiki/Tutorial:-Training-LEAP-from-scratch).

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
