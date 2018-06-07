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
    cp "./config/$1" ./Dockerfile
    docker build -t $1 .
}	# ----------  end of function test  ----------
export -f build

parallel -j $THREAD build ::: `ls ./config/`
