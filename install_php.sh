#!/bin/sh
#批量编译安装php。只编译php-fpm,apache的libphp,debug选项，分是否支持zts两个版本

#日志文件
LOG=/data/log/php_install

#安装到哪个目录
TARGET_DIR='/data/software/php/'

#so文件放置到的目录
SO_DIR='/data/software/php/so_dir/'

#php源码目录，名称格式：php-5.3.29
PHP_SRC_DIR="/data/src/php/"

#apache的模块目录
APACHE_DIR='/data/software/apache/'

#待安装的php目录列表
TO_INSALL_LIST=`ls $PHP_SRC_DIR`

#启用debug选项,如果为空则不开启
DEBUG='--enable-debug'

#空格替换符号
SPLIT='||'

#zts选项
zts_flag="--enable-maintainer-zts ${SPLIT}"

#5.3的配置
setting_53_list="--enable-fpm --with-apxs2=${APACHE_DIR}bin/apxs"

#5.3+的配置
setting_53_plus_list="--enable-fpm${SPLIT}--with-apxs2=${APACHE_DIR}bin/apxs"

#加载日志文件
. ./log.sh

#备份so文件
backUpSo()
{
    module_dir=${APACHE_DIR}modules
    php_so=`ls $module_dir | grep php`
    if [ -f $module_dir/$php_so ];then
        mv $module_dir/$php_so $SO_DIR${1}.so
    fi
}

#编译
runMake()
{
    #兼容5.3版本不可以同时添加apache与php-fpm参数
    for set in $setting
    do
        #zts选项
        for zts in $zts_flag
        do
            flags=`echo "$DEBUG $zts $set" | sed "s/"${SPLIT}"/ /g"  | sed 's/ \+/ /g'`
            suffix=$version
            if [[ "$flags" == *zts* ]];then
                suffix=${suffix}_zts
            else
                suffix=${suffix}_nts
            fi

            make dist clean >> $LOG 2>&1
            log "./configure --prefix=${TARGET_DIR}${suffix} $flags"
            make clean >> $LOG 2>&1
            ./configure --prefix=${TARGET_DIR}${suffix} $flags >> $LOG 2>&1
            log "configure over"
            make >> $LOG 2>&1
            log "make over"
            make install >> $LOG 2>&1
            log "install over"
            if [[ "$flags" == *apxs*  ]];then
                backUpSo $suffix
            fi
            cp php.ini-development ${TARGET_DIR}${suffix}/lib/php.ini
            info "successful $suffix with $flags"
        done
    done
}

#遍历php版本并执行安装
for php in $TO_INSALL_LIST
do
    version=`echo $php|cut -d '-' -f2`
    #查看大版本
    if [ `echo $version | cut -d "." -f1,2` == "5.3" ];then
        setting=$setting_53_list
    else
        setting=$setting_53_plus_list
    fi
    cd $PHP_SRC_DIR$php
    runMake "$setting" "$version"
done
