nh-root-help(){
  echo "
  remote configuration file v 001
  -------------------------------
  Run this remotely via ssh.

  Requires:
    - running as root
    - new user name, usually admin as it will be added to sudo group.

  Configures a server for api hosting and data federated  processing.
  "
}

# updates os
nh-root-update-os(){
  apt-get update
  apt-get -y upgrade
}

# install required dependencies
nh-root-install-deps() {
  apt -y install nginx
  apt -y install snapd
  snap install node --classic --channel=14
  node -v
  apt-get remove certbot
  snap install --classic certbot
  snap install doctl # added 7/28/21 -zo
  apt -y install jq # added 8/3/21
  apt -y install daemonize # added 8/3/21
}

nh-root-add-admin(){
    adduser --disabled-password \
	    --ingroup sudo \
	    --gecos "" \
	    admin
}

# added 08/18/21
nh-root-add-devops(){
    adduser --disabled-password \
	    --ingroup sudo \
	    --gecos "" \
	    devops
}

nh-root-security(){
  echo "%sudo   ALL=(ALL:ALL)  NOPASSWD: ALL" >> /etc/sudoers
  ufw allow 'Nginx Full'
  systemctl status nginx
}

nh-root-init-ssh(){
# Requires first argument to be publc key.
  mkdir ~/.ssh
  chmod 0700 ~/.ssh
  touch ~/.ssh/authorized_keys
  echo $1 > ~/.ssh/authorized_keys
  chmod 0600 ~/.ssh/authorized_keys
}

nh-root-copy-keys(){
  mkdir /home/admin/.ssh
  cp /root/.ssh/authorized_keys /home/admin/.ssh/authorized_keys
  chown -R admin:admin /home/admin/.ssh
  chmod 0700 /home/admin/.ssh
  chmod 0600 /home/admin/.ssh/authorized_keys
}

# Much tighter. Moves most stuff to admin phase.
nh-root-init(){
  nh-root-update-os
  nh-root-install-deps
  nh-root-add-admin
  nh-root-add-devops
  nh-root-copy-keys
  nh-root-security
}
