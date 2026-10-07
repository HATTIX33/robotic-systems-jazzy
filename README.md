# Robotic Systems — ROS 2 Jazzy on Fedora

VS Code Dev Container for **rootless Podman on Fedora**, based on **Ubuntu 24.04 Noble Numbat** and **ROS 2 Jazzy Jalisco**.

The environment is designed for the *Robotic Systems* course and provides a reproducible ROS 2 development setup while keeping ROS and Ubuntu-specific dependencies isolated from the Fedora host.

The project is mounted at `/workspace`, while the container provides sudo access, host networking and IPC, X11 authentication, hardware device access, and the ROS 2 development toolchain required by the course.

## Included software

The container includes:

- `ros-jazzy-desktop` — ROS 2, RViz, demos, and desktop tools required by the course.
- `ros-dev-tools`.
- `python3-colcon-common-extensions`.
- `python3-colcon-mixin`.
- `python3-colcon-clean`.
- The default `colcon` mixin repository.
- `colcon_cd` support and Bash completion.
- Git and the OpenSSH client.
- `sudo`.
- `vim`.
- X11 and Mesa utilities for graphics diagnostics.

The following ROS environment variables are configured:

```bash
ROS_DOMAIN_ID=0
ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST
```

Every shell automatically sources:

```bash
/opt/ros/jazzy/setup.bash
```

If it exists, the workspace overlay is also loaded automatically:

```bash
/workspace/ws/install/local_setup.bash
```

The initial `colcon_cd` root is:

```bash
/opt/ros/jazzy/
```

This can later be changed to the course workspace making package navigation more convenient.

No unrelated robotics frameworks, robot-specific SDKs, machine-learning stacks, remote desktop environments, or Gazebo packages are installed by default.

If additional software becomes necessary during the course, add it to the `Containerfile` and rebuild the Dev Container so that the environment remains reproducible.

## First startup

1. Open the `robotic-systems-jazzy` directory in VS Code on Fedora.
2. Make sure the **Dev Containers** extension is installed on the host.
3. Configure VS Code to use Podman as the container engine, for example:

```json
"dev.containers.dockerPath": "podman"
```

4. Press `Ctrl+Shift+P`.
5. Select:

```text
Dev Containers: Reopen in Container
```

6. Wait for the image build, ``rosdep update``, and VS Code extension installation to complete.

An Internet connection is required during the first build to download Ubuntu packages, ROS 2 packages, the `rosdep` index, colcon mixins, and VS Code extensions.

The first build may download several gigabytes of data.

After modifying the Containerfile, devcontainer.json, or other files that affect the container environment, rebuild it with:

Ctrl+Shift+P
→ Dev Containers: Rebuild Container

If you want to force a completely fresh build and ignore cached image layers, use:

Ctrl+Shift+P
→ Dev Containers: Rebuild Container Without Cache

## X11 and graphics

The container uses the Fedora graphical session directly through X11.

The host initialization script retrieves the current X11 authentication cookie using `xauth` and creates:

```text
.devcontainer/.host/Xauthority
```

This file is ignored by Git and excluded from the container build context. It is mounted read-only inside the container as:

```text
/tmp/.Xauthority
```

The container also receives the host `DISPLAY`.

There is therefore **no need to run**:

```bash
xhost +
```

After logging out of and back into Fedora, reopen or rebuild the Dev Container so that the X11 authentication cookie can be refreshed.

If VS Code does not inherit `DISPLAY` or `XAUTHORITY`, close the project window and reopen it from a graphical Fedora terminal:

```bash
cd /path/to/robotic-systems-jazzy
echo "$DISPLAY"
echo "$XAUTHORITY"
code .
```

## Hardware access

The container is currently configured to access:

```text
/dev/dri
/dev/snd
/dev/bus/usb
```

Their purposes are:

- `/dev/dri` — Intel integrated GPU and hardware-accelerated graphics.
- `/dev/snd` — host audio devices.
- `/dev/bus/usb` — USB devices.

If the project is used on a machine without one of these devices, remove the corresponding `--device` entry from `devcontainer.json` and from the device checks in `initialize-host.sh`.

Additional serial devices can be exposed explicitly if needed, for example:

```text
--device=/dev/ttyUSB0
```

## Testing ROS 2 manually

To verify ROS 2 communication manually, open two terminals inside the container.

Terminal 1:

```bash
ros2 run demo_nodes_cpp talker
```

Terminal 2:

```bash
ros2 run demo_nodes_py listener
```

The listener should repeatedly print messages containing:

```text
I heard
```

Stop both nodes with `Ctrl+C`.

## Workspace and development

Course packages should be placed in:

```text
ws/src
```

The workspace therefore has the usual structure:

```text
/workspace/ws
├── src
├── build
├── install
└── log
```

To install package dependencies and build the workspace:

```bash
cd /workspace/ws

rosdep install \
    --from-paths src \
    --ignore-src \
    --rosdistro jazzy \
    -r \
    -y

colcon build --symlink-install

source install/local_setup.bash
```

The project also provides two VS Code tasks:

- `ROS: colcon build` — builds the workspace with `colcon build --symlink-install`. Since it is the default build task, it can be launched directly with `Ctrl+Shift+B`.
- `ROS: install workspace dependencies` — runs the corresponding `rosdep install` command. Launch it with `Ctrl+Shift+P` → `Tasks: Run Task`.

Both tasks run from `/workspace/ws`.

