#!/bin/sh
#批量编译安装php

LIB='libjpeg-turbo-devel libmcrypt-devel libpng-devel libmcrypt-devel openssl-devel'

#php源码目录，名称格式：php-5.3.29
PHP_SRC_DIR="/data/src/php/"

#日志文件
LOG=/data/log/php_install

#安装到哪个目录
TARGET_DIR='/data/software/php/'

#so文件放置到的目录
SO_DIR='/data/so_dir/'

#apache的模块目录
APACHE_DIR='/data/software/apache/'

#启用debug选项,如果为空则不开启
DEFAULT="--with-pdo-mysql --with-mysqli --with-curl --with-mcrypt --with-openssl --enable-mbstring --with-gd --enable-zip --enable-fpm --with-apxs2=${APACHE_DIR}bin/apxs"

#空格替换符号
SPLIT='||'

#zts选项
zts_flag="--enable-maintainer-zts ${SPLIT}"

#apax_flag="--with-apxs2=${APACHE_DIR}bin/apxs"

#加载日志文件
. ./log.sh
checkEnv()
{
   for lib in $LIB
   do
       count=`rpm -ql $lib|wc -l`
       if [ $count -eq 1 ];then
           log "$lib required,installing"
           yum -y install $lib>>$LOG 2>&1
           if [ $? != 0 ];then
               error "$lib install error"
           else
               info "$lib installed"
           fi
       fi
   done
}

checkEnv
#备份so文件
backUpSo()
{
    version=$1
    main_version=`echo $1 | cut -d "." -f1`

    if [ ! -d $SO_DIR ];then
        mkdir -p $SO_DIR
    fi
    module_dir=${APACHE_DIR}modules
    php_so="libphp${main_version}.so"
    if [ -f "$module_dir/$php_so" ];then
        mv $module_dir/$php_so $SO_DIR${version}.so
    fi
}

#编译
runMake()
{
    #zts选项
    for zts in $zts_flag
    do
        if [ `echo $version | cut -d "." -f1,2` == "5.3" ];then
            DEFAULT=`echo $DEFAULT | sed -n "s/--with-apxs2=\\/data\\/software\\/apache\\/bin\\/apxs//p"`
        fi
       flags=`echo "$DEFAULT $zts" | sed "s/"$SPLIT"/ /g"  | sed 's/ \+/ /g'`

        suffix=$version
        if [[ ! -z `echo "$flags" | grep "zts"` ]];then
            suffix=${suffix}_zts
        else
            suffix=${suffix}_nts

        fi

        log "make distclean"
        make distclean >> $LOG 2>&1
        log "./configure --prefix=${TARGET_DIR}${suffix} $flags"
        ./configure --prefix=${TARGET_DIR}${suffix} $flags >> $LOG 2>&1
        if [ $? != 0 ];then
            error "result-error:configure for $verion;continue\n"
            continue;
        fi
        log "sed -i 's/-g /-g3 -gdwarf-2 /g' Makefile"
        sed -i 's/-g /-ggdb3 /g' Makefile
        log "make"
        if [ $? != 0 ];then
            error "result-error:make for $version;continue\n"
            continue;
        fi
        make >> $LOG 2>&1

        log "make install"
        #remove php installed dir if exists
        if [ -d "${TARGET_DIR}${suffix}" ];then
            log "rm -rf ${TARGET_DIR}${suffix}"
            rm -rf ${TARGET_DIR}${suffix}
        fi

        #backup libphp[57].so if created
        make install >> $LOG 2>&1
        if [[ "$flags" == *apxs*  ]];then
            log "backUpSo $suffix"
            backUpSo $suffix
        fi

        log "php.ini-development ${TARGET_DIR}${suffix}/lib/php.ini"
        cp php.ini-development ${TARGET_DIR}${suffix}/lib/php.ini
        info "result-success: $suffix with $flags"
    done
}

#遍历php版本并执行安装
install ()
{
    #待安装的php目录列表
    TO_INSALL_LIST=`ls $PHP_SRC_DIR | grep "tar.gz" | grep -E "$1"`

    for php in $TO_INSALL_LIST
    do
        log "cd $PHP_SRC_DIR"
        cd $PHP_SRC_DIR

        dirname=${php%.tar*}
        if [ -d "$dirname" ];then
            log "remove $dirname if exists"
            log "rm -rf $dirname"
            rm -rf $dirname
        fi

        log "untar $php"
        tar zxf $php
        version=`echo $dirname|cut -d '-' -f2`

        log "cd $PHP_SRC_DIR$dirname"
        cd $PHP_SRC_DIR$dirname
        runMake "$version"
    done
}

case $1 in
    "i" | "install")
        install $2
        ;;

    *)
        log "./install_php.sh (i)nstall"
        ;;

    esac
