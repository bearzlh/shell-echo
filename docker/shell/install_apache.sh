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
#         NOTES: install apache-2.4.33 automatically
#        AUTHOR: Bear.Zheng (https://github.com/bearlzh), bear.zheng@cloudwise.com
#  ORGANIZATION: ChinaCloudwise
#       CREATED: 2018年06月01日 13时08分22秒
#      REVISION:  ---
#===============================================================================
source ./main.sh
INSTALL_LIST="APR APR_UTIL APACHE"

#APACHE_VERSION=2.4.33
#APR_VERSION=1.6.3
#APR_UTIL_VERSION=1.6.1
#IF_FASTCGI=1

APACHE_MIRROR=http://archive.apache.org/dist/httpd/httpd-${APACHE_VERSION}.tar.gz
APR_MIRROR=http://archive.apache.org/dist/apr/apr-${APR_VERSION}.tar.gz
APR_UTIL_MIRROR=http://archive.apache.org/dist/apr/apr-util-${APR_UTIL_VERSION}.tar.gz

SRC_DIR=/opt/src/
APACHE_PREFIX=/data/software/apache
APR_PREFIX="/data/software/apr"
APR_UTIL_PREFIX=/data/software/apr_util

LOG=/data/log/install_apache

APACHE_FLAGS="--enable-so --enable-rewrite --with-apr=$APR_PREFIX --with-apr-util=$APR_UTIL_PREFIX"
APR_FLAGS=""
APR_UTIL_FLAGS="--with-apr=$APR_PREFIX"

LIBS="openssl-devel wget gcc make expat-devel pcre-devel"

if [ ! -d $(dirname $LOG) ];then
    mkdir -p $(dirname $LOG)
fi

if [ ! -d "$SRC_DIR" ];then
    mkdir -p $SRC_DIR
fi


if [ ! -z "$APACHE_FLAG" ] ; then
    APACHE_FLAGS="$APACHE_FLAGS $APACHE_FLAG"
fi

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check_file
#   DESCRIPTION:  download source file if not exists
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
check_file()
{
    for file in $INSTALL_LIST; do

        mirror=`eval echo '$'${file}_MIRROR`
        tar_file=`basename $mirror`

        download $SRC_DIR $tar_file $mirror
    done
}	# ----------  end of function check_file  ----------


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  install
#   DESCRIPTION:  install in order
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
install()
{
    for file in $INSTALL_LIST; do

        mirror=`eval echo '$'${file}_MIRROR`
        flags=`eval echo '$'${file}_FLAGS`
        tar_file=`basename $mirror`
        dir=${tar_file%.tar*}
        prefix=`eval echo '$'${file}_PREFIX`

        if [ -d $prefix ] ; then
            log "$dir installed;continue"
            continue
        fi

        SOURCE_DIR=${SRC_DIR}${dir}/
        log "cd $SOURCE_DIR"
        cd $SOURCE_DIR

        exec_cmd "./configure --prefix=$prefix $flags"

        exec_cmd "make"

        exec_cmd "make install"
        
        if [ $file == "APACHE" -a -d "${SRC_DIR}conf/apache" ] ; then
            exec_cmd "cp -r ${SRC_DIR}conf/apache/* ${prefix}/conf/"
        fi
        info "installed $dir successful with path of `dirname $prefix`"
    done

    if [ ! -z "$IF_FASTCGI" ] ; then
        install_fastcgi
    fi
}


install_fastcgi ()
{
    #exec_cmd "git clone https://github.com/ByteInternet/libapache-mod-fastcgi"
    exec_cmd "cd ${SRC_DIR}libapache-mod-fastcgi"
    exec_cmd "patch -p1 < ../patch.diff"
    exec_cmd "cp Makefile.AP2 Makefile"
    exec_cmd "sed -i 's#^top_dir.*#top_dir=/data/software/apache#' Makefile"
    exec_cmd "make"
    exec_cmd "make install"
    exec_cmd "sed -i '/mod_fastcgi.so/d' ${APACHE_PREFIX}/conf/httpd.conf"
    exec_cmd "sed -i '\$a\LoadModule fastcgi_module modules/mod_fastcgi.so' ${APACHE_PREFIX}/conf/httpd.conf"
    exec_cmd "sed -i 's#.*vhosts.conf#Include conf/extra/httpd-vhosts-fastcgi.conf#' ${APACHE_PREFIX}/conf/httpd.conf"
}	# ----------  end of function install_fastcgi  ----------

case $1 in
    "i" | "install")

        if [ -z "$APACHE_VERSION" ] ; then
            error "apache will not be installed with apache version empty"
        else
            check_libs "$LIBS"
            check_file
            install
        fi

        ;;
    "f" | "fastcgi")
        install_fastcgi
        ;;
    *)
        info "help:./$0 (i)stall"
        ;;

    esac    # --- end of case ---
