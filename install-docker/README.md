install-docker
=========

Add docker repository and install required packages

Requirements
------------

Debian installed on host system. User with root privileges or root access.

Role Variables
--------------

docker_apt_release_channel by default is set to stable.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: install-docker, docker_apt_release_channel: stable }

License
-------

BSD