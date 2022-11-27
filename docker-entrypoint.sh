#!/bin/sh
if [[ "${1}" != '/usr/sbin/sshd' ]] || [[ "${2}" != '-D' ]] || [[ "${#}" -ne 2 ]]; then
  echo 'docker-entrypoint.sh NOT called with /usr/sbin/sshd -D'
  exit 1
fi

# generate SSH HostKeys if not provided
# and append them to sshd_config if not already added
for algorithm in rsa ecdsa ed25519
do
  keyfile=/etc/ssh/keys/ssh_host_${algorithm}_key
  [ -f $keyfile ] || ssh-keygen -q -N '' -f $keyfile -t $algorithm
  grep -q "HostKey $keyfile" /etc/ssh/sshd_config || echo "HostKey $keyfile" >> /etc/ssh/sshd_config
done

# Fix permissions at every startup
chown -R git:git /var/lib/git

# Setup gitolite admin
if [ ! -f /var/lib/git/.ssh/authorized_keys ]; then
  if [ -n "$SSH_KEY" ]; then
    [ -n "$SSH_KEY_NAME" ] || SSH_KEY_NAME=admin
    echo "$SSH_KEY" > "/tmp/$SSH_KEY_NAME.pub"
    su - git -c "gitolite setup -pk \"/tmp/$SSH_KEY_NAME.pub\""
    rm "/tmp/$SSH_KEY_NAME.pub"
  else
    echo "You need to specify SSH_KEY on first run to setup gitolite"
    echo "You can also use SSH_KEY_NAME to specify the key name (optional)"
    exit 1
  fi
# Check setup at every startup
else
  su - git -c "gitolite setup"
fi

exec "$@"
