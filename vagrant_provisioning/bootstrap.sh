#!/bin/bash

## Update the system >/dev/null 2>&1
echo "[TASK] Updating the system"
#yum install -y epel-release
yum update -y

## Install desired packages
echo "[TASK] Installing desired packages"
yum install -y java-1.8.0-openjdk

## Enable password authentication
echo "[TASK] Enabled password authentication in sshd config"
sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
systemctl reload sshd

## Disable Password authentication
#echo "[TASK] Disabled Password authentication in sshd config"
#sed -i -e "\\#PasswordAuthentication yes# s#PasswordAuthentication yes#PasswordAuthentication no#g" /etc/ssh/sshd_config
#systemctl reload sshd

## Set Root Password
echo "[TASK] Set root password"
echo "centos" | passwd --stdin root >/dev/null 2>&1

## Disable and Stop firewalld
echo "[TASK] Disable and stop firewalld"
systemctl disable firewalld
systemctl stop firewalld

## Disable SELinux
echo "[TASK] Disable SELinux"
setenforce 0
sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

## Cleanup system >/dev/null 2>&1
echo "[TASK] Cleanup system"
package-cleanup -y --oldkernels --count=1
yum -y autoremove
yum clean all
rm -rf /tmp/*
rm -f /var/log/wtmp /var/log/btmp
#dd if=/dev/zero of=/EMPTY bs=1M
#rm -f /EMPTY
cat /dev/null > ~/.bash_history && history -c

## Update hosts file
echo "[TASK] Update host file /etc/hosts"
cat >>/etc/hosts<<EOF
192.168.16.110 elksrv.testlab.local elksrv
192.168.16.120 client.testlab.local client
EOF

## Rebooting Server
echo "[TASK] Rebooting server"
echo ""
echo "========== Finished =========="
sudo reboot now
