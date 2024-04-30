#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

version="v1.0.0"

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Lỗi: ${plain} Tập lệnh này phải được chạy với người dùng root！\n" && exit 1

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
    echo -e "${red}Không thể xác định hệ điều hành, hãy kiểm tra và thử lại！${plain}\n" && exit 1
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
        echo -e "${red}Vui lòng sử dụng hệ điều hành CentOS 7 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ điều hành Ubuntu 16 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ điều hành Debian 8 trở lên！${plain}\n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [Mặc định $2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Xác nhận khởi động lại NodeX?" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Nhấn enter để quay lại menu chính: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/zeronxdev/NodeX-install/main/NodeX.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    if [[ $# == 0 ]]; then
        echo && echo -n -e "Nhập phiên bản được chỉ định (mặc định sẽ cài đặt phiên bản mới nhất): " && read version
    else
        version=$2
    fi
#    confirm "Chức năng này sẽ buộc cài đặt lại phiên bản mới nhất và dữ liệu sẽ không bị mất. Bạn có muốn tiếp tục không?" "n"
#    if [[ $? != 0 ]]; then
#        echo -e "${red}Đã hủy${plain}"
#        if [[ $1 != 0 ]]; then
#            before_show_menu
#        fi
#        return 0
#    fi
    bash <(curl -Ls https://raw.githubusercontent.com/zeronxdev/NodeX-install/main/NodeX.sh) $version
    if [[ $? == 0 ]]; then
        echo -e "${green}Cập nhật hoàn tất và NodeX đã tự động khởi động lại, vui lòng sử dụng nodex log để xem nhật ký${plain}"
        exit
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

config() {
    echo "NodeX sẽ tự động thử khởi động lại sau khi sửa đổi cấu hình"
    nano /etc/NodeX/config.yml
    sleep 2
    check_status
    case $? in
        0)
            echo -e "Trạng thái NodeX: ${green}Đang chạy${plain}"
            ;;
        1)
            echo -e "Bạn chưa khởi động NodeX hoặc NodeX không thể tự khởi động lại, bạn có muốn kiểm tra log？[Y/n]" && echo
            read -e -p "(Mặc định: y):" yn
            [[ -z ${yn} ]] && yn="y"
            if [[ ${yn} == [Yy] ]]; then
               show_log
            fi
            ;;
        2)
            echo -e "Trạng thái NodeX: ${red}Chưa cài đặt${plain}"
    esac
}

uninstall() {
    confirm "Bạn có chắc chắn muốn gỡ cài đặt NodeX không? [Y/N] " "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop NodeX
    systemctl disable NodeX
    rm -f /etc/systemd/system/NodeX.service 
    systemctl daemon-reload
    systemctl reset-failed
    rm -rf /etc/NodeX
    rm -rf /usr/local/NodeX

    echo ""
    echo -e "Gỡ cài đặt NodeX thành công. Nếu bạn muốn xóa tập lệnh này, hãy chạy lệnh sau ${green}rm /usr/bin/NodeX -f${plain}"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}NodeX khởi chạy thành công${plain}"
    else
        systemctl start NodeX
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}NodeX đã khởi chạy thành công, vui lòng sử dụng nodex log để xem nhật ký${plain}"
        else
            echo -e "${red}NodeX khởi chạy thất bại, vui lòng sử dụng nodex log để xem nhật ký${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    systemctl stop NodeX
    sleep 2
    check_status
    if [[ $? == 1 ]]; then
        echo -e "${green}Dừng NodeX thành công${plain}"
    else
        echo -e "${red}NodeX không dừng được, vui lòng kiểm tra lại${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart NodeX
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}NodeX đã khởi chạy lại thành công, vui lòng sử dụng nodex log để xem nhật ký${plain}"
    else
        echo -e "${red}NodeX không khởi chạy được, vui lòng sử dụng nodex log để xem nhật ký${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status NodeX --no-pager -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable NodeX
    if [[ $? == 0 ]]; then
        echo -e "${green}Thiết lập NodeX tự khởi động thành công${plain}"
    else
        echo -e "${red}NodeX không tự khởi chạy${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable NodeX
    if [[ $? == 0 ]]; then
        echo -e "${green}Thiết lập NodeX không tự khởi động thành công${plain}"
    else
        echo -e "${red}NodeX không thể hủy tự động khởi chạy${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u NodeX.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    bash <(curl -L -s https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh)
    #if [[ $? == 0 ]]; then
    #    echo ""
    #    echo -e "${green}Quá trình cài đặt bbr thành công, vui lòng khởi động lại máy chủ${plain}"
    #else
    #    echo ""
    #    echo -e "${red}Không thể tải xuống tập lệnh cài đặt bbr, vui lòng kiểm tra xem máy có thể kết nối với Github không${plain}"
    #fi

    #before_show_menu
}

