#!/bin/bash -
#===============================================================================
#
#          FILE: install_apache.sh
#
#         USAGE: ./install_apache.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Bear.Zheng (https://github.com/bearlzh), bear.zheng@cloudwise.com
#  ORGANIZATION: ChinaCloudwise
#       CREATED: 2018年06月01日 13时08分22秒
#      REVISION:  ---
#===============================================================================

APACHE_DIR=/data/src/httpd-2.2.31
PREFIX=/data/software/apache2
LOG=/data/log/install_apache
FLAGS="--enable-so --enable-rewrite"
LIBS="apr-devel apr-util-devel openssl-devel"
. ./log.sh

if [ ! -d $(dirname $LOG) ];then
    mkdir -p $(dirname $LOG)
fi

for lib in $LIBS; do
    rpm -q $lib > /dev/null
    if [ $? != 0 ]; then
        log "$lib is required"
        package_count=$(yum search $lib | grep $lib | wc -l)
        if [ $package_count > 1 ];then
            log "$lib installing"
            yum -y install $lib >> LOG 2>&1
            if [ $? != 0 ];then
                error "$lib install failed;exit"
                exit
            else
                info "$lib installed successful"
            fi
        else
            error "$lib is missing;exit"
            exit
        fi
    fi
done

install()
{
    log "cd $APACHE_DIR"
    cd $APACHE_DIR

    log "./configure --prefix=$PREFIX $FLAGS >> $LOG 2>&1"
    ./configure --prefix=$PREFIX $FLAGS >> $LOG 2>&1
    if [ $? != 0 ];then
        error "result-error:configure;exit"
        exit
    fi

    log "make..."
    make >> $LOG 2>&1
    if [ $? != 0 ];then
        error "result-error:make;exit"
        exit
    fi

    log "make install"
    make install >> $LOG 2>&1
    if [ $? != 0 ];then
        error "result-error:make install;exit"
        exit
    fi

    info "install successful"

}

case $1 in
    "i" | "install")
        install
        ;;

    *)
        info "help:./install_apache.sh (i)stall"
        ;;

    esac    # --- end of case ---
