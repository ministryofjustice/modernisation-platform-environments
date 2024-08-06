##### Application server post-build user data

echo "Postbuild - Updating iptables"
service iptables stop
chkconfig iptables off
cd /usr/lib/
ln -s ../../lib/libdb-4.3.so libdb.so.3


# echo "Xvfb :0 -screen 0 6x6x8 -pn -fp /usr/share/X11/fonts/misc -sp /root/SecurityPolicy &
# export DISPLAY=LAWS2197DEV2-app1:0.0
# twm &
# xhost +" >> /etc/rc.local

echo "Postbuild - Updating bin32"
mkdir -p /usr/bin32
cat <<EOT > /usr/bin32/gcc296
#!/bin/sh
exec /usr/bin/gcc34 -m32 -static-libgcc -B/usr/lib -L/usr/lib/gcc-lib/i386-redhat-linux/2.96/ "$@"
EOT

cat <<EOT > /usr/bin32/g++296
#!/bin/sh
exec /usr/bin/g++34 -m32 -static-libgcc -B/usr/lib/gcc-lib/i386-redhat-linux/2.96/ "$@"
EOT

cd /usr/bin32
ln -s gcc296 gcc
ln -s g++296 g++


echo "Postbuild - Updating bash profile"
cat <<EOT > /home/applmgr/.bash_profile
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
           . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH
export LDEMULATION=elf_i386
export PATH=/usr/bin32:/sbin:/usr/sbin:/bin:/usr/bin
. /CWA/app/appl/APPSCWA_SERVER_HOSTNAME.env
EOT



echo "Postbuild - Setting up ntp"
sed -i.bak 's/ nfs.enable_ino64=0//g' /boot/grub/grub.conf
sed -i '/kernel/s/$/ nfs.enable_ino64=0/' /boot/grub/grub.conf

su applmgr -c "rm /CWA/app/comn/html/jsp/bsc/bscpgraph.jsp"

/bin/cp -f -p /etc/ntp.conf /etc/ntp.conf.bck
sed -i "s/server 0.rhel.pool.ntp.org/server 169.254.169.123/g" /etc/ntp.conf
sed -i "s/server 1.rhel.pool.ntp.org/#server 1.rhel.pool.ntp.org/g" /etc/ntp.conf
sed -i "s/server 2.rhel.pool.ntp.org/#server 2.rhel.pool.ntp.org/g" /etc/ntp.conf

service ntpd start
chkconfig ntpd on
