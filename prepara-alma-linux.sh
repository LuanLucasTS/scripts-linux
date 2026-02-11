dnf install -y epel-release
dnf install -y yum-utils
dnf-config-manager --setopt=fastestmirror=True --save
dnf update -y
sudo dnf install -y nano vim wget curl git htop unzip zip bash-completion net-tools bind-utils  traceroute rsync chrony
systemctl enable --now chronyd
timedatectl set-timezone America/Campo_Grande
sudo dnf install -y fail2ban
sudo systemctl enable --now fail2ban
reboot
