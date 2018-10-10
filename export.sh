#!/bin/bash -
#===============================================================================
#
#          FILE: export.sh
#
#         USAGE: ./export.sh
#
#   DESCRIPTION: get patch changed by git
#
#       OPTIONS: $1-export path
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: bearzlh (https://github.com/bearzlh), bear.zheng@cloudwise.com
#  ORGANIZATION: ChinaCloudwise
#       CREATED: 2018/10/09 14时38分56秒
#      REVISION:  ---
#===============================================================================
EXPORT_DIR=/data/export/toushibao

#use the first parameter as export path if not empty and is dir
if [ ! -z $1 -a -d $1 ] ; then
    EXPORT_DIR=$1
fi

if [ ! -d $EXPORT_DIR ] ; then
    mkdir -p $EXPORT_DIR
fi

if [ ! -d $EXPORT_DIR ] ; then
    echo "export dir not created,exit"
    exit
fi

git status >> /dev/null

if [ $? != 0 ]; then
    echo -e "\033[33mnot in git control\033[0m $file"
    exit;
fi
if [ -z "`git status | grep -E 'new file:|modified:'`" ] ; then
    echo -e "\033[33mno file changed\033[0m $file"
    exit
fi

#traverse the changed file
for file in `git status | grep -E 'new file:|modified:'|awk '{print $NF}'`; do
    dir_name=`dirname $file`
    
    if [ ! -d $EXPORT_DIR/$dir_name ] ; then
        mkdir -p $EXPORT_DIR/$dir_name
    fi

    if [ $? != 0 ] ; then
        echo "dir $dir_name not exists,exit"
        exit
    fi
    
    if [ -f $EXPORT_DIR/$file ] ; then
        if [ ! -z "`diff $file $EXPORT_DIR/$file`" ] ; then
            echo -e "\033[33mupdated\033[0m $file"
        fi
    else
        echo -e "\033[36mcreated\033[0m $file"
    fi

    cp $file ${EXPORT_DIR}/$file
done
echo -en "\033[32mpatched success,path:$EXPORT_DIR\n\033[0m"
