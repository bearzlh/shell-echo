#!/bin/sh
#自动将php扩展复制到php源码的扩展目录，并执行编译

#源码目录,下级为各php版本的安装目录，格式：php-5.3.29
PHP_SRC_DIR="/data/src/php/"

#对哪些源码的php版本进行编译
#TO_MAKE_LIST=`ls $PHP_SRC_DIR`
#只对第一个版本进行编译
TO_MAKE_LIST=`ls $PHP_SRC_DIR | grep "5.3.29"`

#日志文件
LOG=/data/log/module_install

#安装目录,下级为各php版本的目录，格式：5.3.29_zts
PHP_INSTALLED_DIR="/data/software/php/"

#扩展目录
MODULE_DIR="/data/src/SeasLog/"

#扩展名
MODULE_NAME=seaslog

#加载日志脚本
. /data/src/shell/log.sh

#遍历源文件
for php in $TO_MAKE_LIST
do
    #获取源文件版本号
    version=`echo $php|cut -d '-' -f2`
    #查看安装版本
    for php_installed in `ls $PHP_INSTALLED_DIR|grep $version`
    do
        php_installed_dir=$PHP_INSTALLED_DIR$php_installed/
        php_source_dir=$PHP_SRC_DIR$php/
        ext_dir=${php_source_dir}/ext/
        php_module_dir=$ext_dir`basename $MODULE_DIR`
        cp -rf $MODULE_DIR $ext_dir

        #编译
        cd $php_module_dir
        log "make distclean"
        make distclean >> $LOG 2>&1
        log "${php_installed_dir}bin/phpize"
        ${php_installed_dir}bin/phpize >> $LOG 2>&1
        log "./configure --with-php-config=${php_installed_dir}bin/php-config"
        ./configure --with-php-config=${php_installed_dir}bin/php-config >> $LOG 2>&1
        log "sed -i 's/-g /-g3 -gdwarf-2 /g' Makefile"
        sed -i 's/-g /-g3 -gdwarf-2 /g' Makefile
        log "make"
        make >> $LOG 2>&1
        log "make install"
        make install >> $LOG 2>&1

        ini_file=${php_installed_dir}lib/php.ini
        #如果配置文件不存在则创建
        if [ ! -f  ini_file ];then
            log "cp ${php_source_dir}php.ini-development $ini_file"
            cp ${php_source_dir}php.ini-development $ini_file
        fi
        log "sed -i -e "/$MODULE_NAME/d" $ini_file"
        sed -i -e "/$MODULE_NAME/d" $ini_file
        log "sed -i -e '$a'extension=${MODULE_NAME}.so $ini_file"
        sed -i -e '$a'extension=${MODULE_NAME}.so $ini_file
        log "sed -i 's/;date.timezone.*/date.timezone=PRC/' $ini_file"
        sed -i 's/;date.timezone.*/date.timezone=PRC/' $ini_file
        info "${php} make completed"
    done
done
info "all task completed"
