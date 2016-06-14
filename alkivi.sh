#!/bin/bash
export DEFLOCAL="en_US.UTF-8"
export ENABLE_DBUS=true
export ENABLE_DHCP=true
export ENABLE_IPTABLES=true
export ENABLE_MINGPU=true
export ENABLE_ROOT=true
export ENABLE_ROOT_SSH=true
export ENABLE_SOUND=false
export ENABLE_SSHD=true
export ENABLE_USER=true
export ENABLE_XORG=false
export EXPANDROOT=true
export HOSTNAME="alkivi-rpi"
export BUILD_KERNEL=true
export KERNEL_RMSRC=false
export PASSWORD="alkivi123"
export TIMEZONE="Europe/Paris"
export USER_NAME=pi
./rpi2-gen-image.sh




