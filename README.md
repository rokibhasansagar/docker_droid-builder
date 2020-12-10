<div align="center">

  <h1><i>Droid Builder - One Image To Build Them All</i></h1>

  <h3><i>Standalone Docker Container based upon Updated Ubuntu 18.04/20.04 LTS for Building Android ROMs or Recovery Projects</i></h3>

  [![Actions Status](https://github.com/rokibhasansagar/docker_droid-builder/workflows/AIO%20Docker%20Builder/badge.svg)](https://github.com/rokibhasansagar/docker_droid-builder/actions)
  [![Container Builder](https://img.shields.io/badge/Powered%20By-Github%20Actions-blue?logo=github-actions)](https://github.com/features/actions "Know about Github Actions")
  [![Platform](https://img.shields.io/badge/Based%20On-Ubuntu-orange?logo=ubuntu)](https://ubuntu.com/download)
  [![License](https://img.shields.io/github/license/rokibhasansagar/docker_droid-builder)](https://github.com/rokibhasansagar/docker_droid-builder/blob/master/LICENSE)
  [![Latest Commit](https://images.microbadger.com/badges/commit/fr3akyphantom/droid-builder.svg)](https://microbadger.com/images/fr3akyphantom/droid-builder)
  [![Docker Pulls](https://img.shields.io/docker/pulls/fr3akyphantom/droid-builder)](https://hub.docker.com/r/fr3akyphantom/droid-builder "Show the Docker Repository")

</div>

## Available Tags of the Docker Image

_Bionic-based Image Info and It's Size:_ [![Image Tag](https://images.microbadger.com/badges/version/fr3akyphantom/droid-builder:bionic.svg)](https://microbadger.com/images/fr3akyphantom/droid-builder:bionic) [![Docker Image Size (bionic)](https://img.shields.io/docker/image-size/fr3akyphantom/droid-builder/bionic?cacheSeconds=3600)](#) [![MicroBadger Layers](https://img.shields.io/microbadger/layers/fr3akyphantom/droid-builder/bionic)](#)

_Focal-based Image Info and It's Size:_ [![Image Tag](https://images.microbadger.com/badges/version/fr3akyphantom/droid-builder:focal.svg)](https://microbadger.com/images/fr3akyphantom/droid-builder:focal) [![Docker Image Size (focal)](https://img.shields.io/docker/image-size/fr3akyphantom/droid-builder/focal?cacheSeconds=3600)](#) [![MicroBadger Layers](https://img.shields.io/microbadger/layers/fr3akyphantom/droid-builder/focal)](#)

## Get the Image

You might want to start the _bash_ environment as _root user_ by running `sudo -s`.

Now, you have choose on which platform you want to build. You got Bionic Beaver (18.04 LTS) and Focal Fossa (20.04 LTS).

Pull the image of by running the following command.

```bash
# If you want only bionic, run this ---
docker pull fr3akyphantom/droid-builder:bionic
# But if you want focal, run this instead ---
docker pull fr3akyphantom/droid-builder:focal
```
## Run the Container

Set `TAG` as "bionic" or "focal", according to your specified needs.
By default, "latest" tag is reserved for "focal" container (Ubuntu 18.04 is too old now).

```bash
docker run --privileged --rm -i \
  # optionally set/change the name/hostname of the container
  --name docker_droid-builder --hostname droid-builder \
  -e USER_ID=$(id -u) -e GROUP_ID=$(id -g) \
  # mount working directory as volume, '/home/builder' must be the Container's mount path
  -v "$HOME:/home/builder:rw,z" \
  # mount ccache volume too, host machine must have $HOME/.ccache folder if ccache is not installed
  -v "$HOME/.ccache:/srv/ccache:rw" \
  fr3akyphantom/droid-builder:${TAG} \
  /bin/bash
```
## Start the Build

When this Image runs as the droid-builder Container, You won't need to install any other softwares.

Check the [Dockerfile](https://github.com/rokibhasansagar/docker_droid-builder/blob/master/Dockerfile) to know more detail about installed packages.

When Docker Container is started, run the following commands...

```bash
# Change directory to any sub-folder (name as you like)
mkdir -p ${PROJECT_DIR} && cd ${PROJECT_DIR}

# Set your github usename and email, required by repo binary
git config --global user.email $GitHubMail
git config --global user.name $GitHubName
git config --global color.ui true

# Initialize the repo here to begin
repo init --depth 1 -q -u https://github.com/${DEMO_ORG}/${DEMO_MANIFEST}.git -b ${MANIFEST_BRANCH}

# sync the repo with maximum connections
# wait for the whole repo to be downloaded
repo sync -c -q --force-sync --no-clone-bundle --no-tags -j$(nproc --all)

# clone the specific device trees
git clone https://github.com/${DEMO_USER}/${DEVICE_REPONAME} device/${VENDOR}/${CODENAME}
# and other dependent repos too, if you need.

# Start the Build Process
export ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
# Set FLAVOR as "eng" or "userdebug"
lunch omni_${CODENAME}-${FLAVOR}

# you can now delete the .repo folder if you need more space,
# but it is not recommended for multiple builds or shared projects

# build only recovery image or make full ROM/otapackage
make -j$(nproc --all) recoveryimage || make -j$(($(nproc --all) / 2)) otapackage
```

### Well, there you have it!
Do away with your imagination.

