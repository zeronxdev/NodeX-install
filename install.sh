#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Lỗi：${plain} Vui lòng chạy với quyền root (gõ lệnh sudo su để dùng quyền root)！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}Không định dạng được hệ điều hành, hãy thử lại！${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64-v8a"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="64"
    echo -e "${red}Không xác định được phiên bản: ${arch}${plain}"
fi

echo "Cấu trúc CPU: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "Phần mềm không hỗ trợ hệ thống 32bit, hãy thử với hệ thống 64bit"
    exit 2
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Vui lòng dùng hệ điều hành CentOS 7 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Phiên bản Ubuntu 18.04 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Phiên bản Debian 8 trở lên！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
	service firewalld stop
        yum install wget curl unzip tar ufw crontabs socat -y
    else
        apt update -y
        apt install wget curl unzip tar cron socat -y
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/NodeX.service ]]; then
        return 2
    fi
    temp=$(systemctl status NodeX | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

install_acme() {
    curl https://get.acme.sh | sh
}

install_NodeX() {
    if [[ -e /usr/local/NodeX/ ]]; then
        rm /usr/local/NodeX/ -rf
    fi

    mkdir /usr/local/NodeX/ -p
	cd /usr/local/NodeX/

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/zeronxdev/NodeX/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}Không xác định được phiên bản NodeX${plain}"
            exit 1
        fi
        echo -e "Phiên bản NodeX mới nhất：${last_version}，Bắt đầu cài đặt"
        wget -q -N --no-check-certificate -O /usr/local/NodeX/NodeX-linux.zip https://github.com/zeronxdev/NodeX/releases/download/${last_version}/NodeX-linux-${arch}.zip
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Không thể tải xuống NodeX, hãy thử lại!${plain}"
            exit 1
        fi
    else
        if [[ $1 == v* ]]; then
            last_version=$1
	else
	    last_version="v"$1
	fi
        url="https://github.com/zeronxdev/NodeX/releases/download/${last_version}/NodeX-linux-${arch}.zip"
        echo -e "Bắt đầu cài đặt NodeX ${last_version}"
        wget -q -N --no-check-certificate -O /usr/local/NodeX/NodeX-linux.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Phiên bản NodeX ${last_version} Lỗi, không xác định được phiên bản${plain}"
            exit 1
        fi
    fi

    unzip NodeX-linux.zip
    rm NodeX-linux.zip -f
    chmod +x *
    mkdir /etc/NodeX/ -p
    rm /etc/systemd/system/NodeX.service -f
    file="https://raw.githubusercontent.com/zeronxdev/NodeX-install/main/NodeX.service"
    wget -q -N --no-check-certificate -O /etc/systemd/system/NodeX.service ${file}
    #cp -f NodeX.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl stop NodeX
    systemctl enable NodeX
    echo -e "${green}NodeX ${last_version}${plain} Cài đặt hoàn tất!"
    cp geoip.dat /etc/NodeX/
    cp geosite.dat /etc/NodeX/ 

    if [[ ! -f /etc/NodeX/config.yml ]]; then
        cp config.yml /etc/NodeX/
        echo -e ""
        echo -e "Để cập nhật phiên bản vui lòng liên hệ admin"
    else
        systemctl start NodeX
        sleep 2
        check_status
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "${green}Khởi động NodeX thành công${plain}"
        else
            echo -e "${red}NodeX Không được khởi động được, vui lòng dùng NodeX log để check lỗi${plain}"
        fi
    fi

    if [[ ! -f /etc/NodeX/dns.json ]]; then
        cp dns.json /etc/NodeX/
    fi
    if [[ ! -f /etc/NodeX/route.json ]]; then
        cp route.json /etc/NodeX/
    fi
    if [[ ! -f /etc/NodeX/custom_outbound.json ]]; then
        cp custom_outbound.json /etc/NodeX/
    fi
    if [[ ! -f /etc/NodeX/custom_inbound.json ]]; then
        cp custom_inbound.json /etc/NodeX/
    fi
    if [[ ! -f /etc/NodeX/rulelist ]]; then
        cp rulelist /etc/NodeX/
    fi
    curl -o /usr/bin/NodeX -Ls https://raw.githubusercontent.com/zeronxdev/NodeX-install/main/cmd.sh
    chmod +x /usr/bin/NodeX
    ln -s /usr/bin/NodeX /usr/bin/nodex 
    chmod +x /usr/bin/nodex
    cd $cur_dir
    rm -f install.sh
    echo -e ""
    echo "Các lệnh sử dụng NodeX (Không phân biệt in hoa, in thường): "
    echo "◄▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬►"
    echo "NodeX                    - Hiện menu"
    echo "NodeX start              - Khởi chạy NodeX"
    echo "NodeX stop               - Dừng chạy NodeX"
    echo "NodeX restart            - Khởi động lại NodeX"
    echo "NodeX status             - Xem trạng thái NodeX"
    echo "NodeX enable             - Tự khởi chạy NodeX"
    echo "NodeX disable            - Hủy tự khởi chạy NodeX"
    echo "NodeX log                - Xem nhật kí NodeX"
    echo "NodeX update             - Nâng cấp NodeX"
    echo "NodeX update x.x.x       - Nâng cấp NodeX đến phiên bản x.x.x"
    echo "NodeX config             - Hiện thị tệp cấu hình"
    echo "NodeX install            - Cài đặt NodeX"
    echo "NodeX uninstall          - Gỡ cài đặt NodeX"
    echo "NodeX version            - Kiếm tra phiên bản NodeX"
    echo "◄▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬𝐂𝐎𝐏𝐘𝐑𝐈𝐆𝐇𝐓©𝐇𝐓𝟒𝐆𝐕𝐏𝐍▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬►"
}

echo -e "${green}BẮT ĐẦU CÀI ĐẶT${plain}"
install_base
# install_acme
install_NodeX $1
