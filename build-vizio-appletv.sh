#!/bin/bash
##############################################################################
# build vizioappletv 
#
# usage: build.sh --target=vs-sx7a|vs-sx7b|mtk-5581|mtk-5597|mtk2020
#                [--release-ver=<version>]
#                [--dev]
#                [--enable-debug]
#                [--rc]
#                [--clean]
#
#        If --release-ver is not specified, a development tarball is created
#
# This script assumes this directory structure:
#   <basedir>/ ........................ pre-exists
#   <basedir>/build/ .................. pre-exists, VS build scripts
#   <basedir>/vizio-appletv-build/ .......... pre-exists, conjure build scripts
#   <basedir>/vizio_appletv_basic_egl/ .................... pre-exists, appletv source
#   <basedir>/sx7_sdk/ ................ pre-exists, VS SDK currently not needed
#
#   <basedir>/out/vizio-appletv-build/ ........... created, vizio-appletv build output
#   <basedir>/vizio_appletv/install/dev/ ............ created, dev image files
#   <basedir>/vizio_appletv/install/img/ ............ created, install image files
#   <basedir>/vizio_appletv/install/img/dragonfly/ .. created, VS .img files
#   <basedir>/vizio_appletv/install/img/leo/ ........ created, VS .img files
#   <basedir>/vizio_apple_tv/install/work/ ........... created, general workspace
#   <basedir>/vizio_appletv/install/work/basic-egl/ .. created, base installation files
#
##############################################################################

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------

ME=$(basename $0)
MYDIR=$(realpath $(dirname $0))
TARGET=vs-sx7b
MAKE_CLEAN=0
ENABLE_CHROMIUM_DEBUG=0
IS_DEV_BUILD=0
IS_RC_BUILD=0

APPLETV_FILES="
basic-egl
libshim_lib.so
"

APPLETV_PAK_DIRS="
"

EXTRA_FILES="
"

VENDOR_FILES_UNUSED="
"

#-----------------------------------------------------------------------------
# functions
#-----------------------------------------------------------------------------

usage()
{
  rc=$1
  shift
  msg="$*"
  test -n "$msg" && echo $msg && echo
  echo "usage: $ME --target=vs-sx7a|vs-sx7b|mtk-5581|mtk-5597|mtk2020 [--release-ver=<version>] [--dev] [--clean]
"
  exit $rc
}


die()
{
  rc=$1
  shift
  msg="$*"
  test -n "$msg" && echo "!! $msg" && echo
  exit $rc
}

set_target()
{
  target=$1
  case $target in
    vs-sx7a|VS-SX7A)   TARGET=vs-sx7a ; incl=build-vs.incl      ;;
    vs-sx7b|VS-SX7B)   TARGET=vs-sx7b ; incl=build-vs.incl      ;;
    mtk-5581|MTK-5581) TARGET=mtk-5581; incl=build-mtk.incl     ;;
    mtk-5597|MTK-5597) TARGET=mtk-5597; incl=build-mtk.incl     ;;
    mtk2020|MTK2020)   TARGET=mtk2020 ; incl=build-mtk2020.incl ;;
    *) usage 2 "Error: unsupported target: '$1'" ;;
  esac
}

set_release_ver()
{
  RELEASE_VER=$1
}

set_symdir()
{
  SYMDIR=$1
}

parse_arguments()
{
  for arg in $*
  do
    case $arg in
      --target=*)      set_target `echo $arg | awk -F = '{print $2}'` ;;
      --release-ver=*) set_release_ver `echo $arg | awk -F = '{print $2}'` ;;
      --symdir=*)      set_symdir `echo $arg | awk -F = '{print $2}'` ;;
      --enable-debug)  ENABLE_CHROMIUM_DEBUG=1 ;;
      --dev)           IS_DEV_BUILD=1 ;;
      --rc)            IS_RC_BUILD=1 ;;
      --clean)         MAKE_CLEAN=1 ;;
      --help)          usage 0 ;;
      *)               usage 1 "Error: unsupported flag: '$arg'" ;;
    esac
  done
}

banner()
{
  echo "
==============================================================================
 $*
==============================================================================
"
}