update_shell() {
    wget -O /usr/bin/NodeX -N --no-check-certificate https://raw.githubusercontent.com/zeronxdev/NodeX-install/main/cmd.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Không thể tải xuống tập lệnh, vui lòng kiểm tra kết nối mạng${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/NodeX
        echo -e "${green}Tập lệnh nâng cấp thành công, vui lòng chạy lại tập lệnh${plain}" && exit 0
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

check_enabled() {
    temp=$(systemctl is-enabled NodeX)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}NodeX đã được cài đặt, vui lòng không cài đặt lại${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}Vui lòng cài đặt NodeX trước${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "Trạng thái NodeX: ${green}Đang chạy${plain}"
            show_enable_status
            ;;
        1)
            echo -e "Trạng thái NodeX: ${yellow}không chạy${plain}"
            show_enable_status
            ;;
        2)
            echo -e "Trạng thái NodeX: ${red}Chưa cài đặt${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Có tự khởi chạy hay không: ${green}Có${plain}"
    else
        echo -e "Có tự khởi chạy hay không: ${red}Không${plain}"
    fi
}

show_NodeX_version() {
    echo -n "Phiên bản NodeX ："
    /usr/local/NodeX/NodeX -version
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_usage() {
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

show_menu() {
    echo -e "
  ${green}Tập lệnh quản lý phụ trợ NodeX，${plain}${red}không hoạt động với Docker${plain}
◄▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬►
  ${green}0.${plain} Thiết lập file Config NodeX
————————————————
  ${green}1.${plain} Cài đặt NodeX
  ${green}2.${plain} Cập nhật NodeX
  ${green}3.${plain} Gỡ cài đặt NodeX
————————————————
  ${green}4.${plain} Khởi chạy NodeX
  ${green}5.${plain} Dừng NodeX
  ${green}6.${plain} Khởi động lại NodeX
  ${green}7.${plain} Xem trạng thái NodeX
  ${green}8.${plain} Xem log NodeX
————————————————
  ${green}9.${plain} Cài đặt NodeX tự khởi chạy
 ${green}10.${plain} Hủy tự khởi chạy NodeX
————————————————
 ${green}11.${plain} Cài đặt nhanh bbr (phụ trợ giúp tăng tốc mạng)
 ${green}12.${plain} Xem phiên bản NodeX 
 ${green}13.${plain} Cập nhật tập lệnh NodeX
 ◄▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬𝐂𝐎𝐏𝐘𝐑𝐈𝐆𝐇𝐓©𝐇𝐓𝟒𝐆𝐕𝐏𝐍▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬►
 "
 #Các bản cập nhật tiếp theo có thể được thêm vào chuỗi trên
    show_status
    echo && read -p "Vui lòng nhập lựa chọn [0-13]: " num

    case "${num}" in
        0) config
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && start
        ;;
        5) check_install && stop
        ;;
        6) check_install && restart
        ;;
        7) check_install && status
        ;;
        8) check_install && show_log
        ;;
        9) check_install && enable
        ;;
        10) check_install && disable
        ;;
        11) install_bbr
        ;;
        12) check_install && show_NodeX_version
        ;;
        13) update_shell
        ;;
        *) echo -e "${red}Vui lòng nhập số chính xác [0-13]: ${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "update") check_install 0 && update 0 $2
        ;;
        "config") config $*
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        "version") check_install 0 && show_NodeX_version 0
        ;;
        "update_shell") update_shell
        ;;
        *) show_usage
    esac
else
    show_menu
fi