#! /bin/bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends ansible git

git clone https://github.com/naoto67/isucon7-ansible.git ./ansible-isucon
(
  cd ansible-isucon
  PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ansible-playbook -i local site.yml
)
rm -rf ansible-isucon

wget https://dl.google.com/go/go1.14.6.linux-amd64.tar.gz
tar -xzf go1.14.6.linux-amd64.tar.gz
sudo install go/bin/go /usr/local/bin/
