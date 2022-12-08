ARG OVERLAY_WS=/opt/ros/overlay_ws
ARG BUILD_DIR=/opt/build

FROM ros:humble AS cacher

# clone overlay source
ARG OVERLAY_WS
WORKDIR $OVERLAY_WS/src
RUN echo "\
repositories: \n\
  realsense: \n\
    type: git \n\
    url: https://github.com/IntelRealSense/realsense-ros.git \n\
    version: ros2-development \n\
" > ../overlay.repos
RUN vcs import ./ < ../overlay.repos


# copy manifests for caching
WORKDIR /opt
RUN mkdir -p /tmp/opt && \
    find ./ -name "package.xml" | \
      xargs cp --parents -t /tmp/opt && \
    find ./ -name "COLCON_IGNORE" | \
      xargs cp --parents -t /tmp/opt || true

FROM ros:humble AS builder

ENV DEBIAN_FRONTEND=noninteractive

# build & install realsense SDK
ARG BUILD_DIR
RUN mkdir $BUILD_DIR
#RUN mkdir /build
WORKDIR $BUILD_DIR

RUN git clone https://github.com/IntelRealSense/librealsense.git
WORKDIR ${BUILD_DIR}/librealsense
RUN apt update && apt install -y libssl-dev libusb-1.0-0-dev libudev-dev pkg-config libgtk-3-dev libglu1-mesa-dev ros-humble-vision-opencv ros-humble-image-transport ros-humble-diagnostic-updater
#ros-humble-cv-bridge 

#RUN /build/librealsense/scripts/setup_udev_rules.sh

RUN mkdir ${BUILD_DIR}/librealsense/build
WORKDIR ${BUILD_DIR}/librealsense/build
RUN cmake ../ -DCMAKE_BUILD_TYPE=Release

RUN make
#RUN make && make install


FROM ros:humble AS rel

ARG BUILD_DIR
#RUN mkdir -p ${BUILD_DIR}/librealsense/build

RUN apt update && apt install -y libssl-dev libusb-1.0-0-dev libudev-dev pkg-config libgtk-3-dev libglu1-mesa-dev ros-humble-vision-opencv ros-humble-image-transport ros-humble-diagnostic-updater
RUN rm -rf /var/lib/apt/lists/*

COPY --from=builder ${BUILD_DIR}/librealsense ${BUILD_DIR}/librealsense
WORKDIR ${BUILD_DIR}/librealsense/build
RUN make install

RUN rm -rf ${BUILD_DIR}

# install overlay dependencies
ARG OVERLAY_WS
WORKDIR $OVERLAY_WS
COPY --from=cacher /tmp/$OVERLAY_WS/src ./src


# build overlay source
COPY --from=cacher $OVERLAY_WS/src ./src
ARG OVERLAY_MIXINS="release"
RUN . /opt/ros/$ROS_DISTRO/setup.sh && \
    colcon build 


# source entrypoint setup
ENV OVERLAY_WS $OVERLAY_WS
RUN sed --in-place --expression \
      '$isource "${OVERLAY_WS}/install/setup.bash"' \
      /ros_entrypoint.sh

CMD [ "ros2", "launch", "realsense2_camera", "rs_launch.py" ]