To inspect the configured colcon mixins:

```bash
colcon mixin list default
```

To inspect `colcon clean`:

```bash
colcon clean --help
```

## Changing the `colcon_cd` root

By default:

```bash
_colcon_cd_root=/opt/ros/jazzy/
```

To make `colcon_cd` search from the course workspace instead, edit:

```text
.devcontainer/ros-env.sh
```

and replace:

```bash
export _colcon_cd_root=/opt/ros/jazzy/
```

with:

```bash
export _colcon_cd_root=/workspace/ws
```

Then rebuild the Dev Container.

## Persistence

The entire host project is bind-mounted at:

```text
/workspace
```

As a result, project files remain on the Fedora host and survive container recreation.

This includes:

```text
ws/src
ws/build
ws/install
ws/log
```

The generated `build`, `install`, and `log` directories are ignored by Git.

Changes made only inside the container filesystem are temporary.

For example:

```bash
sudo apt install some-package
```

installs the package only in the current container. If the container is deleted and recreated from the project configuration, that package disappears.

Any package or configuration that should permanently belong to the development environment should instead be added to the `Containerfile` or the appropriate setup script.

## Git and SSH

Git and SSH access use the integration provided by VS Code Dev Containers.

When available, VS Code forwards the SSH agent from the Fedora host into the container. Private SSH keys therefore do not need to be copied into the image or workspace.

The host `.ssh` directory is not mounted into the container.

Inside the VS Code container terminal, you can inspect SSH agent forwarding with:

```bash
echo "$SSH_AUTH_SOCK"
ssh-add -l
```

Standard GitHub remotes such as:

```text
git@github.com:user/repository.git
```

can therefore use the SSH identities already loaded by the host agent.

Custom SSH aliases such as:

```text
github-personal
```

are different: the SSH agent provides cryptographic identities, but it does not provide entries from the host's `~/.ssh/config`.

If such aliases are required, the corresponding `Host` configuration must also be made available inside the container.

A container started manually with `podman run` does not automatically receive the VS Code SSH-agent integration.

## VS Code extensions

The Dev Container installs the extensions required for development directly in the container environment, including the ROS-specific tools used by the course.

Among them:

```text
ranch-hand-robotics.rde-ros-2
ranch-hand-robotics.urdf-editor
```

This keeps ROS-aware tooling associated with the Jazzy environment instead of the Fedora host.

The extensions are declared in:

```text
.devcontainer/devcontainer.json
```

and are installed automatically when the Dev Container is created.

## Fedora and Podman details

The development container runs through **rootless Podman**.

The container user is:

```text
ros
```

with:

```text
UID 1000
GID 1000
```

and passwordless `sudo`.

The Podman option:

```text
--userns=keep-id:uid=1000,gid=1000
```

maps the Fedora user to the `ros` user in the container. This keeps files created in the bind-mounted workspace accessible from both the host and the container without changing ownership on the Fedora filesystem.

The Dev Container setting:

```json
"updateRemoteUserUID": false
```

keeps this mapping stable.

The configuration also uses:

```text
--runtime=crun
--group-add=keep-groups
```

to preserve supplementary group access from the host, which is useful when accessing hardware devices.

The container uses host networking and IPC:

```text
--network=host
--ipc=host
```

This simplifies ROS 2 communication and avoids an additional container network namespace.

The configuration also currently uses:

```json
"privileged": true
```

which significantly reduces container isolation.

Although Podman itself runs rootless, the container should still be used only with trusted course and development code.

There is no need to disable SELinux on the Fedora host.

## ROS 2 networking

The environment defines:

```bash
ROS_DOMAIN_ID=0
ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST
```

Together with host networking, this configuration is intended for running the course ROS 2 nodes locally on a single machine.

If the project later needs ROS 2 discovery across multiple physical computers or robots, the discovery configuration may need to be changed accordingly.

## Host and container responsibilities

The container provides:

```text
Ubuntu 24.04 user space
ROS 2 Jazzy
development tools
ROS dependencies
VS Code remote extensions
```

The Fedora host still provides:

```text
Linux kernel
hardware drivers
Intel GPU
audio devices
USB devices
graphical session
Podman
VS Code
```

The container therefore does **not** run its own Linux kernel like a virtual machine.

Graphics applications such as RViz use the Fedora kernel and hardware while running against the Ubuntu/ROS userspace inside the container.

This provides substantially more direct hardware access than a traditional virtual machine while keeping the ROS software environment isolated.

## Updates and reproducibility

The image starts from:

```text
ubuntu:24.04
```

ROS 2 is installed from the official ROS apt repository.

The project currently pins the `ros2-apt-source` repository-configuration package to release:

```text
1.3.0
```

Ubuntu and ROS packages installed through `apt` are otherwise resolved to the versions available from the configured repositories at build time.

Consequently, the repository defines the installation procedure and environment structure, but does not pin every individual system package version.

A build performed at a later date may therefore receive newer package updates while remaining on Ubuntu 24.04 and ROS 2 Jazzy.

## References

- [ROS 2 Jazzy — Ubuntu installation using Debian packages](https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html)
- [ROS 2 Jazzy installation documentation source](https://github.com/ros2/ros2_documentation/blob/jazzy/source/Installation/Ubuntu-Install-Debs.rst)
- [ROS apt source releases](https://github.com/ros-infrastructure/ros-apt-source/releases)
- [colcon mixin repository](https://github.com/colcon/colcon-mixin-repository)