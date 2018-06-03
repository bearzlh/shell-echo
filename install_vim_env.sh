#!/bin/bash -
#===============================================================================
#
#          FILE: install_vim_env.sh
#
#         USAGE: ./install_vim_env.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: get vim env
#        AUTHOR: Bear.Zheng (https://github.com/bearzlh), bear.zheng@cloudwise.com
#  ORGANIZATION: ChinaCloudwise
#       CREATED: 2018年06月03日 14时44分47秒
#      REVISION:  ---
#===============================================================================
current_dir=`pwd`
source ./main.sh

SRC_DIR=/data/src/
SOFTWARE_DIR=/data/soft/
LOG=/data/log/install_vim

download_list="https://github.com/git/git.git https://github.com/vim/vim.git https://github.com/bearzlh/vim-for-c.git"


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check_dir
#   DESCRIPTION:  create dir if not exists
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
check_dir ()
{
    dir_list="$SRC_DIR `dirname $LOG`"

    for dir in $dir_list; do
        if [ ! -d $dir ] ; then
            exec_cmd "mkdir -p $dir"
        fi
    done
}	# ----------  end of function check_dir  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  check_src
#   DESCRIPTION:  download source file if not exists
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
check_src ()
{
    for file in $download_list; do
        file_full_name=`basename $file`
        file_name=${file_full_name%.git}
        
        cd $SRC_DIR
        if [ ! -d "$SRC_DIR$file_name"  ] ; then
            exec_cmd "git clone $file"
        fi
    done
}	# ----------  end of function check_src  ----------


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  install_sys
#   DESCRIPTION:  install python
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
install_sys ()
{
    python3="python34-devel"
    rpm -q $python3 > /dev/null 2>&1

    if [ $? != 0 ] ; then
        exec_cmd "yum -y install $python3" 
    fi

    python2="python-devel"
    rpm -q $python2 > /dev/null 2>&1

    if [ $? != 0 ] ; then
        exec_cmd "yum -y install $python2"
    fi

    rpm -q ack > /dev/null 2>&1

    if [ $? != 0 ] ; then
        exec_cmd "yum -y install ack"
    fi
}	# ----------  end of function install_sys  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  install_git
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
install_git ()
{
    if [ -d ${SOFTWARE_DIR}git ] ; then
        log "git already installed"
        return 0
    fi

    git_dir=${SRC_DIR}git
    exec_cmd "cd $git_dir"
    exec_cmd "./configure --prefix=${SOFTWARE_DIR}git"
    exec_cmd "make"
    exec_cmd "make install"
    info "result-sucess:installed=>git"
    
    exec_cmd "git config --global user.name bearzlh"
    exec_cmd "git config --global user.email bear.zheng@yunzhihui.com"
    exec_cmd "git config --global merge.tool vimdiff"
}	# ----------  end of function install_git  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  install_vim
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
install_vim ()
{
    if [ -d ${SOFTWARE_DIR}vim ] ; then
        log "vim already installed"
        return 0
    fi

    vim_dir=${SRC_DIR}vim
    python3_config=`python3-config --configdir`
    exec_cmd "cd $vim_dir"
    exec_cmd "./configure --prefix=${SOFTWARE_DIR}vim --enable-python3interp=yes --with-python3-config-dir=$python3_config --with-features=huge"
    exec_cmd "make"
    exec_cmd "make install"
    exec_cmd "cp ${SRC_DIR}vim-for-c/.vimrc ~/"
    exec_cmd "vim +PluginInstall +qall"
}	# ----------  end of function install_vim  ----------


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  install_bashdb
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
install_bashdb ()
{
    if [ -d ${SOFTWARE_DIR}bashdb ] ; then
        log "bashdb already installed"
        return 0
    fi

    exec_cmd "cp $current_dir/bashdb.tar.gz $SRC_DIR"
    exec_cmd "cd $SRC_DIR"
    exec_cmd "tar zxf bashdb.tar.gz"
    exec_cmd "cd bashdb"
    exec_cmd "make configure"
    exec_cmd "./configure --prefix=${SOFTWARE_DIR}bashdb"
    exec_cmd "make"
    exec_cmd "make install"
}	# ----------  end of function install_bashdb  ----------
check_dir
check_src
install_sys
install_git
install_vim
install_bashdb
