# -*- coding: utf-8 -*-
"""
   Copyright 2018 Jacob M. Graving <jgraving@gmail.com>

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   Modified from code written by François Chollet 
   All contributions by François Chollet:
   Copyright (c) 2015 - 2018, François Chollet.
   All rights reserved.
"""

import numpy as np

import keras.backend as K
from keras.legacy import interfaces
from keras.engine import Layer
from keras.engine import InputSpec

from keras.utils import conv_utils
from keras.backend import int_shape, permute_dimensions

from keras.backend import tf

from keras.layers import Conv2D, Add

__all__ = ['UpSampling2D', 'Maxima2D']


def resize_images(x, height_factor, width_factor, interpolation, data_format):
    """Resizes the images contained in a 4D tensor.
    # Arguments
        x: Tensor or variable to resize.
        height_factor: Positive integer.
        width_factor: Positive integer.
        interpolation: string, "nearest", "bilinear" or "bicubic"
        data_format: string, `"channels_last"` or `"channels_first"`.
    # Returns
        A tensor.
    # Raises
        ValueError: if `data_format` is neither `"channels_last"` or `"channels_first"`.
    """
    if interpolation == 'nearest':
        tf_resize = tf.image.resize_nearest_neighbor
    elif interpolation == 'bilinear':
        tf_resize = tf.image.resize_bilinear
    elif interpolation == 'bicubic':
        tf_resize = tf.image.resize_bicubic
    else:
        raise ValueError('Invalid interpolation method:', interpolation)
    if data_format == 'channels_first':
        original_shape = int_shape(x)
        new_shape = tf.shape(x)[2:]
        new_shape *= tf.constant(np.array([height_factor, width_factor]).astype('int32'))
        x = permute_dimensions(x, [0, 2, 3, 1])
        x = tf_resize(x, new_shape, align_corners=True)
        x = permute_dimensions(x, [0, 3, 1, 2])
        x.set_shape((None, None, original_shape[2] * height_factor if original_shape[2] is not None else None,
                     original_shape[3] * width_factor if original_shape[3] is not None else None))
        return x
    elif data_format == 'channels_last':
        original_shape = int_shape(x)
        new_shape = tf.shape(x)[1:3]
        new_shape *= tf.constant(np.array([height_factor, width_factor]).astype('int32'))
        x = tf_resize(x, new_shape, align_corners=True)
        x.set_shape((None, original_shape[1] * height_factor if original_shape[1] is not None else None,
                     original_shape[2] * width_factor if original_shape[2] is not None else None, None))
        return x
    else:
        raise ValueError('Invalid data_format:', data_format)


class UpSampling2D(Layer):
    """Upsampling layer for 2D inputs.
    Repeats the rows and columns of the data
    by size[0] and size[1] respectively with bilinear interpolation.
    # Arguments
        size: int, or tuple of 2 integers.
            The upsampling factors for rows and columns.
        data_format: A string,
            one of `channels_last` (default) or `channels_first`.
            The ordering of the dimensions in the inputs.
            `channels_last` corresponds to inputs with shape
            `(batch, height, width, channels)` while `channels_first`
            corresponds to inputs with shape
            `(batch, channels, height, width)`.
            It defaults to the `image_data_format` value found in your
            Keras config file at `~/.keras/keras.json`.
            If you never set it, then it will be "channels_last".
        interpolation: A string,
            one of 'nearest' (default), 'bilinear', or 'bicubic'
    # Input shape
        4D tensor with shape:
        - If `data_format` is `"channels_last"`:
            `(batch, rows, cols, channels)`
        - If `data_format` is `"channels_first"`:
            `(batch, channels, rows, cols)`
    # Output shape
        4D tensor with shape:
        - If `data_format` is `"channels_last"`:
            `(batch, upsampled_rows, upsampled_cols, channels)`
        - If `data_format` is `"channels_first"`:
            `(batch, channels, upsampled_rows, upsampled_cols)`
    """

    @interfaces.legacy_upsampling2d_support
    def __init__(self, size=(2, 2), data_format=None, interpolation='nearest', **kwargs):
        super(UpSampling2D, self).__init__(**kwargs)
        self.data_format = conv_utils.normalize_data_format(data_format)
        self.interpolation = interpolation
        self.size = conv_utils.normalize_tuple(size, 2, 'size')
        self.input_spec = InputSpec(ndim=4)

    def compute_output_shape(self, input_shape):
        if self.data_format == 'channels_first':
            height = self.size[0] * input_shape[2] if input_shape[2] is not None else None
            width = self.size[1] * input_shape[3] if input_shape[3] is not None else None
            return (input_shape[0],
                    input_shape[1],
                    height,
                    width)
        elif self.data_format == 'channels_last':
            height = self.size[0] * input_shape[1] if input_shape[1] is not None else None
            width = self.size[1] * input_shape[2] if input_shape[2] is not None else None
            return (input_shape[0],
                    height,
                    width,
                    input_shape[3])

    def call(self, inputs):
        return resize_images(inputs, self.size[0], self.size[1],
                             self.interpolation, self.data_format)

    def get_config(self):
        config = {'size': self.size,
                  'data_format': self.data_format}
        base_config = super(UpSampling2D, self).get_config()
        return dict(list(base_config.items()) + list(config.items()))


