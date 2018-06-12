import keras
from keras import backend as K
from keras.models import Model
from keras.layers import Input, Conv2D, Conv2DTranspose, Add, MaxPooling2D
from keras.optimizers import Adam

from leap.layers import residual_bottleneck_module, UpSampling2D

def leap_cnn(img_size, output_channels, filters=64, upsampling_layers=False, amsgrad=False, summary=False):
    """
    Creates and compiles network model.

    :param img_size: shape of a single image, optionally including channels
    :param output_channels: number of output channels (joints being predicted)
    :param filters: number of baseline filters to use (more filters will be used in intermediate layers)
    :param summary: prints network summary after compiling
    """
    if len(img_size) == 2:
        img_size = img_size + (1,)

    x_in = Input(img_size)

    x1 = Conv2D(filters, kernel_size=3, padding="same", activation="relu")(x_in)
    x1 = Conv2D(filters, kernel_size=3, padding="same", activation="relu")(x1)
    x1 = Conv2D(filters, kernel_size=3, padding="same", activation="relu")(x1)
    x1_pool = MaxPooling2D(pool_size=2, strides=2, padding="same")(x1)

    x2 = Conv2D(filters*2, kernel_size=3, padding="same", activation="relu")(x1_pool)
    x2 = Conv2D(filters*2, kernel_size=3, padding="same", activation="relu")(x2)
    x2 = Conv2D(filters*2, kernel_size=3, padding="same", activation="relu")(x2)
    x2_pool = MaxPooling2D(pool_size=2, strides=2, padding="same")(x2)

    x3 = Conv2D(filters*4, kernel_size=3, padding="same", activation="relu")(x2_pool)
    x3 = Conv2D(filters*4, kernel_size=3, padding="same", activation="relu")(x3)
    x3 = Conv2D(filters*4, kernel_size=3, padding="same", activation="relu")(x3)

    if upsampling_layers:
        x4 = UpSampling2D(interpolation="bilinear")(x3)
    else:
        x4 = Conv2DTranspose(filters*2, kernel_size=3, strides=2, padding="same", activation="relu", kernel_initializer="glorot_normal")(x3)
    x4 = Conv2D(filters*2, kernel_size=3, padding="same", activation="relu")(x4)
    x4 = Conv2D(filters*2, kernel_size=3, padding="same", activation="relu")(x4)

    if upsampling_layers:
        x_out = UpSampling2D(interpolation="bilinear")(x4)
        x_out = Conv2D(output_channels, kernel_size=3, padding="same", activation="linear")(x_out)
    else:
        x_out = Conv2DTranspose(output_channels, kernel_size=3, strides=2, padding="same", activation="linear", kernel_initializer="glorot_normal")(x4)

    # Compile
    net = Model(inputs=x_in, outputs=x_out, name="LeapCNN")
    net.compile(optimizer=Adam(amsgrad=amsgrad), loss="mean_squared_error")

    if summary:
        net.summary()

    return net

