#===============================================================================
#
#          FILE: test.sh
#
#         USAGE: ./test.sh
#
#   DESCRIPTION: parallel test
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: bearzlh (https://github.com/bearzlh), bear.zheng@cloudwise.com
#  ORGANIZATION: ChinaCloudwise
#       CREATED: 2018/06/07 19时25分09秒
#      REVISION:  ---
#===============================================================================
#!/bin/sh

THREAD=10


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_seconds
#   DESCRIPTION:  get seconds of hh:mm:ss
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
get_seconds ()
{
    hour=`echo $1|cut -d ":" -f1`
    minute=`echo $1|cut -d ":" -f2`
    second=`echo $1|cut -d ":" -f3`
    echo $((hour * 3600 + minute * 60 + second))
}	# ----------  end of function get_seconds  ----------


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_interval
#   DESCRIPTION:  get seconds interal 
#    PARAMETERS:  $1:start_time,$2:end_time
#       RETURNS:  
#-------------------------------------------------------------------------------
get_interval ()
{
    start=`get_seconds $1` 
    end=`get_seconds $2`
    echo $(($end - $start))
}	# ----------  end of function get_interval  ----------


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  get_modify_time
#   DESCRIPTION:  get modify time of the file
#    PARAMETERS:  $1:file path
#       RETURNS:  
#-------------------------------------------------------------------------------
get_modify_time ()
{
    updated_time `stat $1 |sed -n '7p'|awk '{print $2}'|cut -d '.' -f1`
    now=`date "+%H:%M:%S"`
    echo `get_interval $updated_time $now`
}	# ----------  end of function get_modify_time  ----------

build ()
{
    if [ -z "`docker images|grep $1`" ] ; then
        while [ "`get_modify_time ./Dockerfile`" < 10 ] ; do
            echo "sleep 10"
            sleep 10
        done
        cp "./config/$1" ./Dockerfile
        docker build -t $1 . >> ./build_log/${1}.log
    else
        echo "$1 has been builded,continue" >> ./build_log/${1}.log
    fi
}	# ----------  end of function test  ----------

export -f build

parallel -j $THREAD build ::: `ls ./config/`
