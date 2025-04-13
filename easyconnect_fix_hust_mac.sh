#!/bin/bash

# 检查网络，获取VPN的IP
check_network() {
    export VPN_IP=`host vpn.hust.edu.cn | head -1 | rev | cut -d' ' -f1 | rev`
    export VPN_IP_START=`echo $VPN_IP | cut -d'.' -f-2`
    if [[ ! $VPN_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo 1>&2 Error: Cannot lookup domain of vpn.hust.edu.cn
        exit 1
    fi
}

# 检查 EasyConnect 是否已安装
check_easy_connect() {
    if [ ! -d "/Applications/EasyConnect.app" ]; then
        echo 1>&2 Error: "EasyConnect" not found
        exit 1
    fi
}

# 等待指定的时间，直到完成
wait_60s() {
    ECHO=${3:-echo}
    $ECHO -n "Wait $1 ... 60s"
    for i in `seq -w 59 -1 -1`; do
        $2 && break
        sleep 1
        $ECHO -en '\b\b\b'${i}s
    done
    if [ $i -eq -1 ]; then
        $ECHO -e '\b\b\btimeout'
        return 1
    else
        $ECHO -e '\b\b\bdone'
        return 0
    fi
}

# 显示进度
show_progress() {
    LEN=${#2}
    if [ "$1" -ne 1 ]; then
        for _i in `seq $((LEN*2+1))`; do
            if [ "$1" -ne "$2" ]; then
                echo -en '\b'
            else
                echo -en '\b \b'
            fi
        done
    fi
    if [ "$1" -ne "$2" ]; then
        printf "%0${LEN}d/$2" $1
    fi
}

# 启动 EasyConnect
start_easy_connect() {
    if ! open -a EasyConnect; then
        echo 1>&2 Error: Open EasyConnect failed
        exit 1
    fi
}

# 获取要删除的路由
get_route_to_delete() {
    export ROUTE_TO_DEL=`netstat -rn | grep -w tun0 | tr -s ' ' | grep -v $VPN_IP_START`
    if [ -n "$ROUTE_TO_DEL" ]; then
        return 0
    fi
    return 1
}

# 删除路由规则
delete_route_rules() {
    echo -n 'Delete route rules ... '
    sleep 3
    get_route_to_delete
    NET_IP=(`echo "$ROUTE_TO_DEL" | cut -d' ' -f1`)
    NET_FLAG=(`echo "$ROUTE_TO_DEL" | cut -d' ' -f3`)

    # 获取网关
    export GATEWAY=`echo "$ROUTE_TO_DEL" | cut -d' ' -f2 | uniq | head -1`
    for ((i=0;i<${#NET_IP[@]};i++)); do
        # 如果是有效路由并且符合条件，则删除路由
        if grep -vq / <<< ${NET_IP[i]} && [ "${NET_FLAG[i]}" = "UGSc" ]; then
            sudo route delete "${NET_IP[i]}/0" > /dev/null
        else
            sudo route delete "${NET_IP[i]}" > /dev/null
        fi
        show_progress $((i+1)) ${#NET_IP[@]}
    done
    echo done
}

# 添加路由规则
add_route_rules() {
    echo -n 'Add route rules ... '
    if [ -z "$GATEWAY" ]; then
        # 获取网关
        GATEWAY=`ifconfig tun0 | tr ' ' '\n' | grep '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1`
        if [ -z "$GATEWAY" ]; then
            echo 1>&2 Warning: Gateway is null
        fi
    fi
    # 子网列表
    SUBNET="202.114.0.0/16 10.0.0.0/8  *.hust.edu.cn"    
    for ((i=0;i<${#SUBNET[@]};i++)); do
        if [[ ${SUBNET[i]} != ${VPN_IP_START}* ]]; then
            sudo route -n add -net ${SUBNET[i]} $GATEWAY > /dev/null
            show_progress $((i+1)) ${#SUBNET[@]}
        fi
    done
    echo done
}

# 执行脚本的主要流程
check_network
check_easy_connect
sudo true
start_easy_connect
wait_60s EasyConnect get_route_to_delete
if [ -z "$ROUTE_TO_DEL" ]; then
    echo -e Error: no rules to delete
    exit 1
fi
delete_route_rules
add_route_rules
