#!/bin/sh

OS=$(uname -s)
ARCH=$(uname -m)

BIN_OS=
BIN_ARCH=
BIN_DATA=.
BIN_DIR=bin_unix

case $OS in
Linux)
    BIN_OS=linux
    ;;
FreeBSD)
    BIN_OS=freebsd
    ;;
Darwin)
    BIN_OS=darwin
    ;;
esac

case $ARCH in
i486|i586|i686)
    BIN_ARCH=x86
    ;;
x86_64|amd64)
    BIN_ARCH=x64
    ;;
esac

if [ -x ${BIN_DATA}/${BIN_DIR}/client_${BIN_OS}_${BIN_ARCH} ]; then
    cd ${BIN_DATA}
    exec ${BIN_DIR}/client_${BIN_OS}_${BIN_ARCH} $@
else
    echo "You don't have a binary client for ${OS}/${ARCH}."
    echo "Either get precompiled binaries (if available) or compile it"
    echo "yourself using the instructions written in INSTALL.txt."
    exit 1
fi