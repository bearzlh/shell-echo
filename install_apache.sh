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

INSTALL_LIST="APR APR_UTIL APACHE"

APACHE_VERSION=2.4.33
APR_VERSION=1.6.3
APR_UTIL_VERSION=1.6.1

APACHE_MIRROR=http://archive.apache.org/dist/httpd/httpd-${APACHE_VERSION}.tar.gz
APR_MIRROR=http://archive.apache.org/dist/apr/apr-${APR_VERSION}.tar.gz
APR_UTIL_MIRROR=http://archive.apache.org/dist/apr/apr-util-${APR_UTIL_VERSION}.tar.gz

SRC_DIR=/data/src/
APACHE_PREFIX=/data/software/apache
APR_PREFIX="/data/software/apr"
APR_UTIL_PREFIX=/data/software/apr_util

LOG=/data/log/install_apache

APACHE_FLAGS="--enable-so --enable-rewrite --with-apr=$APR_PREFIX --with-apr-util=$APR_UTIL_PREFIX"
APR_FLAGS=""
APR_UTIL_FLAGS="--with-apr=$APR_PREFIX"

LIBS="openssl-devel"
. ./log.sh

if [ ! -d $(dirname $LOG) ];then
    mkdir -p $(dirname $LOG)
fi
if [ ! -d "$SRC_DIR" ];then
    mkdir -p $SRC_DIR
fi



#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  exec_cmd
#   DESCRIPTION:  execute shell command
#    PARAMETERS:  command
#       RETURNS:  
#-------------------------------------------------------------------------------
exec_cmd ()
{
    log "execute:$@"
    $@ >> $LOG 2>&1

    if [ $? != 0 ] ; then
        error "result-error:cmd->$1,look $LOG for help"
        exit
    else
        info "ok"
    fi
}	# ----------  end of function exec_cmd  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check_lib
#   DESCRIPTION:  install necessary libs if uninstalled
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
check_lib ()
{
    for lib in $LIBS; do
        rpm -q $lib > /dev/null
        if [ $? != 0 ]; then
            log "$lib is required"
            package_count=$(yum search $lib | grep $lib | wc -l)
            if [ $package_count > 1 ];then
                log "$lib installing"
                exec_cmd "yum -y install $lib"
            else
                error "$lib is missing;exit"
                exit
            fi
        fi
    done

}	# ----------  end of function check_lib  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check_file
#   DESCRIPTION:  download source file if not exists
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
check_file()
{
    for file in $INSTALL_LIST; do
        version=`eval echo '$'${file}_VERSION`
        mirror=`eval echo '$'${file}_MIRROR`
        flags=`eval echo '$'${file}_FLAGS`
        tar_file=`basename $mirror`

        cd $SRC_DIR
        if [ ! -f "$SRC_DIR$tar_file" ] ; then
            exec_cmd "wget -O $tar_file $mirror"
        fi

        dir=${tar_file%.tar*}
        if [ ! -d "$dir" ] ; then
            exec_cmd "tar zxf $tar_file"
        fi
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

        info "installed $dir successful with path of `dirname $prefix`"
    done

}

check_lib
check_file
case $1 in
    "i" | "install")
        install
        ;;

    *)
        info "help:./$0 (i)stall"
        ;;

    esac    # --- end of case ---
