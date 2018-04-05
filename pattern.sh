#!/bin/sh
background_default=grey
foreground_default=black
prefix='\033['
start_pattern=
end_pattern=
current_dir=`dirname $0`

error()
{
    echo -e "\033[31m$1\033[0m"
    exit
}

setPatternDir()
{
   current_dir=`dirname $1`/`basename $1`/
}

getParamsNum()
{
    n=0
    n=$[n + `echo $1 | sed -n '/X/p'|wc -l`]
    n=$[n + `echo $1 | sed -n '/Y/p'|wc -l`]
    echo $n
}

pattern()
{
    return=
    pattern_list=`sed -n 's/ \+#.*$/\n/p' $current_dir/pattern.txt`
    for param in $@
    do
        param=`echo $param | sed 's/:/ /g;p' | sed -n '$p'`
        params_receive_num=`echo $param | wc -w`
        if [ $params_receive_num -eq 3 ];then
            p1=${param%% *}
            param=${param#* }
            p2=${param%% *}
            p3=${param##* }
        elif [ $params_receive_num -eq 2 ];then
            p1=${param%% *}
            p2=${param##* }
        else
            p1=$param
        fi
        match=`echo "$pattern_list" | sed -n "/^$p1/p"`
        if [ -z "$match" ];then
            error "${FUNCNAME[0]} $* ==> params error,no matched"
        else
            match_num=`echo -n "$match" | wc -l`
        fi
        if [ $match_num -gt 1 ];then
            error "${FUNCNAME[0]} $* ==> should match one;matched:\n`echo \"$match\" | sed -n 's/ .*//p'`"
        fi
        params_num=$[`getParamsNum "$match"` + 1]
        
        if [ $params_receive_num -ne $params_num ];then
            error "${FUNCNAME[0]} ==> should offer $params_num params,$params_receive_num received"
        fi
        code=`echo $match | sed -n 's/.*\ //p'`
        if [ "$params_receive_num" -eq 2 ];then
            code=`echo $code | sed -n "s/\[X\]/$p2/p"`
        elif [ "$params_receive_num" -eq 3 ];then
            code=`echo $code | sed -n "s/\[X\]/$p2/p" | sed -n "s/\[Y\]/$p3/p"`
        fi

        return=$return"$prefix$code"
    done
    echo $return
}

#设置输入模式
set_pattern()
{
    start_pattern="`pattern $@`"
    end_pattern="`pattern off`"
}

#查看当前输入模式
get_pattern()
{
    echo "$start_pattern" 
}

#重置输入模式
reset_pattern()
{
    start_pattern=
    end_pattern=
}

escape_charactor()
{
    escape='\[]{}.*?'
    count=${#escape}
    r=$1
    #转义次数
    if [ -z $2 ];then
        level=1
    else
        level=$2
    fi

    for ((c = 0; c < $level; c++))
    do
        for ((i = 0; i < $count; i++))
        do
            v1="${escape:i:1}"
            vl='/\'$v1'/\\\'$v1'/'
            if [ ! -z `echo $r | grep -F "$v1"` ];then
                r=`echo $r | sed -n "s${vl}g;p"`
            fi
        done
    done

    echo $r
}

check_pattern()
{
    return=$1
    start_pattern_match=`echo $1 | sed -n "/<\*\*/p"`
    end_pattern_match=`echo $1 | sed -n "/\*\*>/p"`
    start_pattern_escape=`escape_charactor $start_pattern`
    end_pattern_escape=`escape_charactor $end_pattern`

    if [ -z $start_pattern_match -a -z $end_pattern_match ];then
        return=$start_pattern$1$end_pattern
    else
        if [ ! -z $start_pattern_match ];then
            return=`echo $return | sed -n "s/<\*\*/$start_pattern_escape/g;p"`
        fi
        if [ ! -z $end_pattern_match ];then
            return=`echo $return | sed -n "s/\*\*>/$end_pattern_escape/g;p"`
        fi
    fi
    echo $return
}


#输出
echo_pattern()
{
    string=`check_pattern $@`
    echo -en $string
}

printf_pattern()
{
    p1=`check_pattern $1`
    r=`escape_charactor $p1`
    pl=`echo $@ | sed -n "s/$r//g;p"`
    printf $start_pattern$p1$end_pattern $pl
}
