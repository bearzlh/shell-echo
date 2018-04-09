#!/bin/sh
#自动将php扩展复制到php源码的扩展目录，并执行编译

#源码目录,下级为各php版本的安装目录，格式：php-5.3.29
PHP_SRC_DIR="/data/src/php/"

#对哪些源码的php版本进行编译
#TO_MAKE_LIST=`ls $PHP_SRC_DIR`
#只对第一个版本进行编译
TO_MAKE_LIST=`ls $PHP_SRC_DIR | sed -n '1p'`

#日志文件
LOG=/data/log/module_install

#安装目录,下级为各php版本的目录，格式：5.3.29_zts
PHP_INSTALLED_DIR="/data/software/php/"

#扩展目录
MODULE_DIR="/data/src/SeasLog/"

#扩展名
MODULE_NAME=seaslog

#加载日志脚本
. ./log.sh

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
        if [ ! -d $php_module_dir ];then
            cp -r $MODULE_DIR $ext_dir
        fi

        #编译
        log "make $MODULE_NAME for $php_installed"
        cd $php_module_dir
        make clean >> $LOG 2>&1
        $php_installed_dir/bin/phpize >> $LOG 2>&1
        ./configure --with-php-config=$php_installed_dir/bin/php-config >> $LOG 2>&1
        log "configure completed"
        make >> $LOG 2>&1
        log "make completed"
        make install >> $LOG 2>&1
        log "install completed"

        #如果配置文件不存在则创建
        if [ ! -f $php_installed_dir/lib/php.ini ];then
            cp ${php_source_dir}php.ini-development $php_installed_dir/lib/php.ini
        fi
        sed -i -e "/$MODULE_NAME/d" $php_installed_dir/lib/php.ini
        sed -i -e '$a'extension=${MODULE_NAME}.so $php_installed_dir/lib/php.ini
        sed -i 's/;date.timezone.*/date.timezone=PRC/' $php_installed_dir/lib/php.ini 
        log "php.ini edit"
        info "${php} make completed"
    done
done
info "all task completed"
