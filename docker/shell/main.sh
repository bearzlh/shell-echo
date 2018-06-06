#!/bin/sh
#===============================================================================
#
#          FILE: log.sh
#
#         USAGE: ./log.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: main function
#        AUTHOR: Bear.Zheng (https://github.com/bearzlh), bear.zheng@cloudwise.com
#  ORGANIZATION: ChinaCloudwise
#       CREATED: 2018年06月02日 16时32分37秒
#      REVISION:  ---
#===============================================================================
CURRENT_DIR="$(dirname $(readlink -f ${BASH_SOURCE}))/"

#load print format
source  ${CURRENT_DIR}/pattern.sh

if [ -z $LOG ];then
    LOG=/tmp/log
fi


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  time_format
#   DESCRIPTION:  output formated time
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
time_format()
{
    echo `date +"%Y-%m-%d %H:%M:%S"`
}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  log_message
#   DESCRIPTION:  log message
#    PARAMETERS:  $1:message to log;$2:font color
#       RETURNS:  
#-------------------------------------------------------------------------------
log_message ()
{
    color=`pattern $2`
    off=`pattern off`
    echo -e "`time_format`==>${color}$1${off}"
    echo "`date`==>$1">>$LOG
   
}	# ----------  end of function log_message  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  log
#   DESCRIPTION:  debug information
#    PARAMETERS:  messages to log
#       RETURNS:  
#-------------------------------------------------------------------------------
log()
{
    log_message "$*" ffcblue
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  info
#   DESCRIPTION:  successful message
#    PARAMETERS:  message to log
#       RETURNS:  
#-------------------------------------------------------------------------------
info()
{
    log_message "$*" ffcgreen
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  error
#   DESCRIPTION:  error message
#    PARAMETERS:  message to log
#       RETURNS:  
#-------------------------------------------------------------------------------
error()
{
    log_message "$*" ffcred
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  exec_cmd
#   DESCRIPTION:  run shell command,exit if error
#    PARAMETERS:  valid the result and return
#       RETURNS:  
#-------------------------------------------------------------------------------
exec_cmd ()
{
    cmd="$1"
    log "run:$cmd"
    eval $cmd >> $LOG 2>&1

    if [ $? != 0 ] ; then
        error "result-error:cmd->$cmd,look $LOG for help"
        exit 1
    fi
}	# ----------  end of function exec_cmd  ----------



#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  valid
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
valid ()
{
    cmd="$1"
    eval $cmd >> $LOG 2>&1

    if [ $? != 0 ] ; then
        error "result-error:cmd->$cmd,look $LOG for help"
        exit 1
    fi
}	# ----------  end of function valid  ----------


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  download
#   DESCRIPTION:  download and untar
#    PARAMETERS:  $1:dir;$2:name;$3:url
#       RETURNS:  
#-------------------------------------------------------------------------------
download ()
{
    SRC_DIR=$1
    tar_file=$2
    mirror=$3
    cd $SRC_DIR
    if [ ! -f "$SRC_DIR$tar_file" ] ; then
        exec_cmd "wget -O $tar_file $mirror"
    fi

    dir=${tar_file%.tar*}
    if [ ! -d "$dir" ] ; then
        exec_cmd "tar zxf $tar_file"
    else
        exec_cmd "rm -rf $dir"
        exec_cmd "tar zxf $tar_file"
    fi
}	# ----------  end of function download  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check_libs
#   DESCRIPTION:  install libs if not installed
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
check_libs()
{
    libs="$1"
    for lib in $libs
    do
        rpm -q $lib>/dev/null 2>&1
        if [ $? != 0 ];then
            log "$lib required"
            exec_cmd "yum -y install $lib"
        fi
    done
}	# ----------  end of function check_libs  ----------
