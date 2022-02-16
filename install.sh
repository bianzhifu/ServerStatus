#!/bin/bash
os_arch=""

pre_check() {
  command -v systemctl >/dev/null 2>&1
  if [[ $? != 0 ]]; then
    echo "不支持此系统：未找到 systemctl 命令"
    exit 1
  fi
  # check root
  [[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1

  ## os_arch
  if [[ $(uname -m | grep 'x86_64') != "" ]]; then
    os_arch="amd64"
  elif [[ $(uname -m | grep 'aarch64\|armv8b\|armv8l') != "" ]]; then
    os_arch="arm64"
  else
    echo "只支持amd64/arm64"
    exit 1
  fi
}

install() {
  echo -e "> 安装ServerStatus"

  mkdir -p /opt/ServerStatus/
  chmod 777 /opt/ServerStatus/

  echo -e "下载ServerStatus"
  wget -O ServerStatus_linux_${os_arch} https://github.com/bianzhifu/ServerStatus/releases/latest/download/ServerStatus_linux_${os_arch} >/dev/null 2>&1
  if [[ $? != 0 ]]; then
    echo -e "${red}下载失败,https://github.com/bianzhifu/ServerStatus/releases/latest/download/ServerStatus_linux_${os_arch}"
    return 0
  fi
  mv ServerStatus_linux_${os_arch} /opt/ServerStatus/ServerStatus
  chmod +x /opt/ServerStatus/ServerStatus

  echo -e "> 安装启动项"

  service_script=/etc/systemd/system/ServerStatus.service

  cat >$service_script <<EOFSCRIPT
[Unit]
Description=ServerStatus
After=syslog.target
#After=network.target

[Service]
LimitMEMLOCK=infinity
LimitNOFILE=65535
Type=simple
User=root
Group=root
WorkingDirectory=/opt/ServerStatus/
ExecStart=/opt/ServerStatus/ServerStatus -port=8888 -theme=badafans
Restart=always

[Install]
WantedBy=multi-user.target
EOFSCRIPT
  chmod +x $service_script

  echo -e "${green}安装成功，正在启动...${plain}"
  systemctl daemon-reload
  systemctl enable ServerStatus.service
  systemctl restart ServerStatus.service

  echo -e "启动成功，显示日志 ${plain}"
  journalctl -n10 -u ServerStatus.service
}

uninstall() {
  echo -e "> 卸载"
  systemctl disable ServerStatus.service
  systemctl stop ServerStatus.service
  rm -rf /etc/systemd/system/ServerStatus.service
  systemctl daemon-reload
  rm -rf /opt/ServerStatus/
}

restart() {
  echo -e "> 重启"
  systemctl daemon-reload
  systemctl restart ServerStatus.service
}

show_usage() {
  echo "使用方法: "
  echo "---------------------------------------"
  echo "./install.sh i               - 安装"
  echo "./install.sh u               - 卸载"
  echo "./install.sh r               - 重启"
  echo "---------------------------------------"
}
pre_check
case $1 in
"i")
  install $2
  ;;
"u")
  uninstall
  ;;
"r")
  restart
  ;;
*) show_usage ;;
esac
