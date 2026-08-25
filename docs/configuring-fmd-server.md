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

# Setting up FMD Server

This is an [Ansible](https://www.ansible.com/) role which installs [FMD Server](https://gitlab.com/fmd-foss/fmd-server) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

FMD Server is the official server for [FMD (FindMyDevice)](https://gitlab.com/fmd-foss/fmd-android), which allows you to locate, ring, wipe and issue other commands to your Android device when it is lost.

See the project's [documentation](https://gitlab.com/fmd-foss/fmd-server/-/blob/master/README.md) to learn what FMD Server does and why it might be useful to you.

## Adjusting the playbook configuration

To enable FMD Server with this role, add the following configuration to your `vars.yml` file.

**Note**: the path should be something like `inventory/host_vars/mash.example.com/vars.yml` if you use the [MASH Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

```yaml
########################################################################
#                                                                      #
# fmd_server                                                           #
#                                                                      #
########################################################################

fmd_server_enabled: true

########################################################################
#                                                                      #
# /fmd_server                                                          #
#                                                                      #
########################################################################
```

### Set the hostname

To enable FMD Server you need to set the hostname as well. To do so, add the following configuration to your `vars.yml` file. Make sure to replace `example.com` with your own value.

```yaml
fmd_server_hostname: "example.com"
```

After adjusting the hostname, make sure to adjust your DNS records to point the domain to your server.

**Note**: hosting FMD Server under a subpath (by configuring the `fmd_server_path_prefix` variable) does not seem to be possible due to FMD Server's technical limitations.

### Set a registration token (recommended)

With the default setting, the instance is public: anyone who can reach the hostname can create an account on it, without invitation, approval or rate limit, by sending a single request to `PUT /api/v1/device`. Whoever does so can then use your server to store location history and photos from their own devices — up to `fmd_server_config_maxsavedloc` locations and `fmd_server_config_maxsavedpic` pictures per account, indefinitely, on your disk. FMD Server has no administration interface for listing or removing the accounts that appear this way.

What such a stranger cannot do is read anyone else's data. Locations, pictures and the account's private key are encrypted by the FMD client before they are uploaded, the private key is unlocked with the account's password, and every read of stored data requires an access token obtained by logging in (`POST /api/v1/requestAccess`), which FMD Server locks after five failed attempts.

To make the instance private and have it require a token for registration, set it by adding the following configuration to your `vars.yml` file. Make sure to replace `YOUR_TOKEN_HERE` with your own value. Generating a strong token (e.g. `pwgen -s 64 1`) is recommended.

```yaml
fmd_server_config_registrationtoken: YOUR_TOKEN_HERE
```

The token is only checked at registration time. Devices that have already registered keep working if you set, change or remove it later, so adding one to an instance that is already in use closes it to new registrations without disturbing the existing devices.

### Extending the configuration

There are some additional things you may wish to configure about the service.

Take a look at:

- [`defaults/main.yml`](../defaults/main.yml) for some variables that you can customize via your `vars.yml` file.

## Installing

After configuring the playbook, run the installation command of your playbook as below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start
```

If you use the MASH playbook, the shortcut commands with the [`just` program](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/just.md) are also available: `just install-all` or `just setup-all`

## Usage

After running the command for installation, FMD Server becomes available at the specified hostname like `https://example.com`.

To use it, first you need to [download the client (FMD)](https://f-droid.org/packages/de.nulide.findmydevice/) and install it on your device. Open the application, go to Settings, select "FMD Server", and input the URL to the "Server URL" area. Then, select "Register" to register the device to the server by inputting FMD ID, password, and the registration token specified to `fmd_server_config_registrationtoken` if the instance is set to private.

After registering the device to the server, please make sure to grant necessary permissions to the application as instructed on it. You also might want to log in to the instance on a web browser and test if the application and server work as expected by dispatching commands from the UI to ring the phone, lock it, have it take photos with front and back cameras, etc.

## Upgrading

FMD Server keeps its state in a SQLite database under `{{ fmd_server_database_path }}` (`/findmydeviceserver/database` by default), and it migrates that database itself, at startup. Bumping `fmd_server_version` and re-running the playbook is therefore the whole upgrade — there is no separate migration step to run, and nothing asks for confirmation.

The migrations only go forward. Upstream [does not implement "down" migrations](https://gitlab.com/fmd-foss/fmd-server/-/blob/master/docs/database.md), and ships the generated `*.down.sql` files empty on purpose, so pinning `fmd_server_version` back to the previous release does not undo a migration that has already run. Back the database directory up before upgrading, and keep the backup until the devices have checked in successfully.

## Troubleshooting

### Check the service's logs

You can find the logs in [systemd-journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html) by logging in to the server with SSH and running `journalctl -fu findmydeviceserver` (or how you/your playbook named the service, e.g. `mash-findmydeviceserver`).
