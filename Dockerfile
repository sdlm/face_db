FROM ubuntu:16.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y apt-utils \
    vim curl wget mc git unzip rsync \
    python3 python3-pip python3-dev \
    build-essential pkg-config
RUN pip3 install -U pip \
    && pip3 install -U numpy scipy
RUN ln -s /usr/bin/python3 /usr/bin/python

WORKDIR /

##############
# install jupyter
##############
RUN pip3 install -U ipython jupyter

# setup jupyter config
COPY jupyter_notebook_config.py /root/.jupyter/

# Fix 'No module named ipykernel_launcher' https://github.com/nteract/hydrogen/issues/730
RUN python3 -m ipykernel install --user

# open jupyter port
EXPOSE 8888

##############
# install TensorFlow
##############
# https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/docker/Dockerfile

# Pick up some TF dependencies
RUN apt install -y libfreetype6-dev libpng12-dev libzmq3-dev software-properties-common

RUN pip3 --no-cache-dir install \
    Pillow \
    h5py \
    ipykernel \
    matplotlib \
    pandas \
    sklearn \
    && python -m ipykernel.kernelspec

# Install TensorFlow CPU version
RUN pip --no-cache-dir install \
    https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-1.4.1-cp35-cp35m-linux_x86_64.whl

# TensorBoard
EXPOSE 6006
# IPython
EXPOSE 8888

##############
# install OpenCV
##############
# docker-hub https://github.com/janza/docker-python3-opencv/blob/opencv_contrib/Dockerfile
# medium     https://medium.com/@debugvn/installing-opencv-3-3-0-on-ubuntu-16-04-lts-7db376f93961
# hackernoon https://github.com/ColeMurray/medium-facenet-tutorial/blob/master/Dockerfile
ENV OPENCV_VERSION="3.4.0"

# install dependencies
RUN apt-get update && \
    apt-get install -y \
    build-essential cmake pkg-config \
    libswscale-dev libtbb2 libtbb-dev \
    libgtk2.0-dev libgtk-3-dev \
    libjpeg-dev libpng-dev libtiff-dev \
    libxvidcore-dev libx264-dev \
    libjasper-dev libavformat-dev libpq-dev libdc1394-22-dev \
    libatlas-base-dev gfortran \
    ffmpeg yasm \
    libboost-all-dev

# download opencv lib
RUN wget -O opencv.tar.gz https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.tar.gz \
    && wget -O opencv_contrib.tar.gz https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.tar.gz \
    && tar -xzvf opencv.tar.gz \
    && tar -xzvf opencv_contrib.tar.gz \
    && rm opencv.tar.gz \
    && rm opencv_contrib.tar.gz

# compile
RUN mkdir /opencv-${OPENCV_VERSION}/cmake_binary \
    && cd /opencv-${OPENCV_VERSION}/cmake_binary \
    && cmake \
    -D BUILD_TIFF=ON \
    -D BUILD_opencv_java=OFF \
    -D OPENCV_EXTRA_MODULES_PATH=/opencv_contrib-${OPENCV_VERSION}/modules \
    -D ENABLE_AVX=ON \
    -D WITH_CUDA=OFF \
    -D WITH_OPENGL=ON \
    -D WITH_OPENCL=ON \
    -D WITH_IPP=ON \
    -D WITH_TBB=ON \
    -D WITH_EIGEN=ON \
    -D WITH_V4L=ON \
    -D WITH_FFMPEG=ON \
    -D BUILD_TESTS=OFF \
    -D BUILD_EXAMPLES=OFF \
    -D BUILD_opencv_python2=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D BUILD_NEW_PYTHON_SUPPORT=ON \
    -D INSTALL_C_EXAMPLES=OFF \
    -D INSTALL_PYTHON_EXAMPLES=ON \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=$(python3 -c "import sys; print(sys.prefix)") \
    -D PYTHON_EXECUTABLE=$(which python3) \
    -D PYTHON_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
    -D PYTHON_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
    .. \
    && make -j4 \
    && make install \
    && cd / \
    && rm -r /opencv-${OPENCV_VERSION} \
    && pip3 install -U opencv-contrib-python

# install https://github.com/davidsandberg/facenet.git
RUN git clone https://github.com/davidsandberg/facenet.git

##############
# add my own project
##############
ADD . /

# clean
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /
CMD ["jupyter", "notebook", "--allow-root"]
