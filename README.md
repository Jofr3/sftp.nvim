# sftp.nvim

`sftp.nvim` is a Neovim plugin that simplifies file uploads using `rsync`.

## Features

* Detects if the current project is an SFTP-enabled project.
* Automatically uploads files to the server on save.
* Creates remote directories if they don’t exist.

## Installation

### Lazy

```lua
return {
    "Jofr3/sftp.nvim",
    opts = {}
}
```

## Setup

### 1. Add hosts to your `~/.ssh/config`:

```ssh
Host example_host
  Port 22
  User user_name
  HostName example_host.com
  IdentityFile ~/.ssh/keys/key.pem

Host *
  ForwardAgent no
  AddKeysToAgent no
  Compression no
  ServerAliveInterval 0
  ServerAliveCountMax 3
  HashKnownHosts no
  UserKnownHostsFile ~/.ssh/known_hosts
  ControlMaster auto
  ControlPath ~/.ssh/control-%r@%h:%p
  ControlPersist 10m
```

*Tip:* The `Control*` options keep SSH connections persistent.

### 2. Test the SSH connection and add the host to known hosts:

```bash
ssh example_host
```

### 3. Add your project to the plugin configuration:

```lua
{
    projects = {
        {
            local_path = "/home/username/projects/example_project",
            host = "example_host", -- Matches the host in your SSH config
            remote_path = "/remote_project_root",
        }
    }
}
```

## Usage

Enter or `cd` into a configured project and save a file — it will be uploaded automatically.

## Roadmap

* [ ] Download files from server
* [ ] Delete files on server
* [ ] Password-based authentication (FTP)

## Caveats

* Only supports passwordless SSH authentication.
* The server must be in your known hosts for uploads to work.
