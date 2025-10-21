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

    uci add_list dhcp.lan.dhcp_option='223.5.5.5'
    uci add_list dhcp.lan.dhcp_option='119.29.29.29'

    uci commit network
    
    log "The network configuration has been applied"
}


# 设置PPPoE（如果提供了凭据）
setup_pppoe() {
    if [ -n "$PPPOE_USERNAME" ] && [ -n "$PPPOE_PASSWORD" ]; then
        log "Setting up PPPoE connection with username: $PPPOE_USERNAME"
        
        uci set network.wan=interface
        uci set network.wan.proto='pppoe'
        uci set network.wan.ifname='eth1'  # 根据实际情况调整
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

# 执行配置
setup_basic
apply_network_config
setup_pppoe
# setup_ipv6

# 重启服务
/etc/init.d/network restart
/etc/init.d/firewall restart
log "Network services restarted"

log "First boot configuration completed successfully"

# 清理临时文件
rm -f /tmp/build_env

exit 0