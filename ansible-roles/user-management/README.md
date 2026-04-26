# User Management Ansible Role

A comprehensive Ansible role for managing user accounts, SSH public keys, passwords, teams, join dates, and admin privileges across your infrastructure.

## Features

- ✅ Create user accounts with custom UID and groups
- ✅ Deploy SSH public keys for password-less authentication
- ✅ Set and manage user passwords (using bcrypt hashes)
- ✅ Organize users into teams/groups
- ✅ Track user join dates and metadata
- ✅ Configure sudo access for admin users
- ✅ Centralized user metadata logging
- ✅ Support for multiple teams and user roles

## Role Structure

```
user-management/
├── tasks/
│   └── main.yml           # Main tasks
├── handlers/
│   └── main.yml           # Event handlers
├── defaults/
│   └── main.yml           # Default variables
├── templates/
│   ├── user_sudoers.j2   # Sudoers configuration template
│   └── user_metadata.j2  # User metadata JSON template
├── files/                 # Static files (if needed)
├── meta/
│   └── main.yml          # Role metadata
└── README.md             # This file
```

## Requirements

- Ansible >= 2.9
- Target systems: Ubuntu 18.04+, CentOS 7+, RHEL
- Root or sudo access to target hosts
- `sudo` package installed on target systems

## Variables

### Default Variables (`defaults/main.yml`)

```yaml
# List of users to create
users: []

# Teams (secondary groups)
teams: []

# SSH authorized keys directory
ssh_key_dir: "/etc/ssh/authorized_keys"

# User home directory prefix
user_home_prefix: "/home"

# Default shell for new users
default_shell: "/bin/bash"

# Create home directories
create_home: true

# User metadata directory
user_metadata_dir: "/var/lib/user-metadata"
```

## User Structure

Define users in your inventory or playbook with the following structure:

```yaml
users:
  - username: john.doe
    uid: 1001
    group: developers           # Primary group
    groups: [developers, sudo] # Secondary groups (optional)
    team: developers           # Team name (optional)
    password: "$6$rounds=656000$..." # Encrypted bcrypt hash (optional)
    public_keys:
      - "ssh-rsa AAAB3NzaC1yc2EAAAADAQABAAABgQC..."
      - "ssh-rsa AAAB3NzaC1yc2EAAAADAQABAAABgQD..."
    is_admin: false
    joined_date: "2024-01-15"
    shell: "/bin/bash"
    home_dir: "/home/john.doe" # Optional, defaults to user_home_prefix/username

  - username: jane.smith
    uid: 1002
    group: devops
    team: devops
    password: "$6$rounds=656000$..."
    public_keys:
      - "ssh-rsa AAAB3NzaC1yc2EAAAADAQABAAABgQE..."
    is_admin: true             # Admin user with sudo access
    joined_date: "2024-01-10"
    shell: "/bin/bash"
```

## Teams Structure

Define teams/groups that users belong to:

```yaml
teams:
  - name: developers
    gid: 2001
  - name: devops
    gid: 2002
  - name: admins
    gid: 2003
```

## Generating Password Hashes

To generate bcrypt password hashes for the `password` field:

### Using Python:
```bash
python3 -c "from passlib.context import CryptContext; \
crypt = CryptContext(schemes=['bcrypt']); \
print(crypt.using(rounds=12).hash('mypassword'))"
```

### Using mkpasswd:
```bash
mkpasswd --method=sha-512 "mypassword"
```

### Using Ansible:
```bash
ansible localhost -m debug -a "msg={{ 'mypassword' | password_hash('sha512') }}"
```

## SSH Public Key Format

SSH public keys should be in OpenSSH format:

```
ssh-rsa AAAB3NzaC1yc2EAAAADAQABAAABgQC... user@hostname
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... user@hostname
```

## Usage Example

### 1. Create a playbook

```yaml
---
- hosts: all
  become: yes
  roles:
    - user-management
  vars:
    users:
      - username: alice
        uid: 1001
        group: engineers
        team: platform
        is_admin: true
        joined_date: "2024-01-01"
        public_keys:
          - "ssh-rsa AAAB3NzaC1yc2E..."
        shell: "/bin/bash"

      - username: bob
        uid: 1002
        group: engineers
        is_admin: false
        joined_date: "2024-02-15"
        public_keys:
          - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."
        shell: "/bin/bash"

    teams:
      - name: engineers
        gid: 2001
      - name: admins
        gid: 2002
```

### 2. Use variables from inventory

