#!/bin/bash
# from
# https://github.com/oneclickvirt/pve_lxc_images

# ./buildct.sh CTID CPU核数 内存 硬盘 系统 存储盘
# ./buildct.sh 102 1 512 5 debian11 local

# 用颜色输出信息
_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }
reading() { read -rp "$(_green "$1")" "$2"; }
utf8_locale=$(locale -a 2>/dev/null | grep -i -m 1 -E "UTF-8|utf8")
if [[ -z "$utf8_locale" ]]; then
    echo "No UTF-8 locale found"
else
    export LC_ALL="$utf8_locale"
    export LANG="$utf8_locale"
    export LANGUAGE="$utf8_locale"
    echo "Locale set to $utf8_locale"
fi

get_system_arch() {
    local sysarch="$(uname -m)"
    if [ "${sysarch}" = "unknown" ] || [ "${sysarch}" = "" ]; then
        local sysarch="$(arch)"
    fi
    # 根据架构信息设置系统位数并下载文件,其余 * 包括了 x86_64
    case "${sysarch}" in
    "i386" | "i686" | "x86_64")
        system_arch="x86"
        ;;
    "armv7l" | "armv8" | "armv8l" | "aarch64")
        system_arch="arch"
        ;;
    *)
        system_arch=""
        ;;
    esac
}

check_china() {
    _yellow "IP area being detected ......"
    if [[ -z "${CN}" ]]; then
        if [[ $(curl -m 6 -s https://ipapi.co/json | grep 'China') != "" ]]; then
            _yellow "根据ipapi.co提供的信息，当前IP可能在中国，使用中国镜像下载"
            CN=true
        else
            if [[ $? -ne 0 ]]; then
                if [[ $(curl -m 6 -s cip.cc) =~ "中国" ]]; then
                    _yellow "根据cip.cc提供的信息，当前IP可能在中国，使用中国镜像下载"
                    CN=true
                fi
            fi
        fi
    fi
}

get_system_arch
check_china
if [ -z "${system_arch}" ] || [ ! -v system_arch ]; then
    _red "This script can only run on machines under x86_64 or arm architecture."
    exit 1
fi
cd /root >/dev/null 2>&1
CTID="${1:-102}"
core="${2:-1}"
memory="${3:-512}"
disk="${4:-5}"
system_ori="${5:-debian11}"
storage="${6:-local}"
rm -rf "ct$name"
en_system=$(echo "$system_ori" | sed 's/[0-9]*//g')
num_system=$(echo "$system_ori" | sed 's/[a-zA-Z]*//g')
system="$en_system-$num_system"
if [ "$system_arch" = "arch" ]; then
    if [ "$en_system" = "ubuntu" ]; then
        case "$system_ori" in
        ubuntu14)
            version="trusty"
            ;;
        ubuntu16)
            version="xenial"
            ;;
        ubuntu18)
            version="bionic"
            ;;
        ubuntu20)
            version="focal"
            ;;
        ubuntu22)
            version="jammy"
            ;;
        *)
            echo "Unsupported Ubuntu version."
            exit 1
            ;;
        esac
    elif [ "$en_system" = "debian" ]; then
        case "$system_ori" in
        debian6)
            version="squeeze"
            ;;
        debian7)
            version="wheezy"
            ;;
        debian8)
            version="jessie"
            ;;
        debian9)
            version="stretch"
            ;;
        debian10)
            version="buster"
            ;;
        debian11)
            version="bullseye"
            ;;
        debian12)
            version="bookworm"
            ;;
        *)
            echo "Unsupported Debian version."
            exit 1
            ;;
        esac
    else
        version=${num_system}
    fi
    if [[ -z "${CN}" || "${CN}" != true ]]; then
        curl -o "/var/lib/vz/template/cache/${en_system}-arm64-${version}-cloud.tar.xz" "https://jenkins.linuxcontainers.org/view/LXC/job/image-${en_system}/architecture=arm64,release=${version},variant=cloud/lastSuccessfulBuild/artifact/rootfs.tar.xz"
    else
        # https://mirror.tuna.tsinghua.edu.cn/lxc-images/images/
        URL="https://mirror.tuna.tsinghua.edu.cn/lxc-images/images/${en_system}/${version}/arm64/cloud/"
        HTML=$(curl -s "$URL")
        folder_links_dates=$(echo "$HTML" | grep -oE '<a href="([^"]+)".*date">([^<]+)' | sed -E 's/<a href="([^"]+)".*date">([^<]+)/\1 \2/')
        sorted_links=$(echo "$folder_links_dates" | sort -k2 -r)
        latest_folder_link=$(echo "$sorted_links" | head -n 1 | awk '{print $1}')
        latest_folder_url="${URL}${latest_folder_link}"
        curl -o "/var/lib/vz/template/cache/${en_system}-arm64-${version}-cloud.tar.xz" "${latest_folder_url}/rootfs.tar.xz"
    fi
