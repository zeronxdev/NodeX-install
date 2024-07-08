clear
echo "   1. Cài đặt NodeX"
echo "   2. Cập nhật cấu hình"
echo "   3. Thêm node"
read -p "  Chọn tính năng và nhấn Enter (Mặc định là Cài đặt):  " num
[ -z "${num}" ] && num="1"

install(){
    ufw allow 80
    ufw allow 443
    clear
    read -p " Nhập URL website (Không có https://): " api_host
    [ -z "${api_host}" ] && api_host=0
    echo "--------------------------------"
    #key web
    read -p " Nhập API KEY: " api_key
    [ -z "${api_key}" ] && api_key=0
    echo "--------------------------------"
    pre_install
}
pre_install(){
    clear
    read -p "Nhập số lượng node cần cài (Tối đa 2 node): " n
    [ -z "${n}" ] && n="1"
    if [ "$n" -ge 2 ] ; then
        n="2"
    fi
    a=0
    while [ $a -lt $n ]
    do
        echo -e "Node thứ $((a+1))"
        echo -e "[1] Vmess"
        echo -e "[2] Vless"
        echo -e "[3] Trojan"
        read -p "Chọn giao thức node (Mặc định là Vmess):" NodeType
        if [ "$NodeType" == "1" ]; then
            NodeType="V2ray"
            NodeName="Vmess"
            EnableVless="false"
            elif [ "$NodeType" == "2" ]; then
            NodeType="V2ray"
            NodeName="Vless"
            EnableVless="true"
            elif [ "$NodeType" == "3" ]; then
            NodeType="Trojan"
            NodeName="Trojan"
            EnableVless="false"
        else
            NodeType="V2ray"
            EnableVless="false"
        fi
        echo "Giao thức đã chọn: $NodeName"
        echo "--------------------------------"
        
        #node id
        read -p "ID Node:" node_id
        [ -z "${node_id}" ] && node_id=0
        echo "-------------------------------"
        
        config
        a=$((a+1))
    done
}

#clone node
clone_node(){
    clear
    #link web
    read -p " Nhập URL website (Không có https://): " api_host
    [ -z "${api_host}" ] && api_host=0
    echo "--------------------------------"
    echo "URL website: https://${api_host}"
    echo "--------------------------------"
    #key web
    read -p " Nhập API KEY: " api_key
    [ -z "${api_key}" ] && api_key=0
    echo "--------------------------------"
    echo "API KEY: ${api_key}"
    echo "--------------------------------"
    #node type
    echo -e "[1] Vmess"
    echo -e "[2] Vless"
    echo -e "[3] Trojan"
    read -p "Chọn giao thức (Mặc định là Vmess):" NodeType
    if [ "$NodeType" == "1" ]; then
        NodeType="V2ray"
        EnableVless="false"
        elif [ "$NodeType" == "2" ]; then
        NodeType="V2ray"
        EnableVless="true"
        elif [ "$NodeType" == "3" ]; then
        NodeType="Trojan"
        EnableVless="false"
    else
        NodeType="V2ray"
        EnableVless="false"
    fi
    echo "Giao thức đã chọn: $NodeType"
    echo "--------------------------------"
    #node id
    read -p "ID Node:" node_id
    [ -z "${node_id}" ] && node_id=0
    echo "-------------------------------"
    config
}

config(){
    cd /etc/NodeX
cat >>config.yml<<EOF
  - PanelType: "NewV2board" # Panel type: Xpanel, SSpanel, NewV2board, PMpanel, Proxypanel
    ApiConfig:
      ApiHost: "https://$api_host"
      ApiKey: "$api_key"
      NodeID: $node_id
      NodeType: $NodeType # Node type: V2ray, Shadowsocks, Trojan, Shadowsocks-Plugin
      Timeout: 30 
      EnableVless: $EnableVless 
      EnableXTLS: false
      SpeedLimit: 0 
      DeviceLimit: 0 
      RuleListPath: # /etc/NodeX/rulelist 
      DisableCustomConfig: false 
    ControllerConfig:
      DisableSniffing: True
      ListenIP: 0.0.0.0 
      SendIP: 0.0.0.0 
      UpdatePeriodic: 10 
      DeviceOnlineMinTraffic: 1024 
      EnableDNS: false 
      DNSType: AsIs 
      EnableProxyProtocol: false 
      CertConfig:
        CertMode: file
        CertDomain: "8.8.8.8"
        CertFile: /etc/NodeX/nodex.crt 
        KeyFile: /etc/NodeX/nodex.key
        Provider: cloudflare
        Email: test@me.com
        DNSEnv: 
          ALICLOUD_ACCESS_KEY: aaa
          ALICLOUD_SECRET_KEY: bbb
EOF
}

case "${num}" in
    1) bash <(curl -Ls https://raw.githubusercontent.com/zeronxdev/NodeX-install/main/install.sh)
        openssl req -newkey rsa:2048 -x509 -sha256 -days 365 -nodes -out /etc/NodeX/nodex.crt -keyout /etc/NodeX/nodex.key -subj "/C=JP/ST=Tokyo/L=Chiyoda-ku/O=Google Trust Services LLC/CN=google.com"
        cd /etc/NodeX
  cat >config.yml <<EOF
Log:
  Level: none # Log level: none, error, warning, info, debug
  AccessPath: # /etc/NodeX/access.Log
  ErrorPath: # /etc/NodeX/error.log
DnsConfigPath: # /etc/NodeX/dns.json # Path to dns config, check https://xtls.github.io/config/dns.html for help
RouteConfigPath: # /etc/NodeX/route.json # Path to route config, check https://xtls.github.io/config/routing.html for help
InboundConfigPath: # /etc/NodeX/custom_inbound.json # Path to custom inbound config, check https://xtls.github.io/config/inbound.html for help
OutboundConfigPath: # /etc/NodeX/custom_outbound.json # Path to custom outbound config, check https://xtls.github.io/config/outbound.html for help
ConnectionConfig:
  Handshake: 3 
  ConnIdle: 1000 
  UplinkOnly: 2 
  DownlinkOnly: 4
  BufferSize: 64 
Nodes:
EOF
        install
        cd /root
        nodex start
    ;;
    2) cd /etc/NodeX
cat >config.yml <<EOF
    Log:
      Level: none # Log level: none, error, warning, info, debug
      AccessPath: # /etc/NodeX/access.Log
      ErrorPath: # /etc/NodeX/error.log
    DnsConfigPath: # /etc/NodeX/dns.json # Path to dns config, check https://xtls.github.io/config/dns.html for help
    RouteConfigPath: # /etc/NodeX/route.json # Path to route config, check https://xtls.github.io/config/routing.html for help
    InboundConfigPath: # /etc/NodeX/custom_inbound.json # Path to custom inbound config, check https://xtls.github.io/config/inbound.html for help
    OutboundConfigPath: # /etc/NodeX/custom_outbound.json # Path to custom outbound config, check https://xtls.github.io/config/outbound.html for help
    ConnetionConfig:
      Handshake: 3 
      ConnIdle: 1000 
      UplinkOnly: 2 
      DownlinkOnly: 4 
      BufferSize: 64 
    Nodes:
EOF
        install
        cd /root
        nodex restart
    ;;
    3) cd /etc/NodeX
        clone_node
        cd /root
        nodex restart
    ;;
esac
