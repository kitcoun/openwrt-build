#!/bin/sh

log() {
    echo "[FirstBoot] $1" | logger -t firstboot
}

log "Starting first boot configuration..."

apply_network_config() {
    log "Application Network Configuration..."
    
    # 设置LAN口
    uci set network.lan.ipaddr="${LAN_IP:-192.168.2.1}"
    uci set network.lan.netmask="${LAN_NETMASK:-255.255.255.0}"

    uci add_list dhcp.lan.dhcp_option='6,223.5.5.5,119.29.29.29'

    uci commit network
    
    log "The network configuration has been applied"
}


# 设置PPPoE（如果提供了凭据）
setup_pppoe() {
    if [ -n "$PPPOE_USERNAME" ] && [ -n "$PPPOE_PASSWORD" ]; then
        log "Setting up PPPoE connection with username: $PPPOE_USERNAME"
        
        uci set network.wan=interface
        uci set network.wan.proto='pppoe'
        uci set network.wan.ifname='wan'  # 根据实际情况调整
        uci set network.wan.username="$PPPOE_USERNAME"
        uci set network.wan.password="$PPPOE_PASSWORD"
        uci set network.wan.metric='10'
        
        uci commit network
        log "PPPoE configuration completed"
    else
        log "No PPPoE credentials provided, skipping PPPoE setup"
    fi
}

# 基础系统配置
setup_basic() {
    log "Configuring basic system settings..."
    
    # 设置时区
    uci set system.@system[0].timezone='UTC-8'
    uci set system.@system[0].zonename='Asia/Shanghai'
    
    # 设置主机名
    uci set system.@system[0].hostname="OpenWrt-${CONFIG_NAME:-Router}"

    # 修改源
    sed -i 's_downloads.openwrt.org_mirrors.ustc.edu.cn/openwrt_' /etc/opkg/distfeeds.conf
    
    uci commit system
}

# 启用IPv6
setup_ipv6() {
    log "Enabling IPv6 support..."
    
    if [ -f "/root/enable-ipv6.sh" ]; then
        log "Executing IPv6 setup script..."
        sh /root/enable-ipv6.sh
    else
        log "IPv6 script not found, using basic IPv6 configuration"
        
        # 基础IPv6配置
        uci set network.wan.ipv6='1'
        uci set network.wan6=interface
        uci set network.wan6.proto='dhcpv6'
        uci set network.wan6.ifname='@wan'
        uci set network.wan6.reqaddress='try'
        uci set network.wan6.reqprefix='auto'
        
        uci set network.lan.ip6assign='60'
        uci set dhcp.lan.dhcpv6='server'
        uci set dhcp.lan.ra='server'
        
        uci commit network
        uci commit dhcp
    fi
}

# 设置不指定接口并开放22端口入站
setup_firewall_ssh() {
    echo "22 port"
    
    # 添加允许SSH(22端口)的防火墙规则
    uci add firewall rule
    uci set firewall.@rule[-1].name='Allow-SSH'
    uci set firewall.@rule[-1].src='wan'
    uci set firewall.@rule[-1].proto='tcp'
    uci set firewall.@rule[-1].src_port='22'
    uci set firewall.@rule[-1].dest_port='22'
    uci set firewall.@rule[-1].target='ACCEPT'
    uci set firewall.@rule[-1].enabled='1'
    
    # 提交防火墙配置
    uci commit firewall

    # uci delete dropbear.@dropbear[0].Interface

    uci commit dropbear
}

# 开放防火墙端口
setup_firewall_http() {
    echo "80 port"
    
    # 添加允许HTTP(80端口)的防火墙规则
    uci add firewall rule
    uci set firewall.@rule[-1].name='Allow-HTTP'
    uci set firewall.@rule[-1].src='wan'
    uci set firewall.@rule[-1].proto='tcp'
    uci set firewall.@rule[-1].dest_port='80'
    uci set firewall.@rule[-1].target='ACCEPT'
    uci set firewall.@rule[-1].enabled='1'

    # 允许从WAN访问lan1的所有TCP端口
    uci add firewall rule
    uci set firewall.@rule[-1].src='wan'
    uci set firewall.@rule[-1].dest='lan'
    uci set firewall.@rule[-1].name='Allow-WAN-TCP-Lan1'
    uci add_list firewall.@rule[-1].dest_ip='10.0.0.136'
    uci set firewall.@rule[-1].dest_port='8000-9000'
    uci set firewall.@rule[-1].target='ACCEPT'

    # 远程桌面端口
    uci add firewall rule
    uci set firewall.@rule[-1].src='wan'
    uci set firewall.@rule[-1].dest='lan'
    uci set firewall.@rule[-1].name='Remote Desktop'
    uci set firewall.@rule[-1].src_port='3389'
    uci add_list firewall.@rule[-1].dest_ip='10.0.0.136'
    uci set firewall.@rule[-1].dest_port='3389'
    uci set firewall.@rule[-1].target='ACCEPT'
    
    # 提交防火墙配置
    uci commit firewall
}