else
    system_name=$(pveam available --section system | grep "$system" | awk '{print $2}' | head -n1)
    if ! pveam available --section system | grep "$system" >/dev/null; then
        _red "No such system"
        exit
    else
        _green "Use $system_name"
    fi
    pveam download local $system_name
fi

check_cdn() {
    local o_url=$1
    for cdn_url in "${cdn_urls[@]}"; do
        if curl -sL -k "$cdn_url$o_url" --max-time 6 | grep -q "success" >/dev/null 2>&1; then
            export cdn_success_url="$cdn_url"
            return
        fi
        sleep 0.5
    done
    export cdn_success_url=""
}

check_cdn_file() {
    check_cdn "https://raw.githubusercontent.com/spiritLHLS/ecs/main/back/test"
    if [ -n "$cdn_success_url" ]; then
        _yellow "CDN available, using CDN"
    else
        _yellow "No CDN available, no use CDN"
    fi
}

cdn_urls=("https://cdn0.spiritlhl.top/" "http://cdn3.spiritlhl.net/" "http://cdn1.spiritlhl.net/" "https://ghproxy.com/" "http://cdn2.spiritlhl.net/")
check_cdn_file

first_digit=${CTID:0:1}
second_digit=${CTID:1:1}
third_digit=${CTID:2:1}
if [ $first_digit -le 2 ]; then
    if [ $second_digit -eq 0 ]; then
        num=$third_digit
    else
        num=$second_digit$third_digit
    fi
else
    num=$((first_digit - 2))$second_digit$third_digit
fi

user_ip="172.16.1.${num}"
if [ "$system_arch" = "x86" ]; then
    pct create $CTID ${storage}:vztmpl/$system_name -cores $core -cpuunits 1024 -memory $memory -swap 128 -rootfs ${storage}:${disk} -onboot 1 -features nesting=1
else
    temp_system_name="${en_system}-arm64-${version}-cloud.tar.xz"
    pct create $CTID ${storage}:vztmpl/${temp_system_name} -cores $core -cpuunits 1024 -memory $memory -swap 128 -rootfs ${storage}:${disk} -onboot 1 -features nesting=1
fi
pct start $CTID
pct set $CTID --hostname $CTID
pct set $CTID --net0 name=eth0,ip=${user_ip}/24,bridge=vmbr1,gw=172.16.1.1
pct set $CTID --nameserver 1.1.1.1
pct set $CTID --searchdomain local
sleep 3
if echo "$system" | grep -qiE "centos|almalinux|rockylinux"; then
    pct exec $CTID -- yum install -y curl
    if [[ -z "${CN}" || "${CN}" != true ]]; then
        pct exec $CTID -- yum update -y 
        pct exec $CTID -- yum update
        pct exec $CTID -- yum install -y dos2unix curl
    else
        pct exec $CTID -- yum install -y curl
        pct exec $CTID -- curl -lk https://gitee.com/SuperManito/LinuxMirrors/raw/main/ChangeMirrors.sh -o ChangeMirrors.sh
        pct exec $CTID -- chmod 777 ChangeMirrors.sh
        pct exec $CTID -- ./ChangeMirrors.sh --source mirrors.tuna.tsinghua.edu.cn --web-protocol http --intranet false --close-firewall true --backup true --updata-software false --clean-cache false --ignore-backup-tips
        pct exec $CTID -- rm -rf ChangeMirrors.sh
        pct exec $CTID -- yum install -y dos2unix
    fi
else
    if [[ -z "${CN}" || "${CN}" != true ]]; then
        pct exec $CTID -- apt-get update -y
        pct exec $CTID -- dpkg --configure -a
        pct exec $CTID -- apt-get update
        pct exec $CTID -- apt-get install dos2unix curl -y
    else
        pct exec $CTID -- apt-get install curl -y --fix-missing
        pct exec $CTID -- curl -lk https://gitee.com/SuperManito/LinuxMirrors/raw/main/ChangeMirrors.sh -o ChangeMirrors.sh
        pct exec $CTID -- chmod 777 ChangeMirrors.sh
        pct exec $CTID -- ./ChangeMirrors.sh --source mirrors.tuna.tsinghua.edu.cn --web-protocol http --intranet false --close-firewall true --backup true --updata-software false --clean-cache false --ignore-backup-tips
        pct exec $CTID -- rm -rf ChangeMirrors.sh
        pct exec $CTID -- apt-get install dos2unix -y
    fi
fi
pct exec $CTID -- curl -L ${cdn_success_url}https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/ssh.sh -o ssh.sh
pct exec $CTID -- chmod 777 ssh.sh
pct exec $CTID -- dos2unix ssh.sh
pct exec $CTID -- bash ssh.sh
# 禁止PVE自动修改网络接口设置
pct exec $CTID -- touch /etc/network/.pve-ignore.interfaces
# 禁止PVE自动修改DNS设置
pct exec $CTID -- touch /etc/.pve-ignore.resolv.conf
# 禁止PVE自动修改主机名设置
pct exec $CTID -- touch /etc/.pve-ignore.hosts
pct exec $CTID -- touch /etc/.pve-ignore.hostname
