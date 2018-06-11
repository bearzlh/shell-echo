#===============================================================================
#
#          FILE: docker_handle.sh
#
#         USAGE: ./docker_handle.sh
#
#   DESCRIPTION: some useful command for docker
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: bear.zheng (https://github.com/bearzlh), bear.zheng@yunzhihui.com
#  ORGANIZATION: ChinaCloudwise
#       CREATED: 2018年06月08日 07时13分24秒
#      REVISION:  ---
#===============================================================================
source ./shell/main.sh

confirm ()
{
    confirm=
    while [ "$confirm" != "y" -a "$confirm" != "n" ] ; do
        echo "input y or n to confirm"
        read confirm
    done

    if [ "$confirm" == "y" ] ; then
        return 1
    else
        return 0
    fi
}	# ----------  end of function confirm  ----------

clear_images ()
{
    filter=$1
    images=`docker images | sed -n '2,\$p' |grep -E "$filter" | awk '{print $3}'`

    for image in $images; do
        containers=`docker ps -a | grep $image`
        if [ ! -z "$containers" ] ; then
            up_containers=
            exit_containers=
            for container in "$containers"; do
                id=`echo $container | awk '{print $1}'`
                if [ ! -z "`echo $container | grep -i up`" ] ; then
                    up_containers="$up_containers $id"
                elif [ ! -z "`echo $container | grep -i exited`" ] ; then
                    exit_containers="$exit_containers $id"
                fi
            done

            if [ ! -z "$up_containers" ] ; then
                log "up containers: $up_containers"
            fi

            if [ ! -z "$exit_containers" ] ; then
                log "exited containers: $exit_containers"
            fi
            log "remove $image?"
            confirm=`confirm`
            if [ $? == 1 ] ; then
                if [ ! -z "$up_containers" ] ; then
                    for up in $up_containers; do
                        exec_cmd "docker kill $up"
                        exec_cmd "docker rm $up"
                    done
                fi

                if [ ! -z "$exit_containers" ] ; then
                    for exit in $exit_containers; do
                        exec_cmd "docker rm $exit"
                    done
                fi               

                exec_cmd "docker rmi $image"
                info "$image removed"
            fi
        else
            log "remove $image?"
            confirm=`confirm`
            log $confirm
            if [ $? == 1 ] ; then
                exec_cmd "docker rmi $image"
                info "$image removed"
            fi
        fi
    done
}	# ----------  end of function clear_none_images  ----------


case $1 in
    "clear_image" | "ci")
        clear_images $2
        ;;

    *)
        print_info "Usage: $0 clear_image(ci)"
        ;;

    esac    # --- end of case ---