# ddns设置
setup_ddns(){
    # 安装软件
    apkg update
    opkg install curl libustream-openssl
    opkg install openssl-util
    opkg install luci-app-ddns

    # 删除
    uci del ddns.myddns_ipv4

    # 阿里云ddns
    # 前置条件，修改username和password,查看下面的链接
    # https://github.com/kitcoun/ddns-scripts-aliyun/tree/master?tab=readme-ov-file
    # 本设备
    uci del ddns.myddns_ipv6.update_url
    uci del ddns.myddns_ipv6.domain
    uci del ddns.myddns_ipv6.username
    uci del ddns.myddns_ipv6.password
    uci del ddns.myddns_ipv6.ip_source
    uci del ddns.myddns_ipv6.ip_network
    uci del ddns.myddns_ipv6.interface
    uci set ddns.myddns_ipv6.enabled='1'
    uci set ddns.myddns_ipv6.service_name='aliyun.com'
    uci del ddns.myddns_ipv6.service_name
    uci set ddns.myddns_ipv6.service_name='aliyun.com'
    uci set ddns.myddns_ipv6.lookup_host='ly.dmsp.com'
    uci set ddns.myddns_ipv6.domain='ly@dmsp.com'
    uci set ddns.myddns_ipv6.username='xxxxx'
    uci set ddns.myddns_ipv6.password='xxxxx'
    uci set ddns.myddns_ipv6.ip_source='script'
    uci set ddns.myddns_ipv6.ip_script='/usr/lib/ddns/wanv6script.sh'
    uci set ddns.myddns_ipv6.interface='wan6'
    uci set ddns.myddns_ipv6.use_syslog='2'

    # 下级设备，修改username和password
    uci set ddns.lan1_ipv6=service
    uci set ddns.lan1_ipv6.service_name='aliyun.com'
    uci set ddns.lan1_ipv6.use_ipv6='1'
    uci set ddns.lan1_ipv6.enabled='1'
    uci set ddns.lan1_ipv6.lookup_host='pc.dmsp.com'
    uci set ddns.lan1_ipv6.domain='pc@dmsp.com'
    uci set ddns.lan1_ipv6.username='xxxxx'
    uci set ddns.lan1_ipv6.password='xxxxx'
    uci set ddns.lan1_ipv6.ip_source='script'
    uci set ddns.lan1_ipv6.ip_script='/usr/lib/ddns/lanv6script.sh'
    uci set ddns.lan1_ipv6.interface='lan'
    uci set ddns.lan1_ipv6.use_syslog='2'

    uci commit ddns

    /etc/init.d/ddns restart
}

# 防止ARP缓存过期导致无法唤醒
setup_arp(){
    # 添加静态ARP条目
    # 路由器重启或长时间后ARP条目会自动清除
    # 在局域网内只需要知道MAC地址就可以唤醒设备，无论关机多久，ARP表是否过期
    # 远程唤醒，也只需要在唤醒前添加arp就可以了   

    # 添加到本地启动脚本中
    # sed -i '/^exit 0$/i\nsleep 15\narp -s 10.0.0.136 AA:BB:CC:DD:EE:FF' /etc/rc.local
}

# 安装软件
setup_app(){
    apkg update

    # 启用 BBR TCP 拥塞控制内核模块（如果内核支持）
    opkg install kmod-tcp-bbr
}

#upnp
setup_upnp(){
    # 现有还有问题
    # 备份当前配置
    cp /etc/config/upnpd /etc/config/upnpd.backup

    # 重置配置
cat > /etc/config/upnpd << 'EOF'
    config upnpd 'config'
        option enabled '1'
        option enable_upnp '1'
        option enable_natpmp '0'
        option enable_pcp '0'
        option use_stun '0'
        option enable_ipv6 '1'
        option external_iface 'wan'
        option internal_iface 'lan'
        option download '1024'
        option upload '512'
        option port '5000'
        option upnp_lease_file '/var/run/miniupnpd.leases'
        option igdv1 '1'
        option uuid '11cc567f-ea58-4245-999d-95b6f6857740'
        option secure_mode '1'

    config perm_rule
        option action 'allow'
        option ext_ports '1024-65535'
        option int_addr '0.0.0.0/0'
        option int_ports '1024-65535'
        option comment 'Allow high ports'

    config perm_rule
        option action 'deny'
        option ext_ports '0-65535'
        option int_addr '0.0.0.0/0'
        option int_ports '0-65535'
        option comment 'Default deny'
EOF
        
    # 设置外部接口
    uci set upnpd.config.external_iface='wan'

    # 设置Presentation URL (请将示例地址替换为您路由器的实际LAN IP)
    # uci set upnpd.config.presentation_url='http://[fd00::1]' 
    uci add_list upnpd.config.presentation_url='http://10.0.0.1'

    uci commit upnpd
    # 重启服务
    /etc/init.d/miniupnpd restart
}

setup_acme(){
    # 阿里云自签证书
    # 下载脚本到/etc/acme/dnsapi/
    # https://github.com/acmesh-official/acme.sh/blob/master/dnsapi/dns_ali.sh

    uci set acme.@acme[0].account_email='mynickchen@Outlook.com'
    uci set acme.@acme[0].debug='0'
    uci set acme.dnscard=cert
    uci set acme.dnscard.enabled='1'
    uci set acme.dnscard.validation_method='dns'
    uci set acme.dnscard.dns='dns_ali'
    uci set acme.dnscard.credentials='Ali_Key="xxxx"' 'Ali_Secret="xxxxx"'
    uci set acme.dnscard.staging='0'
    uci set acme.dnscard.key_type='ec256'
    uci set acme.dnscard.domains='dmsp.asia' '*.dmsp.asia'
    
    uci commit acme
    # 重启服务
    /etc/init.d/acme restart
    # 重新执行
    # /etc/init.d/acme renew
    # 监听日志
    # logread -f | grep -i "_acme-challenge\|txt value" &
}


# 执行配置
setup_basic
apply_network_config
setup_pppoe
# setup_ipv6
# setup_firewall_ssh
# setup_firewall_http
# setup_ddns

# 重启服务
/etc/init.d/network restart
/etc/init.d/firewall restart
/etc/init.d/dropbear restart
log "Network services restarted"

log "First boot configuration completed successfully"

# 清理临时文件
rm -f /tmp/build_env

exit 0