In your inventory file:

```ini
[webservers]
web1.example.com
web2.example.com

[all:vars]
# Define users once for all hosts
user_management_users = "{{ groups['all'] | map(attribute='users', default=[]) | list }}"
```

### 3. Run the playbook

```bash
ansible-playbook site.yml --tags users
```

## Output Files

### Metadata Directory

The role creates detailed metadata for each user:

```bash
/var/lib/user-metadata/
├── john.doe.json
├── jane.smith.json
└── ...
```

Each JSON file contains:
```json
{
  "username": "john.doe",
  "uid": 1001,
  "group": "developers",
  "team": "developers",
  "joined_date": "2024-01-15",
  "is_admin": false,
  "shell": "/bin/bash",
  "home_dir": "/home/john.doe",
  "ssh_keys_count": 2,
  "deployed_at": "2024-04-19T10:15:30.123456+00:00",
  "deployed_by": "ansible"
}
```

### Sudoers Configuration

Admin users are automatically configured in:
```
/etc/sudoers.d/user-admins
```

## Tags

The role supports the following tags:

- `users` - Execute all user-related tasks
- `user_accounts` - Create user accounts only
- `ssh_keys` - Deploy SSH public keys
- `sudo` - Configure sudo access
- `groups` - Create groups/teams
- `metadata` - Create metadata files
- `summary` - Display user deployment summary

## Running Specific Tasks

```bash
# Only create user accounts
ansible-playbook site.yml --tags user_accounts

# Only deploy SSH keys and configure sudo
ansible-playbook site.yml --tags "ssh_keys,sudo"

# Show summary without making changes (dry-run)
ansible-playbook site.yml --tags summary --check
```

## Security Considerations

1. **Password Hashes**: Always use encrypted password hashes, never plain text
2. **SSH Keys**: Use strong keys (at least 4096-bit RSA or ed25519)
3. **Sudoers**: The role validates sudoers syntax with `visudo` before applying
4. **Permissions**: SSH directories and files have proper permissions (700 for .ssh)
5. **Metadata Directory**: Created with 755 permissions for auditability but secure key storage

## Troubleshooting

### User already exists error
If you see errors about users already existing, ensure you're not trying to create duplicate users or that the home directory doesn't already exist with different permissions.

### SSH key authentication not working
1. Verify the public key format
2. Check .ssh directory permissions (should be 700)
3. Check authorized_keys permissions (should be 600)
4. Verify SSH daemon configuration allows public key auth

### Sudoers validation failed
The role validates sudoers syntax. If validation fails:
1. Check the generated /etc/sudoers.d/user-admins file
2. Run `visudo -cf /etc/sudoers.d/user-admins` manually to see errors
3. Ensure admin usernames are correct

### Metadata files not created
Check that:
1. The user_metadata_dir exists and is writable
2. Sufficient disk space is available
3. SELinux (if enabled) allows writing to the directory

## Limitations

- No automatic password rotation (manage separately)
- Does not manage user expiration automatically
- Requires encrypted password hashes; hashing is not done in the role
- SSH key rotation must be done by updating the users variable

## Example with All Features

```yaml
---
- name: Deploy users across infrastructure
  hosts: all
  become: yes
  
  roles:
    - user-management
  
  vars:
    # Create teams first
    teams:
      - name: devops
        gid: 2001
      - name: backend
        gid: 2002
      - name: frontend
        gid: 2003
      - name: admins
        gid: 2099
    
    # Define all users
    users:
      - username: alice.johnson
        uid: 1001
        group: devops
        team: devops
        is_admin: true
        joined_date: "2023-06-01"
        public_keys:
          - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJz..."
        shell: "/bin/bash"
      
      - username: bob.smith
        uid: 1002
        group: backend
        team: backend
        is_admin: false
        joined_date: "2024-01-15"
        password: "$6$rounds=656000$..."
        public_keys:
          - "ssh-rsa AAAB3NzaC1yc2EAAAADAQABAAABgQC..."
        shell: "/bin/bash"
      
      - username: charlie.brown
        uid: 1003
        group: frontend
        team: frontend
        is_admin: false
        joined_date: "2024-01-20"
        public_keys:
          - "ssh-rsa AAAB3NzaC1yc2EAAAADAQABAAABgQD..."
        shell: "/bin/bash"

  tasks:
    - name: Run user management role
      debug:
        msg: "Deploying users with all attributes"
      tags:
        - always
```

## Author

DevOps Team

## License

MIT
