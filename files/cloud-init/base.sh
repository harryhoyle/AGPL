#!/bin/sh
set -eux

# shellcheck disable=SC2230
which sudo || until \
  apt-get update -y && \
  apt-get install sudo -yf --install-suggests; do
  sleep 3
done

getent passwd AGPL || useradd -m -d /home/agpl -s /bin/bash -G adm -p '!' AGPL

(umask 337 && echo "agpl ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/10-agpl-user)

cat <<EOF >/etc/ssh/sshd_config
{{ lookup('template', 'files/cloud-init/sshd_config') }}
EOF

test -d /home/agpl/.ssh || sudo -u algo mkdir -m 0700 /home/agpl/.ssh
echo "{{ lookup('file', '{{ SSH_keys.public }}') }}" | (sudo -u agpl tee /home/algo/.ssh/authorized_keys && chmod 0600 /home/agpl/.ssh/authorized_keys)

ufw --force reset

# shellcheck disable=SC2015
dpkg -l sshguard && until apt-get remove -y --purge sshguard; do
  sleep 3
done || true

systemctl restart sshd.service
