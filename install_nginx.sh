#!/bin/bash -
#===============================================================================
#
#          FILE: install_nginx.sh
#
#         USAGE: ./install_nginx.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: nginx with php-fpm
#        AUTHOR: Bear.Zheng (https://github.com/bearzlh), bear.zheng@cloudwise.com
#  ORGANIZATION: ChinaCloudwise
#       CREATED: 2018年06月02日 16时20分29秒
#      REVISION:  ---
#===============================================================================

source ./main.sh
NGINX_VERSION=1.14.0
NGINX_MIRROR=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
NGINX_PREFIX=/data/software/nginx
NGINX_FLAGS=""

SRC_DIR=/data/src/

LOG=/data/log/install_nginx



#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check_file
#   DESCRIPTION:  download and untar nginx source
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
check_file ()
{
    if [ ! -f "$SRC_DIR$dir" ] ; then
        tar_file=`basename $NGINX_MIRROR`
        dir=${tar_file%.tar*}
        if [ ! -f "$tar_file" ] ; then
            download $SRC_DIR $dir $NGINX_MIRROR
        fi
    fi
}	# ----------  end of function check_file  ----------


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  install
#   DESCRIPTION:  install nginx
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
install ()
{
    tar_file=`basename $NGINX_MIRROR`
    dir=${tar_file%.tar*}

    if [ -d $NGINX_PREFIX ] ; then
        info "$NGINX_PREFIX exists,exit"
        exit
    fi

    check_file

    cd $SRC_DIR$dir
    exec_cmd "./configure --prefix=$NGINX_PREFIX $NGINX_FLAGS" 
    exec_cmd "make"
    exec_cmd "make install"

    info "installed $dir successful with path:`dirname $NGINX_PREFIX`"
}	# ----------  end of function install  ----------

case $1 in
    "i" | "install")
        install
        ;;

    *)
        info "help:./$0 i"
        ;;

    esac    # --- end of case ---
