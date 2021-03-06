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

#main functions
source ./main.sh

#log file
LOG=/data/log/module_install

#php installed dir
PHP_SOFTWARE_DIR=/data/software/php/


if [ ! -z "$MODULE_DIR_NAME" ] ; then
    MODULE_DIR=/data/modules/$MODULE_DIR_NAME/
fi


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check_version
#   DESCRIPTION:  dump which version to install
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
check_version ()
{
    log "deal as follows"
    #param process
    filter_module="$1"
    filter_php="$2"

    #extension filter
    if [ -d $MODULE_DIR ];then
        MODULE_NAMES=`ls $MODULE_DIR|grep -E "$filter_module"`
    else
        exec_cmd "echo $MODULE_DIR INVALID"
        exit 0
    fi

    grep_version=
    grep_zts=

    #version and zts filter
    if [ ! -z "$filter_php" ];then
        if [ -z "`echo $filter_php | grep '-'`" ];then
            grep_version=$filter_php
        else
            grep_version=`echo $filter_php|cut -d '-' -f1`
            grep_zts=`echo $filter_php|cut -d '-' -f2`
        fi
    fi

    #filter php and zts type
    PHP_SOFTWARE_LIST=`ls $PHP_SOFTWARE_DIR | grep "$grep_version" | grep "$grep_zts"`

    for php in $PHP_SOFTWARE_LIST
    do
        info "$php:`echo $MODULE_NAMES | xargs`"
    done
}	# ----------  end of function check_version  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  install
#   DESCRIPTION:  module install
#    PARAMETERS:  $1:module name;$2 php version
#       RETURNS:  
#-------------------------------------------------------------------------------
install(){
    #param process
    filter_module="$1"
    filter_php="$2"

    #extension filter
    if [ -d $MODULE_DIR ];then
        if [ -z "$filter_module" ] ; then
            MODULE_NAMES=`ls $MODULE_DIR`
        else
            MODULE_NAMES=`ls $MODULE_DIR|grep -E "$filter_module"`
        fi
    else
        info "MODULE_DIR INVALID;exit"
        exit 0
    fi

    grep_version=
    grep_zts=

    #version and zts filter
    if [ ! -z "$filter_php" ];then
        if [ -z "`echo $filter_php | grep '-'`" ];then
            grep_version=$filter_php
        else
            grep_version=`echo $filter_php|cut -d '-' -f1`
            grep_zts=`echo $filter_php|cut -d '-' -f2`
        fi
    fi

    #filter php and zts type
    PHP_SOFTWARE_LIST=`ls $PHP_SOFTWARE_DIR | grep "$grep_version" | grep "$grep_zts"`

    for php in $PHP_SOFTWARE_LIST
    do
        log "install for $php"

        module_names=$MODULE_NAMES
        version=`echo $php|cut -d '_' -f1`

        if [ -z "$module_names" ] ; then
            info "module names not found;continue"
            continue
        fi
        php_software_dir="$PHP_SOFTWARE_DIR$php/"

        #traversal extension dirs
        for MODULE_NAME in $module_names
        do
            (
                exec_cmd "cd $MODULE_DIR$MODULE_NAME"

                make distclean >> /dev/null 2>&1

                exec_cmd "${php_software_dir}bin/phpize"

                exec_cmd "./configure --with-php-config=${php_software_dir}bin/php-config"

                #gdb debug
                exec_cmd "sed -i 's/-g /-g3 -gdwarf-2 /g' Makefile"

                exec_cmd "make"
                
                exec_cmd "make install"

                ini_file=`${php_software_dir}bin/php --ini | sed -n '2p'|awk '{print $NF}'`

                #check php.ini
                exec_cmd "[ -f  $ini_file ]"

                #remove old config
                exec_cmd "sed -i -e "/$MODULE_NAME/d" $ini_file"

                #add timezone if empty
                if [ -z `cat $ini_file|grep "^date.timezone"|cut -d '=' -f2` ];then
                    exec_cmd "sed -i 's/;date.timezone.*/date.timezone=PRC/' $ini_file"
                fi

                #add config from file init.tpl if the file exists otherwise add so config only
                if [ -f init.tpl ];then
                    exec_cmd "sed -i '\$r init.tpl' $ini_file"
                else
                    exec_cmd "sed -i -e '\$a'extension=${MODULE_NAME}.so $ini_file"
                fi
                info "result-success->$php"
            )
            
            if [ $? != 0 ] ; then
                continue
            fi
        done
    done

    info "all tasks completed"
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_file_modified_time
#   DESCRIPTION:  get modify time of file
#    PARAMETERS:  $1:file path
#       RETURNS:  time
#-------------------------------------------------------------------------------
get_file_modified_time ()
{
    path="$1"
    valid "[ -f $path ]"
    echo `stat $1 | sed -n "7p"|cut -d " " -f2`
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  restart
#   DESCRIPTION:  restart php-fpm
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
restart()
{
    php_fpm=$1
    if [ -z $php_fpm ] ; then
        php_fpm=php_fpm
    fi
    
    if [ ! -z "`ps -e|grep php-fpm|grep -v grep`" ] ; then
        exec_cmd "killall php-fpm"
    fi
    killall php-fpm > /dev/null 2>&1
    
    exec_cmd "$php_fpm"
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  test
#   DESCRIPTION:  test smart_agent
#    PARAMETERS:  php version
#       RETURNS:  
#-------------------------------------------------------------------------------
test ()
{
    param_version="$1"

    test_list=`ls $PHP_SOFTWARE_DIR | grep -E "$1"`

    for version in $test_list; do
        (
            log_path="/data/log/phpagent/trace_data.json"
            restart ${PHP_SOFTWARE_DIR}${version}/sbin/php-fpm

            time_pre=`get_file_modified_time $log_path`
            valid "curl 'http://192.168.100.100/admin/student/index?sort=id&order=desc&offset=0&limit=10&_=1527844738037' -H 'Cookie: thinkphp_show_page_trace=0|0; thinkphp_show_page_trace=0|0; PHPSESSID=bui9a3omlap0chtt9k1nuin51j; XDEBUG_SESSION=IDEKEY; keeplogin=1%7C86400%7C1527931135%7C7e3e73afb96824b6c95fcc50f181ae36' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.139 Safari/537.36' -H 'Content-Type: application/json' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Referer: http://192.168.100.100/admin/student?addtabs=1' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' --compressed >> /dev/null 2>&1"
            time_end=`get_file_modified_time $log_path`

            valid "test $time_pre -eq $time_end"

            valid "cat $log_path | jq ."

            valid "[[ `cat $log_path | jq . | grep array | uniq | wc -l` == 1 ]]"

            info "result-sucess:test $version ok"
        )
        
        if [ $? != 0 ] ; then
            continue
        fi
    done
}

#命令列表
case $1 in
    #install modules
    "install"|"i")
        if [ -z "$MODULE_DIR" ] ; then
            log "module dir invalid"
        else
            install "$2" "$3"
        fi
        ;;

    #check which php version and which module will be dealed
    "check"|"c")
        check_version "$2" "$3"
        ;;

    #restart php-fpm
    "restart")
        restart $2
        ;;

    #test smart_agent
    "test")
        test $2
        ;;

esac
