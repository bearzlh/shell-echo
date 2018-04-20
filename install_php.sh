#!/bin/sh
#批量编译安装php。只编译php-fpm,apache的libphp,debug选项，分是否支持zts两个版本

#日志文件
LOG=/data/log/php_install

#安装到哪个目录
TARGET_DIR='/data/software/php/'

#so文件放置到的目录
SO_DIR='/data/so_dir/'

#php源码目录，名称格式：php-5.3.29
PHP_SRC_DIR="/data/src/php/"

#apache的模块目录
APACHE_DIR='/data/software/apache/'

#待安装的php目录列表
TO_INSALL_LIST=`ls $PHP_SRC_DIR | grep 5.3.29`

#启用debug选项,如果为空则不开启
DEBUG='--enable-debug'

#空格替换符号
SPLIT='||'

#zts选项
zts_flag="--enable-maintainer-zts ${SPLIT}"

apax_flag="--with-apxs2=${APACHE_DIR}bin/apxs"
fpm_flag="--enable-fpm"

#加载日志文件
. ./log.sh

#备份so文件
backUpSo()
{
    if [ ! -d $SO_DIR ];then
        mkdir -p $SO_DIR
    fi
    module_dir=${APACHE_DIR}modules
    php_so=`ls $module_dir | grep php`
    if [ -f $module_dir/$php_so ];then
        mv $module_dir/$php_so $SO_DIR${1}.so
    fi
}

#编译
runMake()
{
    #zts选项
    for zts in $zts_flag
    do
        flags=`echo "$DEBUG $zts" | sed "s/"$SPLIT"/ /g"  | sed 's/ \+/ /g'`

        suffix=$version
        if [[ ! -z `echo "$flags" | grep "zts"` ]];then
            flags="$flags $apax_flag"
            suffix=${suffix}_zts
         else
            suffix=${suffix}_nts
            if [ `echo $version | cut -d "." -f1,2` == "5.3" ];then
                $flags="$flags $fpm_flag"
            fi
        
        fi

        log "make distclean"
        make distclean >> $LOG 2>&1
        log "./configure --prefix=${TARGET_DIR}${suffix} $flags"
        ./configure --prefix=${TARGET_DIR}${suffix} $flags >> $LOG 2>&1
        log "sed -i 's/-g /-g3 -gdwarf-2 /g' Makefile"
        sed -i 's/-g /-ggdb3 /g' Makefile
        log "make"
        make >> $LOG 2>&1
        log "make install"
        make install >> $LOG 2>&1
        if [[ "$flags" == *apxs*  ]];then
            log "backUpSo $suffix"
            backUpSo $suffix
        fi
        log "php.ini-development ${TARGET_DIR}${suffix}/lib/php.ini"
        cp php.ini-development ${TARGET_DIR}${suffix}/lib/php.ini
        info "successful $suffix with $flags"
    done
}

#遍历php版本并执行安装
for php in $TO_INSALL_LIST
do
    version=`echo $php|cut -d '-' -f2`
    #查看大版本
    #if [ `echo $version | cut -d "." -f1,2` == "5.3" ];then
    #    setting=$setting_53_list
    #else
    #    setting=$setting_53_plus_list
    #fi
    cd $PHP_SRC_DIR$php
    runMake "$version"
done
