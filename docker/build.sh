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

THREAD=4

build ()
{
    source "./shell/main.sh"
    LOG="./log"
    SRC='./'
    TMP='/tmp/'
    if [ -z "`docker images|grep $1`" ] ; then
        exec_cmd "mkdir $TMP$1"
        exec_cmd "cp ./config/$1 $TMP$1/Dockerfile" 
        exec_cm "docker build -t $1 $TMP$1 >> ./build_log/${1}.log"
    else
        echo "$1 has been builded,continue" >> ./build_log/${1}.log
    fi
    exec_cmd "rm -rf $TMP$1"
}	# ----------  end of function test  ----------

export -f build

parallel -j $THREAD build ::: `ls ./config/`
