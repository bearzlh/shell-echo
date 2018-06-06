#!/bin/sh
#批量编译安装php

#load main function file
source ./main.sh

LIBS='wget make gcc epel-release libjpeg-turbo-devel libmcrypt-devel libpng-devel libmcrypt-devel openssl-devel mariadb-devel libxml2-devel libcurl-devel'

#PHP_VERSIONS="5.3.29 5.4.45 5.5.38 5.6.34 7.2.5"
#IF_APACHE=
#IF_FPM=
#ZTS_FLAGS='zts nts'

PHP_MIRROR=http://cn2.php.net/get/php-{VERSION}.tar.gz/from/this/mirror

#php source dir
PHP_SRC_DIR="/opt/src/php/"

#dir to install php
PHP_SOFTWARE_DIR='/data/software/php/'

#log file
LOG=/data/log/install_php

#dir to backup libphp[57].so
SO_DIR='/data/software/apache/modules/'

#apache dir
APACHE_DIR='/data/software/apache/'

#optional flag to install php
PHP_INSTALL_FLAGS="--with-pdo-mysql --with-mysqli --with-curl --with-mcrypt --with-openssl --enable-mbstring --with-gd --enable-zip"

APACHE_FLAG="--with-apxs2=${APACHE_DIR}bin/apxs"

if [ ! -z "$IF_FPM" ] ; then
    PHP_INSTALL_FLAGS="$PHP_INSTALL_FLAGS --enable-fpm"
fi

if [ ! -z "$IF_APACHE" ] ; then
    PHP_INSTALL_FLAGS="$PHP_INSTALL_FLAGS $APACHE_FLAG"
fi

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check_dir
#   DESCRIPTION:  create dir if not exists
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
check_dir ()
{
    dir_list="$PHP_SRC_DIR $PHP_SOFTWARE_DIR $SO_DIR `dirname $LOG`"

    for dir in $dir_list; do
        if [ ! -d $dir ] ; then
            exec_cmd "mkdir -p $dir"
        fi
    done

}	# ----------  end of function check_dir  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check_file
#   DESCRIPTION:  download if not exists
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
check_file ()
{
    for php_version in $PHP_VERSIONS; do
        mirror=`echo $PHP_MIRROR | sed -n "s/{VERSION}/$php_version"/p`
        download $PHP_SRC_DIR php-${php_version}.tar.gz $mirror
    done
}	# ----------  end of function check_file  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  backup_so
#   DESCRIPTION:  backup libphp[57].so for apache
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
backup_so()
{
    version_ts=$1
    main_version=`echo $version_ts | cut -d "." -f1`
    module_dir=${APACHE_DIR}modules
    php_so=libphp${main_version}.so

    exec_cmd "cp $module_dir/$php_so $SO_DIR${version_ts}.so"
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  install
#   DESCRIPTION:  install php
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
install ()
{
    check_libs "$LIBS"
    check_file
    #待安装的php目录列表
    TO_INSALL_VERSION_LIST=`echo $PHP_VERSIONS | grep -E "$1"`

    for version in $TO_INSALL_VERSION_LIST
    do
        exec_cmd "cd ${PHP_SRC_DIR}php-$version"
        #zts flag
        for zts in $ZTS_FLAGS
        do
            if [ $zts == "zts" ] ; then
                ts_flag='--enable-maintainer-zts'
            else
                ts_flag=''
            fi

            #replace space back
            flags=`echo "$PHP_INSTALL_FLAGS $ts_flag" | sed 's/ \+/ /g'`

            if [[ ! -z `echo "$flags" | grep "zts"` ]];then
                version_ts=${version}_zts
            else
                version_ts=${version}_nts
            fi

            make distclean>/dev/null 2>&1
            exec_cmd "./configure --prefix=${PHP_SOFTWARE_DIR}${version_ts} $flags"
            exec_cmd "sed -i 's/-g /-ggdb3 /g' Makefile"
            exec_cmd "make"
            #remove php installed dir if exists
            if [ -d "${PHP_SOFTWARE_DIR}${version_ts}" ];then
                exec_cmd "rm -rf ${PHP_SOFTWARE_DIR}${version_ts}"
            fi

            #backup libphp[57].so if created
            exec_cmd "make install"
            if [[ ! -z "`echo $flags|grep apxs`"  ]];then
                exec_cmd "backup_so $version_ts"
            fi

            exec_cmd "cp php.ini-development ${PHP_SOFTWARE_DIR}${version_ts}/lib/php.ini"
            info "result-success: $version_ts with $flags"
        done
    done
}

check_dir

#execute the command
case $1 in
    "i" | "install")
        if [ -z "$PHP_VERSIONS" ] ; then
            error "php will not be installed with php version empty"
        else
            install $2
        fi
        ;;

    *)
        log "./install_php.sh (i)nstall"
        ;;

    esac
