# shellcheck shell=bash
# Shared by Bash terminals, login shells and the image entrypoint.
# /etc/profile.d can also be read by non-Bash login shells.
if [ -n "${BASH_VERSION:-}" ]; then
    source /opt/ros/jazzy/setup.bash
    export ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-0}"
    export ROS_AUTOMATIC_DISCOVERY_RANGE="${ROS_AUTOMATIC_DISCOVERY_RANGE:-LOCALHOST}"
    source /usr/share/colcon_cd/function/colcon_cd.sh
    export _colcon_cd_root=/opt/ros/jazzy/
    source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash

    # The workspace does not have an install/ directory on first launch.
    # local_setup keeps the Jazzy underlay selected above.
    if [ -f /workspace/ws/install/local_setup.bash ]; then
        source /workspace/ws/install/local_setup.bash
    fi
fi
