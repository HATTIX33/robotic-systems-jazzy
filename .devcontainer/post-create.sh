#!/usr/bin/env bash
set -eo pipefail

source /opt/ros/jazzy/setup.bash

mkdir -p /workspace/ws/src
rosdep update --rosdistro jazzy