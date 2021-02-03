ARG CODENAME
FROM ubuntu:${CODENAME}
# Use Ubuntu Bionic/Focal LTS image as base

# Add legacy label for maintainer
LABEL maintainer="fr3akyphantom <rokibhasansagar2014@outlook.com>"

ENV \
	DEBIAN_FRONTEND=noninteractive \
	LANG=C.UTF-8 \
	JAVA_OPTS=" -Xmx7G " \
	JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
	PATH=~/bin:/usr/local/bin:/home/builder/bin:$PATH \
	USE_CCACHE=1 \
	CCACHE_COMPRESS=1 \
	CCACHE_COMPRESSLEVEL=8 \
	CCACHE_DIR=/srv/ccache

# Expand apt repository beyond itself
RUN sed 's/main$/main universe/' /etc/apt/sources.list 1>/dev/null

ARG SHORTCODE

# Install all required packages
RUN set -xe \
	&& if [ "${SHORTCODE}" = "bionic" ]; then UNIQ_PACKAGES="android-tools-adbd pxz libxcrypt-dev python-requests"; elif [ "${SHORTCODE}" = "focal" ]; then UNIQ_PACKAGES="python-is-python2 ninja-build libcrypt-dev"; fi \
	&& apt-get update -q -y \
	&& apt-get install -q -y --no-install-recommends \
		# Core Apt Packages
		apt-utils apt-transport-https python3-apt \
		# Linux Standard Base Packages
		lsb-core lsb-security ca-certificates systemd udev \
		# Upload/Download/Copy/FTP utils
		git curl wget wput axel rsync \
		# GNU and other core tools/utils
		binutils coreutils bsdmainutils util-linux patchutils libc6-dev sudo \
		# Security CLI tools
		ssh openssl libssl-dev sshpass gnupg2 gpg \
		# Tools for interacting with an Android platform
		android-sdk-platform-tools adb fastboot squashfs-tools \
		# OpenJDK8 as Java Runtime
		openjdk-8-jdk ca-certificates-java \
		maven nodejs \
		# Python packages
		python-all-dev python3-dev python3-requests \
		# Compression tools/utils/libraries
		zip unzip lzip lzop zlib1g-dev xzdec xz-utils pixz p7zip-full p7zip-rar zstd libzstd-dev lib32z1-dev \
		# GNU C/C++ compilers and Build Systems
		build-essential gcc gcc-multilib g++ g++-multilib \
		# make system and stuff
		clang llvm lld cmake automake autoconf \
		# XML libraries and stuff
		libxml2 libxml2-utils xsltproc expat re2c \
		# Developer's Libraries for ncurses
		ncurses-bin libncurses5-dev lib32ncurses5-dev bc libreadline-gplv2-dev libsdl1.2-dev libtinfo5 \
		# Misc utils
		file gawk xterm screen rename tree schedtool software-properties-common \
		dos2unix jq flex bison gperf exfat-utils exfat-fuse libb2-dev pngcrush imagemagick optipng advancecomp \
		# LTS specific Unique packages
		${UNIQ_PACKAGES} \
		# Additional
		kmod \
	&& unset UNIQ_PACKAGES \
	# Remove useless jre
	&& apt-get -y purge default-jre-headless openjdk-11-jre-headless \
	# Show installed packages
	&& apt list --installed \
	# Clean useless apt cache
	&& apt-get -y clean && apt-get -y autoremove \
	&& rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
	&& dpkg-divert --local --rename /usr/bin/ischroot && ln -sf /bin/true /usr/bin/ischroot \
	&& chmod u+s /usr/bin/screen && chmod 755 /var/run/screen \
	&& echo "Set disable_coredump false" >> /etc/sudo.conf

# Create user and home directory
RUN set -xe \
	&& mkdir -p /home/builder \
	&& useradd --no-create-home builder \
	&& rsync -a /etc/skel/ /home/builder/ \
	&& chown -R builder:builder /home/builder \
	&& echo "builder ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers

WORKDIR /home

RUN set -xe \
	&& mkdir /home/builder/bin \
	&& curl -sL https://gerrit.googlesource.com/git-repo/+/refs/heads/stable/repo?format=TEXT | base64 --decode  > /home/builder/bin/repo \
	&& curl -s https://api.github.com/repos/tcnksm/ghr/releases/latest \
		| grep "browser_download_url" | grep "amd64.tar.gz" | cut -d '"' -f 4 | wget -qi - \
	&& tar -xzf ghr_*_amd64.tar.gz \
	&& cp ghr_*_amd64/ghr /home/builder/bin/ \
	&& rm -rf ghr_* \
	&& chmod a+rx /home/builder/bin/repo \
	&& chmod a+x /home/builder/bin/ghr

WORKDIR /home/builder

RUN set -xe \
	&& mkdir -p extra && cd extra \
	&& wget -q https://ftp.gnu.org/gnu/make/make-4.3.tar.gz \
	&& tar xzf make-4.3.tar.gz \
	&& cd make-*/ \
	&& ./configure && bash ./build.sh 1>/dev/null && install ./make /usr/local/bin/make \
	&& cd .. \
	&& if [ "${SHORTCODE}" = "bionic" ]; then \
		git clone https://github.com/ninja-build/ninja.git; \
		cd ninja; git checkout -q v1.10.2; \
		./configure.py --bootstrap; \
		install ./ninja /usr/local/bin/ninja; \
		cd ..; fi \
	&& git clone https://github.com/ccache/ccache.git \
	&& cd ccache && git checkout -q v4.1 \
	&& mkdir build && cd build \
	&& cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr .. \
	&& make -j8 && make install \
	&& cd ../../.. \
	&& rm -rf extra

RUN if [ "${SHORTCODE}" = "focal" ]; then \
		if [ -e /lib/x86_64-linux-gnu/libncurses.so.6 ] && [ ! -e /usr/lib/x86_64-linux-gnu/libncurses.so.5 ]; then \
			ln -s /lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5; \
		fi; \
	fi

COPY android-env-vars.sh /etc/android-env-vars.sh

RUN chmod a+x /etc/android-env-vars.sh \
	&& echo "source /etc/android-env-vars.sh" >> /etc/bash.bashrc

# Set up udev rules for adb
RUN set -xe \
	&& curl --create-dirs -sL -o /etc/udev/rules.d/51-android.rules -O -L \
		https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules \
	&& chmod 644 /etc/udev/rules.d/51-android.rules \
	&& chown root /etc/udev/rules.d/51-android.rules

RUN CCACHE_DIR=/srv/ccache ccache -M 5G \
	&& chown builder:builder /srv/ccache

USER builder

VOLUME ["/home/builder", "/srv/ccache"]
