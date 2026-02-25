# AGENTS.md - Homelab Ansible Repository

## Overview
This repository contains Ansible playbooks and roles to configure and manage a Proxmox homelab server. It handles disk configuration, power management, and LXC container deployment.

## Server Hardware
- **CPU**: AMD Ryzen 7 5700X (with C-states enabled in BIOS)
- **Proxmox Host**: 192.168.1.2
- **OS Drive**: `/dev/nvme2n1` (Lexar 1TB NVMe)
- **Fast Storage**: `/dev/nvme0n1` (MSI M470 PRO 2TB NVMe) - LXC, Docker, LLM models
- **Quick Share**: `/dev/nvme1n1` (WD Blue SN580 1TB) - Samba quick-access
- **Backup Pool**: `/dev/sde` + `/dev/sdf` (2x 1TB ADATA SSD) - ZFS mirror
- **Documents Pool**: `/dev/sdc` + `/dev/sdd` (2x 4TB WD IronWolf) - Mirror
- **Media Drive**: `/dev/sda` (10TB) - Movies, TV series
- **Toshiba**: `/dev/sdb` (3TB) - Unassigned, available for future use

---

## Build / Lint / Test Commands

### Running Playbooks

```bash
# Run all playbooks (disk + power + LXC)
ansible-playbook -i inventory/hosts.ini playbooks/setup-all.yml

# Run individual playbooks
ansible-playbook -i inventory/hosts.ini playbooks/disk-setup.yml
ansible-playbook -i inventory/hosts.ini playbooks/power-management.yml
ansible-playbook -i inventory/hosts.ini playbooks/lxc-create.yml

# Run individual LXC containers
ansible-playbook -i inventory/hosts.ini playbooks/lxc-docker.yml
ansible-playbook -i inventory/hosts.ini playbooks/lxc-tailscale.yml
ansible-playbook -i inventory/hosts.ini playbooks/lxc-homeassistant.yml
ansible-playbook -i inventory/hosts.ini playbooks/lxc-pihole.yml
ansible-playbook -i inventory/hosts.ini playbooks/lxc-samba.yml
```

### Syntax Check

```bash
# Check playbook syntax
ansible-playbook --syntax-check playbooks/disk-setup.yml
ansible-playbook --syntax-check playbooks/power-management.yml
ansible-playbook --syntax-check playbooks/lxc-create.yml
```

### Running Specific Tasks (Tags)

```bash
# Run only disk-related tasks
ansible-playbook -i inventory/hosts.ini playbooks/disk-setup.yml --tags "partition"

# Run only ZFS tasks
ansible-playbook -i inventory/hosts.ini playbooks/disk-setup.yml --tags "zfs"

# Run only HDD spin-down configuration
ansible-playbook -i inventory/hosts.ini playbooks/power-management.yml --tags "apm"

# Run only specific LXC container creation
ansible-playbook -i inventory/hosts.ini playbooks/lxc-create.yml --tags "homeassistant"
```

### Dry Run (Check Mode)

```bash
# Preview changes without applying
ansible-playbook -i inventory/hosts.ini playbooks/disk-setup.yml --check
ansible-playbook -i inventory/hosts.ini playbooks/power-management.yml --check
```

### Running Single Test/Task

```bash
# Run a single task using ansible.builtin.debug with --tag
# Or use ansible's -C for check mode on specific hosts

# Example: Test disk detection only
ansible -i inventory/hosts.ini homelab -m command -a "lsblk"

# Example: Test ZFS module
ansible -i inventory/hosts.ini homelab -m community.general.zfs -a "name=tank state=present"
```

### Linting

```bash
# Install ansible-lint
pip install ansible-lint

# Lint all playbooks
ansible-lint playbooks/*.yml
ansible-lint roles/*/tasks/*.yml

# Lint specific file
ansible-lint playbooks/disk-setup.yml
```

---

## Code Style Guidelines

### YAML Formatting
- Use 2 spaces for indentation
- Use `ansible_managed` or `__ansible_managed` comments for templates
- Keep lines under 160 characters when possible
- Use YAML multiline syntax for long strings:
  ```yaml
  # Good
  description: |
    This is a long description
    that spans multiple lines.
  
  # Avoid
  description: "This is a long description that spans multiple lines."
  ```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Playbooks | `noun-verb.yml` | `disk-setup.yml`, `lxc-create.yml` |
| Roles | `role-name/` | `disk-config/`, `power-saving/` |
| Variables | `snake_case` | `mount_point`, `disk_device` |
| Tags | `snake_case` | `partition`, `zfs`, `apm` |
| Tasks | `verb-noun` | `create_partition`, `configure_apm` |
| Facts | `ansible_*` | `ansible_devices`, `ansible_mounts` |

### Variable Precedence
- Use `group_vars/all.yml` for common variables
- Use `host_vars/<hostname>.yml` for host-specific overrides
- Avoid using `vars:` in playbooks when possible
- Document all variables in role `defaults/main.yml`

### Import Organization

```yaml
# Playbook structure order:
- name: Play description
  hosts: <target>
  become: yes  # if root needed
  vars_files:  # external vars
    - vars/secrets.yml
  vars:        # inline vars (minimal)
    - debug: false
  pre_tasks:   # run before roles
    - name: Gather facts
      ansible.builtin.setup:
  roles:       # roles to apply
    - role: disk-config
      tags: ['disk']
  tasks:       # inline tasks (minimal)
    - name: Final task
      ...
  post_tasks:  # run after roles
    - name: Notify handler
      ...
  handlers:    # handlers
    - name: Reload systemd
      ...
```