def _find_maxima(x):

    x = K.cast(x, K.floatx())

    col_max = K.max(x, axis=1)
    row_max = K.max(x, axis=2)

    maxima = K.max(col_max, 1)
    maxima = K.expand_dims(maxima, -2)

    cols = K.cast(K.argmax(col_max, -2), K.floatx())
    rows = K.cast(K.argmax(row_max, -2), K.floatx())
    cols = K.expand_dims(cols, -2)
    rows = K.expand_dims(rows, -2)

    # maxima = K.concatenate([rows, cols, maxima], -2) # y, x, val
    maxima = K.concatenate([cols, rows, maxima], -2) # x, y, val

    return maxima


def find_maxima(x, data_format):
    """Finds the 2D maxima contained in a 4D tensor.
    # Arguments
        x: Tensor or variable.
        data_format: string, `"channels_last"` or `"channels_first"`.
    # Returns
        A tensor.
    # Raises
        ValueError: if `data_format` is neither `"channels_last"` or `"channels_first"`.
    """
    if data_format == 'channels_first':
        x = permute_dimensions(x, [0, 2, 3, 1])
        x = _find_maxima(x)
        x = permute_dimensions(x, [0, 2, 1])
        return x
    elif data_format == 'channels_last':
        x = _find_maxima(x)
        return x
    else:
        raise ValueError('Invalid data_format:', data_format)


class Maxima2D(Layer):
    """Maxima layer for 2D inputs.
    Finds the maxima and 2D indices
    for the channels in the input.
    The output is ordered as [row, col, maximum].
    # Arguments
        data_format: A string,
            one of `channels_last` (default) or `channels_first`.
            The ordering of the dimensions in the inputs.
            `channels_last` corresponds to inputs with shape
            `(batch, height, width, channels)` while `channels_first`
            corresponds to inputs with shape
            `(batch, channels, height, width)`.
            It defaults to the `image_data_format` value found in your
            Keras config file at `~/.keras/keras.json`.
            If you never set it, then it will be "channels_last".
    # Input shape
        4D tensor with shape:
        - If `data_format` is `"channels_last"`:
            `(batch, rows, cols, channels)`
        - If `data_format` is `"channels_first"`:
            `(batch, channels, rows, cols)`
    # Output shape
        3D tensor with shape:
        - If `data_format` is `"channels_last"`:
            `(batch, 3, channels)`
        - If `data_format` is `"channels_first"`:
            `(batch, channels, 3)`
    """

    def __init__(self, data_format=None, **kwargs):
        super(Maxima2D, self).__init__(**kwargs)
        self.data_format = conv_utils.normalize_data_format(data_format)
        self.input_spec = InputSpec(ndim=4)

    def compute_output_shape(self, input_shape):
        if self.data_format == 'channels_first':
            return (input_shape[0],
                    input_shape[1],
                    3)
        elif self.data_format == 'channels_last':
            return (input_shape[0],
                    3,
                    input_shape[3])

    def call(self, inputs):
        return find_maxima(inputs, self.data_format)

    def get_config(self):
        config = {'data_format': self.data_format}
        base_config = super(Maxima2D, self).get_config()
        return dict(list(base_config.items()) + list(config.items()))


def residual_bottleneck_module(x_in, output_filters=32, bottleneck_factor=2, prefix="res", activation="relu", initializer="glorot_normal"):
    # Get input shape and channels
    in_shape = K.int_shape(x_in)
    input_filters = in_shape[3]
    
    # Bottleneck filters are proportional to the output filters
    bottleneck_filters = output_filters // bottleneck_factor
    
    # Bottleneck block
    x = Conv2D(filters=bottleneck_filters, kernel_size=1, padding="same", activation=activation, kernel_initializer=initializer, name=prefix + "_Conv1")(x_in)
    x = Conv2D(filters=bottleneck_filters, kernel_size=3, padding="same", activation=activation, kernel_initializer=initializer, name=prefix + "_Conv2")(x)
    x = Conv2D(filters=output_filters, kernel_size=1, padding="same", activation=activation, kernel_initializer=initializer, name=prefix + "_Conv3")(x)
    
    # 1x1 conv if input channels are different from output channels
    if output_filters != input_filters:
        x_in = Conv2D(filters=output_filters, kernel_size=1, padding="same", activation=activation, kernel_initializer=initializer, name=prefix + "_ConvSkip")(x_in)
    
    # Residual connection
    x = Add(name=prefix + "_AddRes")([x_in, x])
    
    return x