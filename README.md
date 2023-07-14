# Home lab
All I need to configure my home lab server on Debian.

## How to run playbooks
First, create an inventory file that contains `homelab` host definition.
Run one of the playbook.

Install tools like: htop, vim etc. (for more details check install-tools.yml file)
```shell 
ansible-playbook -i inventory install-tools.yml
```

Install docker service
```shell
ansible-playbook -i inventory install-docker.yml
```

Update system
```shell
ansible-playbook -i inventory update-system.yml
```

Deploy apps configured in docker-compose.yml.j2
```shell
ansible-playbook -i inventory --ask-vault-pass deploy-docker-compose.yml
```
password can be stored in a file and pass with --vault-password-file param. 
Will not work for WSL2 and files in windows filesystem.

Pull latest docker images and recreate containers.
```shell
ansible-playbook -i inventory --ask-vault-pass deploy-docker-compose.yml
```