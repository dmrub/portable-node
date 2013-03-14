#!/bin/bash

# Portable Node.js install script
# Author: Dmitri Rubinstein
# Version: 1.0
# 13.03.2013
#
#Copyright (c) 2013
#              DFKI - German Research Center for Artificial Intelligence
#              www.dfki.de
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of
#this software and associated documentation files (the "Software"), to deal in
#the Software without restriction, including without limitation the rights to
#use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
#of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

export LC_ALL=C
unset CDPATH

abspath_cd() {
    if [ -d "$1" ]; then
        echo "$(cd "$1"; pwd)"
    else
        case "$1" in
            "" | ".") echo "$PWD";;
            /*) echo "$1";;
            *)  echo "$PWD/$1";;
        esac
    fi
}

if [ -z "$(type -t dirname)" ]; then
    # Compute the dirname of FILE.
    dirname () {
        case ${1} in
            */*) echo "${1%/*}${2}" ;;
            *  ) echo "${3}" ;;
        esac
    }
fi

die() {
    echo >&2 "Error: $@"
    exit 1
}

if [ "$DEBUG" = "true" -o "$DEBUG" = "yes" ] || \
    [ "$DEBUG" -eq 1 ] 2>/dev/null; then
    debug() { echo "Debug: $@"; }
else
    debug() { :; }
fi

if type -p curl > /dev/null; then
    download() {
	echo "Download: $2 to: $1"
	curl -o "$2" "$1" && [ -e "$2" ]
    }
elif type -p wget > /dev/null; then
    download() {
	echo "Download: $2 to: $1"
	wget -O "$2" "$1" && [ -e "$2" ]
    }
else
    die "No download tool found, please install wget or curl"
fi

# ask prompt default
REPLY=
ask() {
    local prompt=$1
    local default=$2

    echo "$1"
    [ -n "$default" ] && echo -n "[$default] "
    read -e

    [ -z "$REPLY" ] && REPLY=$default
}

# setup_ask prompt default
setup_ask() {
    if [ "$AUTO_INSTALL" = "yes" ]; then
        echo "$1 : $2"
        REPLY=$2
    else
        ask "$@"
    fi
}

# Setup basic variables
thisDir=$(abspath_cd "$(dirname "$0")")
case "$thisDir" in
    */bin) destDir=${thisDir%/*};;
	*) destDir=$thisDir;;
esac

# Check OS
runCScript=
case "$OSTYPE" in
    linux-gnu) ;;
    msys|cygwin)
        # Windows run install-node.vbs if available
        [ -e "$thisDir/install-node.vbs" ] || die "Download and run install-node.vbs"
        runCScript=yes
        ;;
    *) die "$OSTYPE OS is not supported."
esac

# Process command line arguments
nodeVersion=0.10.0
if [[ "$HOSTTYPE" == "x86_64" ]]; then
    nodeArch=x64
else
    nodeArch=x86
fi
forceInstall=

while [ $# -gt 0 ]; do
    case "$1" in
        --) break;; # end of options
        -h|--help)
            cat<<EOF
Node Portable Environment Setup Script

Usage: $0 [options]
options :
  -h | --help                   print this
  -v | --version=node-version   select node version to download (default : $nodeVersion)
  -a | --arch=x86|x86_64|32|64  select node architecture to download (default : $nodeArch)
  -f | --force                  force download and installation
EOF
            exit 0
	    ;;
        -a*)
	    nodeArch=${1:2}
	    shift
	    ;;
	--arch=*)
	    nodeArch=${1:7}
	    shift
	    ;;
	-v*)
	    nodeVersion=${1:2}
	    shift
	    ;;
	--version=*)
	    nodeVersion=${1:10}
	    shift
	    ;;
	-f|--force)
	    forceInstall=yes
	    shift
	    ;;
        -*) die "Unsupported option: $1";;
        *) shift;;
    esac
done

case "$nodeArch" in
    x86_64|x64|64) nodeArch=x64;;
    x86|32) nodeArch=x86;;
    *) die "Unsupported architecture: $nodeArch";;
esac

if [[ "$runCScript" == "yes" ]]; then
    echo "Executing: cscript //NoLogo \"$thisDir/install-node.vbs\" //version:\"$nodeVersion\" //arch:\"$nodeArch\""
    exec cscript //NoLogo "$thisDir/install-node.vbs" //version:"$nodeVersion" //arch:"$nodeArch"
fi

# Setup paths
nodePrefix="node-v${nodeVersion}-linux-${nodeArch}"
nodeTarballFile="${nodePrefix}.tar.gz"
nodeURL="http://nodejs.org/dist/v${nodeVersion}/${nodeTarballFile}"

nodeBaseDir="$destDir/share/nodejs"
nodeTarballPath=$(abspath_cd "$nodeBaseDir/$nodeTarballFile")
#nodeInstallPathRel = nodeBaseDir & "\" & nodePrefix
#nodeInstallPath = FSO.GetAbsolutePathName(nodeInstallPathRel)

echo "I will download and install locally node.js version: $nodeVersion for architecture: $nodeArch"

mkdir -p "$nodeBaseDir" || die "Could not create $nodeBaseDir directory"

# Download and extract

download "$nodeURL" "$nodeTarballPath" || die "Could not download URL: $nodeURL"
