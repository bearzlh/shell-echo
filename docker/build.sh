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

build ()
{
    if [ -z "`docker images|grep $1`" ] ; then
        cp "./config/$1" ./Dockerfile
        docker build -t $1 . >> ./build_log/${1}.log
    else
        echo "$1 has been builded,continue" >> ./build_log/${1}.log
    fi
}	# ----------  end of function test  ----------

export -f build

parallel -j $THREAD build ::: `ls ./config/`
