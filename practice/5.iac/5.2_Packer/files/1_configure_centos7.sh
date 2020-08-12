set -x
adduser username
usermod -aG wheel username
# yum install vim -y
# mv xpaste /home/username/
# setenforce 0
echo 'username     ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

mv /root/xpaste /home/username/
chown -R username:username /home/username/xpaste/

## Disable Selinux
cat > /etc/selinux/config << EOF
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#       enforcing - SELinux security policy is enforced.
#       permissive - SELinux prints warnings instead of enforcing.
#       disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of these two values:
#       targeted - Targeted processes are protected,
#       mls - Multi Level Security protection.
SELINUXTYPE=targeted
EOF

