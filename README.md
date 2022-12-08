# humble-realsense
Docker for Intel Realsense in ROS2-Humble

Tested with Intel Realsense D415

# Execute

To run the container and forward the camera run with:
```
docker run -v /dev:/dev --device-cgroup-rule='c *:* rmw' kcinnayste/humble-realsense
```

To run with pointcloud, use:
```
docker run -v /dev:/dev --device-cgroup-rule='c *:* rmw' kcinnayste/humble-realsense ros2 launch realsense2_camera rs_launch.py pointcloud.enable:=true
```

More information about the realsense2_camera node can be found [here](https://github.com/IntelRealSense/realsense-ros#start-the-camera-node).