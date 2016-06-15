#
# Setup Root keys
#

# Load utility functions
. ./functions.sh

if [ Ã! -e keys.pub ]; then
  echo "error, no keys.pub found for root"
else
  mkdir -p "${R}/root/.ssh"
  chmod 700 "${R}/root/.ssh"
  install_readonly keys.pub "${R}/root/.ssh/authorized_keys"
fi
