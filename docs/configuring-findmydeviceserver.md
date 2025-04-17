<!--
SPDX-FileCopyrightText: 2020 - 2024 MDAD project contributors
SPDX-FileCopyrightText: 2020 - 2024 Slavi Pantaleev
SPDX-FileCopyrightText: 2020 Aaron Raimist
SPDX-FileCopyrightText: 2020 Chris van Dijk
SPDX-FileCopyrightText: 2020 Dominik Zajac
SPDX-FileCopyrightText: 2020 Mickaël Cornière
SPDX-FileCopyrightText: 2022 François Darveau
SPDX-FileCopyrightText: 2022 Julian Foad
SPDX-FileCopyrightText: 2022 Warren Bailey
SPDX-FileCopyrightText: 2023 Antonis Christofides
SPDX-FileCopyrightText: 2023 Felix Stupp
SPDX-FileCopyrightText: 2023 Pierre 'McFly' Marty
SPDX-FileCopyrightText: 2024 - 2025 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Setting up FindMyDeviceServer

This is an [Ansible](https://www.ansible.com/) role which installs [FindMyDeviceServer](https://gitlab.com/Nulide/findmydeviceserver) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

FindMyDeviceServer is the official server for [FindMyDevice (FMD)](https://gitlab.com/Nulide/findmydevice), which allows you to locate, ring, wipe and issue other commands to your Android device when it is lost.

See the project's [documentation](https://gitlab.com/Nulide/findmydeviceserver/-/blob/master/README.md) to learn what FindMyDeviceServer does and why it might be useful to you.

## Adjusting the playbook configuration

To enable FindMyDeviceServer with this role, add the following configuration to your `vars.yml` file.

**Note**: the path should be something like `inventory/host_vars/mash.example.com/vars.yml` if you use the [MASH Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

```yaml
########################################################################
#                                                                      #
# findmydeviceserver                                                   #
#                                                                      #
########################################################################

findmydeviceserver_enabled: true

########################################################################
#                                                                      #
# /findmydeviceserver                                                  #
#                                                                      #
########################################################################
```

### Set the hostname

To enable FindMyDeviceServer you need to set the hostname as well. To do so, add the following configuration to your `vars.yml` file. Make sure to replace `example.com` with your own value.

```yaml
findmydeviceserver_hostname: "example.com"
```

After adjusting the hostname, make sure to adjust your DNS records to point the domain to your server.

**Note**: hosting FindMyDeviceServer under a subpath (by configuring the `findmydeviceserver_path_prefix` variable) does not seem to be possible due to FindMyDeviceServer's technical limitations.

### Set the path for storing a database file on the host

For a persistent storage for a database file, you need to add a Docker volume to mount in the container to share it with the host machine.

To add the volume, prepare a directory on the host machine and add the following configuration to your `vars.yml` file:

```yaml
findmydeviceserver_database_path: /path/on/the/host
```

Make sure permissions of the directory specified to `/path/on/the/host`.

### Set a registration token (optional)

With the default setting, the instance will be public and open to registration by anyone.

To make it private and have it require a token for registration, set it by adding the following configuration to your `vars.yml` file. Make sure to replace `YOUR_TOKEN_HERE` with your own value. Generating a strong token (e.g. `pwgen -s 64 1`) is recommended.

```yaml
findmydeviceserver_config_registrationtoken: YOUR_TOKEN_HERE
```

### Extending the configuration

There are some additional things you may wish to configure about the component.

Take a look at:

- [`defaults/main.yml`](../defaults/main.yml) for some variables that you can customize via your `vars.yml` file.

## Installing

After configuring the playbook, run the installation command of your playbook as below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start
```

If you use the MASH playbook, the shortcut commands with the [`just` program](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/just.md) are also available: `just install-all` or `just setup-all`

## Usage

After running the command for installation, FindMyDeviceServer becomes available at the specified hostname like `https://example.com`.

## Troubleshooting

### Check the service's logs

You can find the logs in [systemd-journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html) by logging in to the server with SSH and running `journalctl -fu findmydeviceserver` (or how you/your playbook named the service, e.g. `mash-findmydeviceserver`).
