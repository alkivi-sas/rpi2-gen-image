#
# Setup Salt Minion
#

# Load utility functions
. ./functions.sh


chroot_exec apt-get install -y --force-yes python resolvconf python-crypto python-msgpack python-zmq python-dateutil python-jinja2 python-apt python-yaml python-pkg-resources python-requests dctrl-tools wget python-pycurl libcurl3-gnutls python-backports.ssl-match-hostname python-singledispatch bsdmainutils

chroot_exec wget http://ftp.fr.debian.org/debian/pool/main/p/python-backports-abc/python-backports-abc_0.4-1_all.deb -O /tmp/python-backports.deb
chroot_exec dpkg -i /tmp/python-backports.deb
chroot_exec wget http://ftp.fr.debian.org/debian/pool/main/p/python-tornado/python-tornado_4.3.0-2_armhf.deb -O /tmp/python-tornado.deb
chroot_exec dpkg -i /tmp/python-tornado.deb
chroot_exec wget http://repo.saltstack.com/apt/debian/latest/salt-common_2016.3.0+ds-1_all.deb -O /tmp/salt-common.deb
chroot_exec dpkg -i /tmp/salt-common.deb
chroot_exec wget http://repo.saltstack.com/apt/debian/latest/salt-minion_2016.3.0+ds-1_all.deb -O /tmp/salt-minion.deb
chroot_exec dpkg -i /tmp/salt-minion.deb

