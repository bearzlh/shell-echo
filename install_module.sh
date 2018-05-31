#!/bin/sh
#自动将php扩展复制到php源码的扩展目录，并执行编译

#扩展名
if [ ! -z "$1" ];then
    MODULE_NAMES=$1
else
    MODULE_NAMES="smart_agent"
fi
grep_version=
grep_zts=

if [ ! -z "$2" ];then
    if [ -z "`echo $2 | grep '-'`" ];then
        grep_version=$2
    else
        grep_version=`echo $2|cut -d '-' -f1`
        grep_zts=`echo $2|cut -d '-' -f2`
    fi
fi

#源码目录,下级为各php版本的安装目录，格式：php-5.3.29
PHP_SRC_DIR="/data/src/php/"

#对哪些源码的php版本进行编译
TO_MAKE_LIST=`ls $PHP_SRC_DIR|grep -v "tar"|grep "$grep_version"`

#日志文件
LOG=/data/log/module_install

#安装目录,下级为各php版本的目录，格式：5.3.29_zts
PHP_INSTALLED_DIR="/data/software/php/"
installed_dirs=`ls /data/software/php/ | grep "$grep_zts"`

#扩展目录，扩展目录名需要与扩展名相同
MODULE_DIR="/data/src/module7/"

#加载日志脚本
. /data/src/shell/log.sh

#遍历源文件
for php in $TO_MAKE_LIST
do
    #获取源文件版本号
    version=`echo $php|cut -d '-' -f2`
    installed_dir_list=`echo "$installed_dirs"|grep $version`
    #查看安装版本
    for php_installed in $installed_dir_list
    do
        for MODULE_NAME in $MODULE_NAMES
        do
            php_installed_dir=$PHP_INSTALLED_DIR$php_installed/
            php_source_dir=$PHP_SRC_DIR$php/
            ext_dir=${php_source_dir}ext/

            #create extension dir if not exists
            if [ ! -d $ext_dir ];then
                log "create ext dir"
                log "mkdir $ext_dir"
                mkdir $ext_dir
            fi
            php_module_dir=$ext_dir$MODULE_NAME

            #remove module dir from ext if module dir exists in resource dir
            if [ -d $MODULE_DIR$MODULE_NAME ];then
                if [ -d $php_module_dir ];then
                    log "remove module dir from ext"
                    log "rm -rf $php_module_dir"
                    rm -rf $php_module_dir
                fi
            fi

            #add module dir from source dir
            if [ ! -d $php_module_dir ];then
                log "add module dir from source"
                cp -rf $MODULE_DIR$MODULE_NAME $ext_dir
            fi

            #make===================
            log "cd $php_module_dir"
            cd $php_module_dir

            log "make distclean"
            make distclean >> $LOG 2>&1

            log "${php_installed_dir}bin/phpize"
            ${php_installed_dir}bin/phpize >> $LOG 2>&1

            log "./configure --with-php-config=${php_installed_dir}bin/php-config"
            ./configure --with-php-config=${php_installed_dir}bin/php-config >> $LOG 2>&1

            #if config error
            if [ $? != 0 ];then
                error "result-error=>configure:$php_installed\n"
                continue;
            fi

            #gdb debug
            log "sed -i 's/-g /-g3 -gdwarf-2 /g' Makefile"
            sed -i 's/-g /-g3 -gdwarf-2 /g' Makefile
            log "make"
            make >> $LOG 2>&1

            #if make error
            if [ $? != 0 ];then
                error "result-error=>make:$php_installed\n"
                continue;
            fi

            log "make install"
            make install >> $LOG 2>&1
            #make over===================

            ini_file=${php_installed_dir}lib/php.ini

            #add php.ini if not exists
            if [ ! -f  $ini_file ];then
                log "php.ini not exists"
                log "cp ${php_source_dir}php.ini-development $ini_file"
                cp ${php_source_dir}php.ini-development $ini_file
            fi

            #remove old config
            log "remove old config"
            log "sed -i -e "/$MODULE_NAME/d" $ini_file"
            sed -i -e "/$MODULE_NAME/d" $ini_file

            #add timezone if empty
            if [ -z `cat $ini_file|grep "^date.timezone"|cut -d '=' -f2` ];then
                log "timezone empty,add PRC"
                log "sed -i 's/;date.timezone.*/date.timezone=PRC/' $ini_file"
                sed -i 's/;date.timezone.*/date.timezone=PRC/' $ini_file
            fi

            #add config from file init.tpl if the file exists otherwise add so config only
            if [ -f init.tpl ];then
                log "found config file,init.tpl"
                sed -i "/$MODULE_NAME/d" $ini_file
                sed -i '$r init.tpl' $ini_file
            else
                log "no config file found,add so config only"
                log "sed -i -e "'$a'"extension=${MODULE_NAME}.so $ini_file"
                sed -i -e '$a'extension=${MODULE_NAME}.so $ini_file
            fi
            info "result-success->$php_installed"
        done
    done
done
info "all tasks completed"
log "restart php-fpm"
if [ `ps -ef|grep php-fpm|wc -l` -gt 1 ];then
    killall php-fpm
fi

result=`php-fpm`

if [ ! -z "$result" ];then
   error "result-error=>php-fpm start message:$result"
fi
