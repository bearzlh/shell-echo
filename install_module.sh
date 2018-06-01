#===============================================================================
#
#          FILE: install_module.sh
#
#         USAGE: ./install_module.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Bear.Zheng (https://github.com/bearzlh), bear.zheng@cloudwise.com
#  ORGANIZATION: ChinaCloudwise
#       CREATED: 2018年06月01日 04时36分22秒
#      REVISION:  ---
#===============================================================================
#!/bin/sh
#自动将php扩展复制到php源码的扩展目录，并执行编译

#log file
LOG=/data/log/module_install

#php source dir
PHP_SRC_DIR="/data/src/php/"

#php installed dir with format: 5.3.29_zts
PHP_INSTALLED_DIR="/data/software/php/"

#extension source dir
MODULE_DIR="/data/src/module7/"

#include log function
. /data/src/shell/log.sh

#install extension
install(){
    #param process
    param_module="$1"
    param_php="$2"

    #extension filter
    if [ ! -z "param_module" ];then
        MODULE_NAMES=`ls $MODULE_DIR|grep -E "$param_module"`
    else
        MODULE_NAMES="smart_agent"
    fi

    grep_version=
    grep_zts=

    #version and zts filter
    if [ ! -z "$param_php" ];then
        if [ -z "`echo $param_php | grep '-'`" ];then
            grep_version=$param_php
        else
            grep_version=`echo $param_php|cut -d '-' -f1`
            grep_zts=`echo $param_php|cut -d '-' -f2`
        fi
    fi

    #filter php and zts type
    TO_MAKE_LIST=`ls $PHP_SRC_DIR|grep -v "tar"|grep "$grep_version"`
    installed_dirs=`ls /data/software/php/ | grep "$grep_zts"`

    for php in $TO_MAKE_LIST
    do
        #php version
        version=`echo $php|cut -d '-' -f2`

        #php installed version,with zts and nts
        installed_dir_list=`echo "$installed_dirs"|grep $version`

        #traversal php installed dirs
        for php_installed in $installed_dir_list
        do

            #traversal extension dirs
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
                    log "add module dir from extension source"
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
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_file_modify_time
#   DESCRIPTION:  get modify time of file
#    PARAMETERS:  file_path
#       RETURNS:  time
#-------------------------------------------------------------------------------
get_file_modify_time ()
{
    path="$1"
    if [ ! -f $1 ];then
        error "$1 not exists"
    else
        echo `stat $1 | sed -n "7p"|cut -d " " -f2`
    fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  restart
#   DESCRIPTION:  restart php-fpm
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
restart()
{
    log "stop php-fpm..."
    if [ `ps -ef | grep php-fpm | wc -l` -gt 1 ];then
        killall php-fpm
    else
        log "php-fpm thread not exists"
    fi
    
    log "start php-fpm..."
    result=`php-fpm`
    
    if [ ! -z "$result" ];then
        error "result-error=>php-fpm start message:$result"
        exit
    else
        info "ok"
    fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  test
#   DESCRIPTION:  test module
#    PARAMETERS:  php version
#       RETURNS:  
#-------------------------------------------------------------------------------
test ()
{
    param_version="$1"

    test_list=`ls $PHP_INSTALLED_DIR | grep -E "$1"`

    for php in $test_list; do
        export PHP="$php"
        source ~/.bashrc
        log_path="/data/log/phpagent/trace_data.json"
        restart

        time_pre=`get_file_modify_time $log_path`
        curl 'http://192.168.100.100/admin/student/index?sort=id&order=desc&offset=0&limit=10&_=1527844738037' -H 'Cookie: thinkphp_show_page_trace=0|0; thinkphp_show_page_trace=0|0; PHPSESSID=bui9a3omlap0chtt9k1nuin51j; XDEBUG_SESSION=IDEKEY; keeplogin=1%7C86400%7C1527931135%7C7e3e73afb96824b6c95fcc50f181ae36' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.139 Safari/537.36' -H 'Content-Type: application/json' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Referer: http://192.168.100.100/admin/student?addtabs=1' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' --compressed >> /dev/null
        time_end=`get_file_modify_time $log_path`

        log $time_pre
        log $time_end
        if [ "$time_pre" != "$time_end" ];then
            info "log updated ok"
        else
            error "log updated false"
            continue
        fi

        cat $log_path | jq . >> /dev/null 2>&1
        if [ $? != 0 ];then
            error "json format error"
            continue
        else
            info "format ok"
        fi

        count=$(cat $log_path | jq . | grep array | uniq | wc -l)
        if [ $count != 1 ];then
            error "blacknames filter error"
        else
            info "filter ok"
        fi
    done
}

#命令列表
case $1 in
    "install"|"i")
        install "$2" "$3"
        ;;

    "restart")
        restart
        ;;

    "test")
        test $2
        ;;

esac
