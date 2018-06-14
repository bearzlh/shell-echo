#!/bin/bash -
#===============================================================================
#
#          FILE: test.sh
#
#         USAGE: ./test.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Bear.Zheng (https://github.com/bearzlh), bear.zheng@cloudwise.com
#  ORGANIZATION: ChinaCloudwise
#       CREATED: 2018年06月14日 10时33分53秒
#      REVISION:  ---
#===============================================================================
source ./main.sh

TEST_APACHE_IMAGE_FILE="./test_apache_images.txt"
TEST_NGINX_IMAGE_FILE="./test_nginx_images.txt"

getContainer ()
{
    echo `docker ps -a | grep $1 | grep -i $2 | awk '{print $1}'`
}	# ----------  end of function getContainer  ----------

test ()
{
    image=$1
    up_containers=`getContainer $image up`
    exit_containers=`getContainer $image exit`
    
    if [ ! -z "$up_containers" ] ; then
        for container in $up_containers; do
            exec_cmd "docker kill $container"
            exec_cmd "docker rm $container"
        done
    fi


    if [ ! -z "$exit_containers" ] ; then
        for container in "$exit_containers"; do
            exec_cmd "docker rm $container"
        done
    fi

    up=`docker run -v /data/bear/test:/opt -v /data/bear/www:/data/www --privileged -itd $image`
    docker exec $up /bin/sh -c "/opt/install_module.sh t $2"
    #exec_cmd "docker kill $up"
    #exec_cmd "docker rm $up"
}	# ----------  end of function test  ----------


run ()
{
    list=`cat $TEST_APACHE_IMAGE_FILE | grep -v "^#"`

    if [ ! -z "$list" ] ; then
        for item in $list; do
            exec_cmd "echo test for $item"
            test $item a
        done       
    fi

    list=`cat $TEST_NGINX_IMAGE_FILE | grep -v "^#"`

    if [ ! -z "$list" ] ; then
        for item in $list; do
            exec_cmd "echo test for $item"
            test $item
        done
    fi

}	# ----------  end of function run  ----------

run
