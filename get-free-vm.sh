#! /usr/bin/env bash

KVM_HOSTS=(
'10.18.2.61'
'10.18.2.84'
)

function get_remote_stopped_vms() {
    ssh "$1"  virsh list --all | grep 'shut' | awk '{print $2}'
}

function start_remote_vm() {
    ssh "$1" virsh start "$2"
}

function get_vm_mac_addr() {
    ssh "$1" virsh domiflist "$2" | grep ':' | awk '{print $5}'
}

function get_vm_ip_addr() {
    ip_kuohao=`ssh "$1" arp -an | grep "$2" | awk '{print $2}'`
    #echo ${ip_kuohao:1: -1} #Doesn't work on Bash 3
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


function start_remote_vm_and_generate_remmina_conf() {
    root_at_host="$1"
    remote_vm_name="$2"
    start_remote_vm "$root_at_host" "$remote_vm_name"
    if [ $? != 0 ]; then
	exit $?
    fi

    vm_mac_addr=`get_vm_mac_addr "$root_at_host" "$remote_vm_name"`
    vm_ip_addr=`get_vm_ip_addr "$root_at_host" "$vm_mac_addr"`
    while [ -z "$vm_ip_addr" ]; do
	echo 'Polling get its IP addr ....'
	sleep 1
	vm_ip_addr=`get_vm_ip_addr "$root_at_host" "$vm_mac_addr"`
    done

    config_exported_as="$host-$remote_vm_name.remmina"
    remmina_conf_str_func "$vm_ip_addr" > "$config_exported_as"
    echo "Exported as $config_exported_as!"
    exit 0
}

function scan_per_host() {
    root_at_host="$1"
    remote_vm_name=`get_remote_stopped_vms "$root_at_host"`

    if [ -z "$remote_vm_name" ]; then
	echo 'No shut off vm on this machine ...'
	return
    fi

    first_remote_vm_name=`echo "$remote_vm_name" | head -1`

    echo "Found $first_remote_vm_name @ $host ...."
    echo "Do you want to start $first_remote_vm_name on $host?"
    read yn
    if [ "$yn" == 'y' ]; then
	start_remote_vm_and_generate_remmina_conf "$root_at_host" "$first_remote_vm_name"
    fi
}


for host in "${KVM_HOSTS[@]}"; do
    echo "Scanning $host ..."
    root_at_host="root@$host"
    scan_per_host "$root_at_host"
done


