ARG OVERLAY_WS=/opt/ros/overlay_ws
ARG BUILD_DIR=/opt/build

FROM ros:humble

ENV DEBIAN_FRONTEND=noninteractive

# build & install realsense SDK
ARG BUILD_DIR
RUN mkdir $BUILD_DIR
#RUN mkdir /build
WORKDIR $BUILD_DIR

RUN git clone https://github.com/IntelRealSense/librealsense.git
WORKDIR ${BUILD_DIR}/librealsense
RUN apt update && apt install -y libssl-dev libusb-1.0-0-dev libudev-dev pkg-config libgtk-3-dev libglu1-mesa-dev

#RUN /build/librealsense/scripts/setup_udev_rules.sh

RUN mkdir ${BUILD_DIR}/librealsense/build
WORKDIR ${BUILD_DIR}/librealsense/build
RUN cmake ../ -DCMAKE_BUILD_TYPE=Release

RUN make && make install

# cleanup build-files
RUN rm -rf ${BUILD_DIR}

# cleanup apt lists
RUN rm -rf /var/lib/apt/lists/*

# clone overlay source
ARG OVERLAY_WS
WORKDIR $OVERLAY_WS/src
RUN echo "\
repositories: \n\
  ros2/realsense: \n\
    type: git \n\
    url: https://github.com/IntelRealSense/realsense-ros.git \n\
    version: ros2-development \n\
" > ../overlay.repos
RUN vcs import ./ < ../overlay.repos