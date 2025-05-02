#!/bin/bash
#========================================================================================================================
# https://github.com/ophub/amlogic-s9xxx-openwrt
# Description: Automatically Build OpenWrt
# Function: Diy script (After Update feeds, Modify the default IP, hostname, theme, add/remove software packages, etc.)
# Source code repository: https://github.com/immortalwrt/immortalwrt / Branch: master
#========================================================================================================================

# ------------------------------- Main source started -------------------------------
#
# Add the default password for the 'root' user（Change the empty password to 'password'）
# sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow

# Set etc/openwrt_release
# sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/base-files/files/etc/openwrt_release
# echo "DISTRIB_SOURCECODE='immortalwrt'" >>package/base-files/files/etc/openwrt_release

# Modify default IP（FROM 192.168.1.1 CHANGE TO 192.168.31.4）
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate
#
# ------------------------------- Main source ends -------------------------------

# ------------------------------- Other started -------------------------------
#
# Add luci-app-amlogic
# svn co https://github.com/ophub/luci-app-amlogic/trunk/luci-app-amlogic package/luci-app-amlogic

# Apply patch
# git apply ../config/patches/{0001*,0002*}.patch --directory=feeds/luci
#
# ------------------------------- Other ends -------------------------------

# 智能判断并设置2.4G和5G WiFi名称、密码、信道和带宽
cat > package/base-files/files/etc/uci-defaults/99-wifi-ssid-pass <<'EOF'
for dev in $(uci show wireless | grep "=wifi-device" | cut -d. -f2 | cut -d= -f1); do
    band=$(uci get wireless.$dev.band 2>/dev/null)
    if [ "$band" = "2g" ]; then
        # 查找对应iface
        iface=$(uci show wireless | grep "=wifi-iface" | cut -d. -f2 | cut -d= -f1 | while read i; do
            [ "$(uci get wireless.$i.device 2>/dev/null)" = "$dev" ] && echo $i && break
        done)
        uci set wireless.$iface.ssid='FREEWIFI'
        uci set wireless.$iface.encryption='psk2'
        uci set wireless.$iface.key='666666'
        uci set wireless.$dev.channel='13'
        uci set wireless.$dev.htmode='HT20'
        uci set wireless.$iface.disassoc_low_ack='0'
    elif [ "$band" = "5g" ]; then
        iface=$(uci show wireless | grep "=wifi-iface" | cut -d. -f2 | cut -d= -f1 | while read i; do
            [ "$(uci get wireless.$i.device 2>/dev/null)" = "$dev" ] && echo $i && break
        done)
        uci set wireless.$iface.ssid='FREEWIFI5G'
        uci set wireless.$iface.encryption='psk2'
        uci set wireless.$iface.key='666666'
        uci set wireless.$dev.channel='64'
        uci set wireless.$dev.htmode='VHT160'
        uci set wireless.$iface.disassoc_low_ack='0'
    fi
done
uci commit wireless
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-wifi-ssid-pass