def hourglass(img_size, output_channels, filters=64, upsampling_layers=False, amsgrad=False, summary=False):
    """
    Creates and compiles network model.

    :param img_size: shape of a single image, optionally including channels
    :param output_channels: number of output channels (joints being predicted)
    :param filters: number of baseline filters to use (more filters will be used in intermediate layers)
    :param summary: prints network summary after compiling
    """

    if len(img_size) == 2:
        img_size = img_size + (1,)

    x_in = Input(img_size, name="x_in")

    x1_pre = residual_bottleneck_module(x_in, prefix="x1", output_filters=filters)
    x1 = MaxPooling2D(pool_size=2, strides=2, padding="same", name="x1_pool")(x1_pre)

    x2_pre = residual_bottleneck_module(x1, prefix="x2", output_filters=filters)
    x2 = MaxPooling2D(pool_size=2, strides=2, padding="same", name="x2_pool")(x2_pre)

    x3_pre = residual_bottleneck_module(x2, prefix="x3", output_filters=filters)
    x3 = MaxPooling2D(pool_size=2, strides=2, padding="same", name="x3_pool")(x3_pre)

    x4_pre = residual_bottleneck_module(x3, prefix="x4", output_filters=filters)
    x4 = MaxPooling2D(pool_size=2, strides=2, padding="same", name="x4_pool")(x4_pre)


    x5 = residual_bottleneck_module(x4, prefix="x5", output_filters=filters)


    if upsampling_layers:
        x6_pre = UpSampling2D(interpolation="bilinear", name="x6_Upsample")(x5)
    else:
        x6_pre = Conv2DTranspose(filters=filters, kernel_size=3, strides=2, padding="same", activation="relu", kernel_initializer="glorot_normal", name="x6_ConvT")(x5)
    x6_add = Add(name="x6_Add")([x4_pre, x6_pre])
    x6 = residual_bottleneck_module(x6_add, prefix="x6", output_filters=filters)

    if upsampling_layers:
        x7_pre = UpSampling2D(interpolation="bilinear", name="x7_Upsample")(x6)
    else:
        x7_pre = Conv2DTranspose(filters=filters, kernel_size=3, strides=2, padding="same", activation="relu", kernel_initializer="glorot_normal", name="x7_ConvT")(x6)
    x7_add = Add(name="x7_Add")([x3_pre, x7_pre])
    x7 = residual_bottleneck_module(x7_add, prefix="x7", output_filters=filters)

    if upsampling_layers:
        x8_pre = UpSampling2D(interpolation="bilinear", name="x8_Upsample")(x7)
    else:
        x8_pre = Conv2DTranspose(filters=filters, kernel_size=3, strides=2, padding="same", activation="relu", kernel_initializer="glorot_normal", name="x8_ConvT")(x7)
    x8_add = Add(name="x8_Add")([x2_pre, x8_pre])
    x8 = residual_bottleneck_module(x8_add, prefix="x8", output_filters=filters)

    if upsampling_layers:
        x9_pre = UpSampling2D(interpolation="bilinear", name="x9_Upsample")(x8)
    else:
        x9_pre = Conv2DTranspose(filters=filters, kernel_size=3, strides=2, padding="same", activation="relu", kernel_initializer="glorot_normal", name="x9_ConvT")(x8)
    x9_add = Add(name="x9_Add")([x1_pre, x9_pre])
    x9 = residual_bottleneck_module(x9_add, prefix="x9", output_filters=filters)

    x_out = Conv2D(filters=output_channels, kernel_size=3, strides=1, padding="same", activation="linear", name="x_out")(x9)

    # Compile
    model = Model(inputs=x_in, outputs=x_out, name="hourglass")
    model.compile(optimizer=Adam(amsgrad=amsgrad), loss="mean_squared_error")

    if summary:
        model.summary()

    return model