show_settings()
{
  case "$TARGET" in
    "mtk-5581") target="MediaTek 5581" ;;
    "mtk-5597") target="MediaTek 5597" ;;
    "mtk2020")  target="MediaTek 2020" ;;
    "vs-sx7a")  target="V-Silicon SX7A" ;;
    "vs-sx7b")  target="V-Silicon SX7B" ;;
    *)          target="Unknown" ;;
  esac

  release="development tarball"
  test -n "$RELEASE_VER" && release="installable image version $RELEASE_VER"

  banner "Building $target $release"

}

make_clean()
{
  rm -rf $VIZIO_APPLETV_INSTALL_IMG_DIR_DIR
}


#=============================================================================
# start of execution
#=============================================================================
parse_arguments $*

# set up platform-independent environment variables
VIZIO_APPLETV_BUILD_ROOT=$(realpath $(dirname $0))
echo "RAMYA VIZIO_APPLETV_BUILD_ROOT = " $VIZIO_APPLETV_BUILD_ROOT
VIZIO_APPLETV_ROOT=`realpath $VIZIO_APPLETV_BUILD_ROOT/..`
echo "RAMYA VIZIO_APPLETV_ROOT= " $VIZIO_APPLETV_ROOT
#CONJURE_EXTRAS_DIR=`realpath $CONJURE_BUILD_ROOT/extras`
#echo "RAMYA CONJURE_EXTRAS_DIR= " $CONJURE_EXTRAS_DIR
#mkdir -p $VIZIO_APPLETV_ROOT/vizio_appletv_basic_egl
VIZIO_APPLETV_BASICEGL_ROOT=$VIZIO_APPLETV_ROOT/vizio_appletv_basic_egl
echo "RAMYA VIZIO_APPLETV_BASICEGL_ROOT= " $VIZIO_APPLETV_BASICEGL_ROOT
mkdir -p $VIZIO_APPLETV_ROOT/vizio_appletv_out
VIZIO_APPLETV_BASICEGLOUT_DIR=$VIZIO_APPLETV_ROOT/vizio_appletv_out
echo "RAMYA VIZIO_APPLETV_BASICEGLOUT_DIR= " $VIZIO_APPLETV_BASICEGLOUT_DIR 

mkdir -p $VIZIO_APPLETV_ROOT/vizio_appletv_install/work
VIZIO_APPLETV_IMG_WORKDIR=$VIZIO_APPLETV_ROOT/vizio_appletv_install/work
echo "RAMYA VIZIO_APPLETV_IMG_WORKDIR= " $VIZIO_APPLETV_IMG_WORKDIR

mkdir -p $VIZIO_APPLETV_ROOT/vizio_appletv_install/img
VIZIO_APPLETV_INSTALL_IMG_DIR=$VIZIO_APPLETV_ROOT/vizio_appletv_install/img
echo "RAMYA VIZIO_APPLETV_INSTALL_IMG_DIR= "$VIZIO_APPLETV_INSTALL_IMG_DIR

mkdir -p $VIZIO_APPLETV_ROOT/vizio_appletv_install/dev
VIZIO_APPLETV_DEV_IMG_DIR=$APPLETV_ROOT/vizio_appletv_install/dev
echo "RAMYA VIZIO_APPLETV_DEV_IMG_DIR= " $VIZIO_APPLETV_DEV_IMG_DIR

# set up platform-dependent environment variables & functions
source $VIZIO_APPLETV_BUILD_ROOT/$incl

show_settings

if [ $MAKE_CLEAN -ne 0 ]; then
  banner "Cleaning up previous builds"
  make_clean
fi

if [ -n "$RELEASE_VER" ]; then
  banner "Building installable image"
  # build_install_img sets $FINAL_IMG_FILE
  build_install_img $RELEASE_VER $VIZIO_APPLETV_INSTALL_IMG_DIR
  banner "Installable image:
$FINAL_IMG_FILE"

else
  banner "Building development tarball"
  build_dev_tarball $VIZIO_APPLETV_DEV_IMG_DIR
  banner "Development tarball:
`ls $RELEASE_VER $VIZIO_APPLETV_DEV_IMG_DIR/*tgz`"
fi
