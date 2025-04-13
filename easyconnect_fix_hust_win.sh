#!/bin/bash

EASYCONNECT_DIR="C:/Program Files (x86)/Sangfor/SSL/EasyConnect"
EASYCONNECT_NAME="EasyConnect.exe"

log_error() {
    echo "$(powershell -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'") ERROR: $1" >> script.log
}

check_network() {
    VPN_IP=$(nslookup.exe vpn.hust.edu.cn 2>/dev/null | grep vpn.hust.edu.cn -A1 | grep Address | head -1 | rev | cut -d' ' -f1 | rev)
    if [ -z "$VPN_IP" ]; then
        log_error "Cannot lookup domain of vpn.hust.edu.cn"
        echo "Error: Cannot lookup domain of vpn.hust.edu.cn" >&2
        exit 1
    fi
    export VPN_IP_START=$(echo $VPN_IP | cut -d'.' -f-2)
    export IFACE_ID=$(route.exe print if | grep Sangfor | tr -d ' ' | cut -d. -f1)
    if [ -z "$IFACE_ID" ]; then
        log_error "Cannot find \"Sangfor SSL VPN\" interface"
        echo "Cannot find \"Sangfor SSL VPN\" interface" >&2
        exit 1
    fi
}

check_easy_connect() {
    if [ ! -f "$EASYCONNECT_DIR/$EASYCONNECT_NAME" ]; then
        log_error "\"${EASYCONNECT_NAME}\" not found"
        echo "Error: \"${EASYCONNECT_NAME}\" not found" >&2
        exit 1
    fi
}

get_iface_gw() {
    IFACE_INFO=$(route.exe print \?22.0.0.0 | grep '^[ ]*[0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+' | awk '{ print $3,$4 }' | sort | uniq -c | sort -nr | head -1)
    export IFACE_GW=$(echo $IFACE_INFO | awk '{ print $2 }')
    export IFACE_IP=$(echo $IFACE_INFO | awk '{ print $3 }')
    if [ -z "$IFACE_IP" ] || ! pidof $EASYCONNECT_NAME &>/dev/null; then
        log_error "Unable to get interface IP or EasyConnect is not running."
        return 1
    fi
    return 0
}

get_route_to_delete() {
    export ROUTE_TO_DEL=$(route.exe print | awk "/${IFACE_IP}/ && !/${VPN_IP_START}/{print \$1,\$2,\$3}")
    if [ -z "$ROUTE_TO_DEL" ] || ! pidof $EASYCONNECT_NAME &>/dev/null; then
        log_error "No route rules to delete."
        return 1
    fi
    return 0
}

_wait_60s() {
    echo -n "Wait $1 ... 60s"
    for _i in $(seq -w 59 -1 -1); do
        $2 && break
        sleep 1
        echo -en '\b\b\b'${_i}s
    done
    if [ ${_i} -eq -1 ]; then
        log_error "Timeout waiting for $1."
        echo -e '\b\b\btimeout'
        return 1
    else
        echo -e '\b\b\bdone'
        return 0
    fi
}

wait_60s() {
    while ! _wait_60s "$@"; do
        read -p "Continue waiting? [Y/n] " cont
        case "$cont" in
            [Yy]* ) return 0 ;;
            [Nn]* ) return 1 ;;
            * ) return 0 ;;  # 默认为继续
        esac
    done
}

show_progress() {
    LEN=${#2}
    if [ "$1" -ne 1 ]; then
        for _i in $(seq $((LEN*2+1))); do
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

delete_route_rules() {
    echo 'Delete route rules ... '
    get_route_to_delete
    COUNT=1
    TOTAL=$(echo "$ROUTE_TO_DEL" | wc -l)
    echo "$ROUTE_TO_DEL" | while read NETWORK MASK GW; do
        if [[ "$GW" != "在链路上" ]]; then
            echo "Deleting route: $NETWORK MASK $MASK via GW $GW"
            route.exe DELETE "$NETWORK" MASK "$MASK" "$GW" IF "${IFACE_ID}" >/dev/null
            if [ $? -ne 0 ]; then
                log_error "Failed to delete route: $NETWORK MASK $MASK"
            fi
        else
            echo "Skipping route: $NETWORK MASK $MASK as the gateway is 'on-link'"
        fi
        show_progress $COUNT $TOTAL
        COUNT=$((COUNT+1))
    done
    echo done
}

add_route_rules() {
    echo 'Add route rules ... '
    SUBNET="202.114.0.0/16 10.0.0.0/8  *.hust.edu.cn"
    COUNT=1
    TOTAL=$(echo "$SUBNET" | wc -w)
    for subnet in $SUBNET; do
        IP=$(ipcalc -n $subnet | awk -F= '{print $2}')
        MASK=$(ipcalc -m $subnet | awk -F= '{print $2}')
        EXISTING_ROUTE=$(route.exe print | grep "$IP" | grep "$MASK")
        if [ -z "$EXISTING_ROUTE" ]; then
            route.exe ADD "$IP" MASK "$MASK" "$IFACE_GW" METRIC 257 IF "$IFACE_ID" >/dev/null
            if [ $? -ne 0 ]; then
                log_error "Failed to add route: $IP MASK $MASK"
            fi
        fi
        show_progress $COUNT $TOTAL
        COUNT=$((COUNT+1))
    done
    echo done
}

if [ "$#" -eq 0 ]; then
    check_easy_connect
    check_network
    cd "$EASYCONNECT_DIR"
    cmd.exe /c start /B ".\\$EASYCONNECT_NAME"
    cd - > /dev/null
    wait_60s EasyConnect get_iface_gw
    [ -z "$IFACE_IP" ] && log_error "Cannot get interface IP" && exit 1
    su -c "sh $0 admin $VPN_IP; exit"
elif [ "$#" -eq 2 -a "$1" = "admin" ]; then
    export VPN_IP=$2
    check_network
    wait_60s "EasyConnect interface" get_iface_gw
    wait_60s "EasyConnect route" get_route_to_delete
    [ -z "$ROUTE_TO_DEL" ] && log_error "No route rules to delete" && exit 1
    delete_route_rules
    add_route_rules
else
    echo "Usage: sh.exe $0" >&2
fi