def stacked_hourglass(img_size, output_channels, filters=64, upsampling_layers=False, amsgrad=False, summary=False):
    """
    Creates and compiles network model.

    :param img_size: shape of a single image, optionally including channels
    :param output_channels: number of output channels (joints being predicted)
    :param filters: number of baseline filters to use (more filters will be used in intermediate layers)
    :param summary: prints network summary after compiling
    """

    if len(img_size) == 2:
        img_size = img_size + (1,)

    x_in = Input(img_size, name="x_in")

    x1_1_pre = residual_bottleneck_module(x_in, prefix="x1_1", output_filters=filters)
    x1_1 = MaxPooling2D(pool_size=2, strides=2, padding="same", name="x1_1_pool")(x1_1_pre)

    x1_2_pre = residual_bottleneck_module(x1_1, prefix="x1_2", output_filters=filters)
    x1_2 = MaxPooling2D(pool_size=2, strides=2, padding="same", name="x1_2_pool")(x1_2_pre)

    x1_3_pre = residual_bottleneck_module(x1_2, prefix="x1_3", output_filters=filters)
    x1_3 = MaxPooling2D(pool_size=2, strides=2, padding="same", name="x1_3_pool")(x1_3_pre)

    x1_4_pre = residual_bottleneck_module(x1_3, prefix="x1_4", output_filters=filters)
    x1_4 = MaxPooling2D(pool_size=2, strides=2, padding="same", name="x1_4_pool")(x1_4_pre)


    x1_5 = residual_bottleneck_module(x1_4, prefix="x1_5", output_filters=filters)


    if upsampling_layers:
        x1_6_pre = UpSampling2D(interpolation="bilinear", name="x1_6_Upsample")(x1_5)
    else:
        x1_6_pre = Conv2DTranspose(filters=filters, kernel_size=3, strides=2, padding="same", activation="relu", kernel_initializer="glorot_normal", name="x1_6_ConvT")(x1_5)
    x1_6_add = Add(name="x1_6_Add")([x1_4_pre, x1_6_pre])
    x1_6 = residual_bottleneck_module(x1_6_add, prefix="x1_6", output_filters=filters)

    if upsampling_layers:
        x1_7_pre = UpSampling2D(interpolation="bilinear", name="x1_7_Upsample")(x1_6)
    else:
        x1_7_pre = Conv2DTranspose(filters=filters, kernel_size=3, strides=2, padding="same", activation="relu", kernel_initializer="glorot_normal", name="x1_7_ConvT")(x1_6)
    x1_7_add = Add(name="x1_7_Add")([x1_3_pre, x1_7_pre])
    x1_7 = residual_bottleneck_module(x1_7_add, prefix="x1_7", output_filters=filters)

    if upsampling_layers:
        x1_8_pre = UpSampling2D(interpolation="bilinear", name="x1_8_Upsample")(x1_7)
    else:
        x1_8_pre = Conv2DTranspose(filters=filters, kernel_size=3, strides=2, padding="same", activation="relu", kernel_initializer="glorot_normal", name="x1_8_ConvT")(x1_7)
    x1_8_add = Add(name="x1_8_Add")([x1_2_pre, x1_8_pre])
    x1_8 = residual_bottleneck_module(x1_8_add, prefix="x1_8", output_filters=filters)

    if upsampling_layers:
        x1_9_pre = UpSampling2D(interpolation="bilinear", name="x1_9_Upsample")(x1_8)
    else:
        x1_9_pre = Conv2DTranspose(filters=filters, kernel_size=3, strides=2, padding="same", activation="relu", kernel_initializer="glorot_normal", name="x1_9_ConvT")(x1_8)
    x1_9_add = Add(name="x1_9_Add")([x1_1_pre, x1_9_pre])
    x1_9 = residual_bottleneck_module(x1_9_add, prefix="x1_9", output_filters=filters)

    #############

    x2_1_pre = residual_bottleneck_module(x1_9, prefix="x2_1", output_filters=filters)
    x2_1 = MaxPooling2D(pool_size=2, strides=2, padding="same", name="x2_1_pool")(x2_1_pre)

    x2_2_pre = residual_bottleneck_module(x2_1, prefix="x2_2", output_filters=filters)
    x2_2 = MaxPooling2D(pool_size=2, strides=2, padding="same", name="x2_2_pool")(x2_2_pre)

    x2_3_pre = residual_bottleneck_module(x2_2, prefix="x2_3", output_filters=filters)
    x2_3 = MaxPooling2D(pool_size=2, strides=2, padding="same", name="x2_3_pool")(x2_3_pre)

    x2_4_pre = residual_bottleneck_module(x2_3, prefix="x2_4", output_filters=filters)
    x2_4 = MaxPooling2D(pool_size=2, strides=2, padding="same", name="x2_4_pool")(x2_4_pre)


    x2_5 = residual_bottleneck_module(x2_4, prefix="x2_5", output_filters=filters)


    if upsampling_layers:
        x2_6_pre = UpSampling2D(interpolation="bilinear", name="x2_6_Upsample")(x2_5)
    else:
        x2_6_pre = Conv2DTranspose(filters=filters, kernel_size=3, strides=2, padding="same", activation="relu", kernel_initializer="glorot_normal", name="x2_6_ConvT")(x2_5)
    x2_6_add = Add(name="x2_6_Add")([x2_4_pre, x2_6_pre])
    x2_6 = residual_bottleneck_module(x2_6_add, prefix="x2_6", output_filters=filters)

    if upsampling_layers:
        x2_7_pre = UpSampling2D(interpolation="bilinear", name="x2_7_Upsample")(x2_6)
    else:
        x2_7_pre = Conv2DTranspose(filters=filters, kernel_size=3, strides=2, padding="same", activation="relu", kernel_initializer="glorot_normal", name="x2_7_ConvT")(x2_6)
    x2_7_add = Add(name="x2_7_Add")([x2_3_pre, x2_7_pre])
    x2_7 = residual_bottleneck_module(x2_7_add, prefix="x2_7", output_filters=filters)

    if upsampling_layers:
        x2_8_pre = UpSampling2D(interpolation="bilinear", name="x2_8_Upsample")(x2_7)
    else:
        x2_8_pre = Conv2DTranspose(filters=filters, kernel_size=3, strides=2, padding="same", activation="relu", kernel_initializer="glorot_normal", name="x2_8_ConvT")(x2_7)
    x2_8_add = Add(name="x2_8_Add")([x2_2_pre, x2_8_pre])
    x2_8 = residual_bottleneck_module(x2_8_add, prefix="x2_8", output_filters=filters)

    if upsampling_layers:
        x2_9_pre = UpSampling2D(interpolation="bilinear", name="x2_9_Upsample")(x2_8)
    else:
        x2_9_pre = Conv2DTranspose(filters=filters, kernel_size=3, strides=2, padding="same", activation="relu", kernel_initializer="glorot_normal", name="x2_9_ConvT")(x2_8)
    x2_9_add = Add(name="x2_9_Add")([x2_1_pre, x2_9_pre])
    x2_9 = residual_bottleneck_module(x2_9_add, prefix="x2_9", output_filters=filters)

    #############

    x_out1 = residual_bottleneck_module(x1_9, output_filters=output_channels, bottleneck_factor=1, prefix="x_out1", activation="linear")
    x_out2 = residual_bottleneck_module(x2_9, output_filters=output_channels, bottleneck_factor=1, prefix="x_out2", activation="linear")

    # Compile
    model = Model(inputs=x_in, outputs=[x_out1, x_out2], name="StackedHourglass")
    model.compile(optimizer=Adam(amsgrad=amsgrad), loss="mean_squared_error")

    if summary:
        model.summary()

    return model