### Error Handling

```yaml
# Always use failed_when for conditional failures
- name: Detect disk
  ansible.builtin.command: lsblk {{ disk_device }}
  register: disk_check
  failed_when: disk_check.rc not in [0, 2]
  changed_when: false

# Use block/rescue for critical operations
- name: Critical disk operation
  block:
    - name: Create partition
      ansible.builtin.parted:
        device: /dev/sda
        label: gpt
  rescue:
    - name: Rollback message
      ansible.builtin.debug:
        msg: "Failed to create partition, manual intervention required"

# Use ignore_errors sparingly
- name: Optional cleanup
  ansible.builtin.file:
    path: /tmp/cleanup
    state: absent
  ignore_errors: true  # Only for truly optional tasks
```

### Idempotency
- All tasks must be idempotent (safe to run multiple times)
- Use `check_mode: yes` with `register:` to detect changes
- Use `changed_when:` to control when task reports changes
- Example:
  ```yaml
  - name: Create mount point
    ansible.builtin.file:
      path: /mnt/media
      state: directory
    register: mount_creation
    changed_when: mount_creation.changed  # Only report if actually created
  ```

### Disk/Partition Safety
- **NEVER** operate on `/dev/nvme2n1` (OS drive) or any boot drive
- Always verify device identity using `by-id` or `by-path`, never just `sda/nvme0n1`
- Use `ansible.builtin.wait_for_device` before partitioning
- Include `unsafe_writes: no` for fstab entries
- Backup GPT headers before modifying partitions:
  ```yaml
  - name: Backup GPT header
    ansible.builtin.command: sgdisk --backup={{ backup_file }} {{ device }}
  ```

### ZFS Configuration
- Use `community.general.zfs` module
- Set appropriate ashift (12 for 4K drives, 9 for 512b)
- Include compression and deduplication settings in vars
- Always set mountpoint to `legacy` and manage via fstab

### LXC Configuration
- Use `proxmox_lxc` module from `community.general`
- Always specify `ostype: debian` and `osversion: 13`
- Enable nesting for Docker-in-LXC: `features: { nesting: 1 }`
- Use `pct` command for post-creation configuration

### Power Management
- Never force CPU governor - check current state first
- Use `ansible.builtin.command` with `cpuinfo` to detect CPU
- For APM: test with `hdparm -I` first to verify drive support
- Include rollback mechanism for critical power settings

---

## Project Structure

```
homelab/
├── AGENTS.md                    # This file
├── inventory/
│   └── hosts.ini                # Target hosts
├── group_vars/
│   └── all.yml                  # Shared variables
├── host_vars/
│   └── proxmox.yml              # Host-specific vars
├── playbooks/
│   ├── disk-setup.yml           # Disk partitioning, ZFS, mergefs
│   ├── power-management.yml     # CPU governor, HDD APM
│   ├── lxc-create.yml           # Create LXC containers
│   └── setup-all.yml            # Run all playbooks
├── roles/
│   ├── disk-config/
│   │   ├── defaults/main.yml
│   │   └── tasks/main.yml
│   ├── power-saving/
│   │   ├── defaults/main.yml
│   │   └── tasks/main.yml
│   └── lxc/
│       ├── defaults/main.yml
│       └── tasks/main.yml
└── templates/                   # Jinja2 templates
```

---

## Variables (group_vars/all.yml)

Key variables defined for the homelab:

| Variable | Description | Default |
|----------|-------------|---------|
| `proxmox_host` | Proxmox IP/hostname | `192.168.1.2` |
| `ssh_key_path` | SSH public key for LXC access | `~/.ssh/id_rsa.pub` |
| `disk_config` | Dictionary of disk configurations | (see file) |
| `lxc_containers` | List of LXC definitions | (see file) |
| `hdd_spindown_timeout` | Idle minutes before spin-down | `10` |
| `cpu_governor` | CPU power governor | `powersave` |

---

## Troubleshooting

### Disk Not Detected
```bash
# Check if disk is visible
lsblk
ansible homelab -m command -a "lsblk -d -o NAME,SIZE,MODEL"

# Check by-id links
ansible homelab -m command -a "ls -la /dev/disk/by-id/"
```

### ZFS Pool Issues
```bash
# Check ZFS status
ansible homelab -m command -a "zpool status"

# Import pool
ansible homelab -m command -a "zpool import -d /dev/disk/by-id"
```

### LXC Creation Fails
```bash
# Check Proxmox templates
ansible homelab -m command -a "pct list"
ansible homelab -m command -a "pveam available"

# Check storage
ansible homelab -m command -a "pvs"
ansible homelab -m command -a "vgs"
```

### Power Settings Not Applied
```bash
# Verify current governor
ansible homelab -m command -a "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"

# Check C-states
ansible homelab -m command -a "cat /sys/devices/system/cpu/cpu*/cpuidle/state*/disable"
```

---

## Security Notes

- Never commit secrets to version control
- Use `ansible-vault` for sensitive variables
- Keep SSH keys outside of repo (add to `.gitignore`)
- Proxmox API tokens should be in `host_vars/` with restricted permissions
