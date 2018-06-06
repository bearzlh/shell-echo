#!/bin/sh
#批量编译安装php

#load main function file
source ./main.sh

LIB='libjpeg-turbo-devel libmcrypt-devel libpng-devel libmcrypt-devel openssl-devel mariadb-devel'

PHP_VERSION_LIST="5.3.29 5.4.45 5.5.38 5.6.34 7.0.4 7.1.15 7.2.5"

PHP_MIRROR=http://cn2.php.net/get/php-{VERSION}.tar.gz/from/this/mirror

#php source dir
PHP_SRC_DIR="/data/src/php/"

#dir to install php
PHP_SOFTWARE_DIR='/data/software/php/'

#log file
LOG=/data/log/install_php

#dir to backup libphp[57].so
SO_DIR='/data/software/apache/modules/'

#apache dir
APACHE_DIR='/data/software/apache/'

#optional flag to install php
PHP_INSTALL_FLAGS="--with-pdo-mysql --with-mysqli --with-curl --with-mcrypt --with-openssl --enable-mbstring --with-gd --enable-zip --enable-fpm --with-apxs2=${APACHE_DIR}bin/apxs"

#pattern to replace space
SPLIT='||'

#zts and nts
zts_flag="--enable-maintainer-zts ${SPLIT}"


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_install_version
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
get_install_version ()
{
    echo $PHP_VERSION_LIST| sed -n 's/ /\n/gp' | grep -E "$1"
}	# ----------  end of function get_install_version  ----------
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
    version_list=`get_install_version $1`
    for php_version in $version_list; do
        mirror=`echo $PHP_MIRROR | sed -n "s/{VERSION}/$php_version"/p`
        download $PHP_SRC_DIR php-${php_version}.tar.gz $mirror
    done
}	# ----------  end of function check_file  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check_libs
#   DESCRIPTION:  install libs if not installed
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
check_libs()
{
    for lib in $LIB
    do
        log "check $lib"
        rpm -q $lib>/dev/null 2>&1
        if [ $? != 0 ];then
            exec_cmd "yum -y install $lib"
        fi
        info "ok"
    done
}	# ----------  end of function check_libs  ----------


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
    check_libs
    check_file $1
    #待安装的php目录列表
    TO_INSALL_VERSION_LIST=`get_install_version $1`

    for version in $TO_INSALL_VERSION_LIST
    do
        exec_cmd "cd ${PHP_SRC_DIR}php-$version"
        #zts flag
        for zts in $zts_flag
        do
            #remove apache flag if php_version=5.3
            if [ `echo $version | cut -d "." -f1,2` == "5.3" ];then
                flags=`echo $PHP_INSTALL_FLAGS | sed -n "s/--with-apxs2=\\/data\\/software\\/apache\\/bin\\/apxs//p"`
            else
                flags="$PHP_INSTALL_FLAGS"
            fi

            #replace space back
            flags=`echo "$flags $zts" | sed "s/"$SPLIT"/ /g"  | sed 's/ \+/ /g'`

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


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
check ()
{
    TO_INSALL_VERSION_LIST=`get_install_version $1`
    info "install as follows:`echo $TO_INSALL_VERSION_LIST | xargs`"
}	# ----------  end of function check  ----------

check_dir

#execute the command
case $1 in
    "i" | "install")
        install $2
        ;;

    "c" | "check")
        check $2
        ;;

    *)
        print_info "Usage:   ./$0 (i)nstall [php version]"
        print_info "\t ./$0 (c)heck [php version] (dump info,not install)"
        ;;

    esac
