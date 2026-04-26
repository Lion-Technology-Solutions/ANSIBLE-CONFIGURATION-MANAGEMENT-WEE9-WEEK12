# Quick Start Guide - User Management Role

## 1. Generate SSH Keys

```bash
# Generate new SSH key pair (if needed)
ssh-keygen -t ed25519 -C "user@example.com"

# Get the public key content
cat ~/.ssh/id_ed25519.pub
```

## 2. Generate Password Hashes

```bash
# Using Python (bcrypt)
python3 << EOF
from passlib.context import CryptContext
crypt = CryptContext(schemes=['bcrypt'])
print(crypt.using(rounds=12).hash('YourPassword123'))
EOF

# Using mkpasswd (if installed)
mkpasswd --method=sha-512

# Using Ansible directly
ansible localhost -m debug -a "msg={{ 'YourPassword123' | password_hash('sha512') }}"
```

## 3. Basic Playbook

Create `deploy_users.yml`:

```yaml
---
- hosts: all
  become: yes
  roles:
    - user-management
  vars:
    teams:
      - name: developers
        gid: 2001
    
    users:
      - username: john
        uid: 1001
        group: developers
        is_admin: false
        joined_date: "2024-04-19"
        public_keys:
          - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
        shell: "/bin/bash"
```

## 4. Run the Playbook

```bash
# Deploy to all hosts
ansible-playbook deploy_users.yml

# Deploy to specific hosts
ansible-playbook deploy_users.yml -i inventory.ini

# Dry run (no changes)
ansible-playbook deploy_users.yml --check

# Only create accounts, skip SSH keys
ansible-playbook deploy_users.yml --tags user_accounts

# Verbose output
ansible-playbook deploy_users.yml -vvv
```

## 5. Verify Deployment

```bash
# Check user exists
getent passwd john

# Check SSH keys
cat /home/john/.ssh/authorized_keys

# Check metadata
cat /var/lib/user-metadata/john.json

# Check sudo access
sudo -l -U john
```

## 6. Common Tasks

### Add a New User

```yaml
users:
  - username: newuser
    uid: 1004
    group: developers
    is_admin: false
    joined_date: "2024-04-19"
    public_keys:
      - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
```

### Make User an Admin

```yaml
users:
  - username: john
    uid: 1001
    is_admin: true  # Enable sudo access
```

### Add Multiple SSH Keys

```yaml
users:
  - username: john
    uid: 1001
    public_keys:
      - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
      - "ssh-rsa AAAB3NzaC1yc2EAAAADAQABAAABgQC..."
```

### Add User to Multiple Groups

```yaml
users:
  - username: john
    uid: 1001
    group: developers  # Primary group
    groups: [developers, devops, admins]  # Secondary groups
```

## 7. Troubleshooting

### User not created
- Check if user already exists: `id username`
- Verify UID is not in use: `getent passwd | grep ":1001:"`

### SSH keys not working
- Verify key format: `ssh-keygen -l -f /path/to/key.pub`
- Check permissions: `ls -la ~/.ssh/`
- Check logs: `sudo tail -f /var/log/auth.log`

### Sudo not working for admin
- Check sudoers: `sudo -l -U username`
- Verify is_admin: true in playbook
- Check sudoers syntax: `sudo visudo -cf /etc/sudoers.d/user-admins`

### Unable to run playbook
- Test SSH connection: `ansible all -m ping`
- Check inventory: `ansible-inventory -i inventory.ini --list`
- Verify become privilege: `ansible all -m debug -a "msg={{ ansible_user_id }}"`

## 8. Security Best Practices

1. **Always use encrypted passwords**: Never store plain text passwords
2. **Use strong SSH keys**: ed25519 keys are preferred over RSA
3. **Limit SSH keys**: Only deploy necessary keys per user
4. **Audit access**: Check metadata files regularly
5. **Rotate keys**: Update public_keys periodically
6. **Use inventory encryption**: Use Ansible Vault for sensitive data

## 9. Advanced Usage

### Using Ansible Vault for Passwords

```bash
# Create vault file
ansible-vault create group_vars/all/users.yml

# Edit vault file
ansible-vault edit group_vars/all/users.yml

# Run playbook with vault
ansible-playbook deploy_users.yml --ask-vault-pass
```

### Dynamic User List

```yaml
users: "{{ query('file', '/path/to/users.json') | from_json }}"
```

### Conditional User Deployment

```yaml
users: "{{ all_users | selectattr('deploy_to_host', 'equalto', inventory_hostname) | list }}"
```

## 10. Role Variables Summary

| Variable | Default | Description |
|----------|---------|-------------|
| `users` | `[]` | List of users to create |
| `teams` | `[]` | List of teams/groups |
| `user_home_prefix` | `/home` | Base path for home directories |
| `default_shell` | `/bin/bash` | Default shell for new users |
| `create_home` | `true` | Create home directories |
| `user_metadata_dir` | `/var/lib/user-metadata` | Directory for metadata files |

For more details, see README.md
