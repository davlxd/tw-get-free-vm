#! /usr/bin/env bash

KVM_HOSTS=(
'10.18.2.61'
'10.18.2.84'
)

function get_remote_stopped_vms() {
    many_vms=`ssh "$1"  virsh list --all | grep 'shut' | awk '{print $2}'`
    echo "$many_vms" | head -1
}

function start_remote_vm() {
    ssh "$1" virsh start "$2"
}

function get_vm_mac_addr() {
    ssh "$1" virsh domiflist "$2" | grep ':' | awk '{print $5}'
}

function get_vm_ip_addr() {
    ip_kuohao=`ssh "$1" arp -an | grep "$2" | awk '{print $2}'`
    #echo ${ip_kuohao:1: -1} #Doesn't work on Bash3
    echo ${ip_kuohao:1} | awk -F\) '{print $1}'
}

function remmina_conf_str_func() {
    cat  <<EOF
[remmina]
disableclipboard=0
ssh_auth=0
clientname=
quality=0
ssh_charset=
ssh_privatekey=
console=0
resolution=1920x1200
group=
password=tlc+5VYU27XHnbBxojPugw==
name=local
ssh_loopback=0
shareprinter=0
ssh_username=
ssh_server=
security=
protocol=RDP
execpath=
sound=off
exec=
ssh_enabled=0
username=administrator
sharefolder=
domain=
server=${1}
colordepth=32
viewmode=1
window_maximize=1
EOF
}



for host in "${KVM_HOSTS[@]}"; do
    echo "Scanning $host ..."
    root_at_host="root@$host"
    remote_vm_name=`get_remote_stopped_vms "$root_at_host"`
    if [ ! -z "$remote_vm_name" ];then
	echo "Found $remote_vm_name @ $host ...."
	echo "Do you want to start $remote_vm_name on $host?"
	read yn
	if [ "$yn" != 'y' ]; then
	    continue
	fi
	start_remote_vm "$root_at_host" "$remote_vm_name"
	vm_mac_addr=`get_vm_mac_addr "$root_at_host" "$remote_vm_name"`
	vm_ip_addr=`get_vm_ip_addr "$root_at_host" "$vm_mac_addr"`
	remmina_conf_str_func $vm_mac_addr
    fi
done


