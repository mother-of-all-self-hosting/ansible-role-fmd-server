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

# Setting up Redlib

This is an [Ansible](https://www.ansible.com/) role which installs [Redlib](https://github.com/redlib-org/redlib) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

Redlib allows you to browse Reddit without exposing your IP address, browsing habits, and other browser fingerprinting data to the website.

See the project's [documentation](https://github.com/redlib-org/redlib/blob/main/README.md) to learn what Redlib does and why it might be useful to you.

## Adjusting the playbook configuration

To enable Redlib with this role, add the following configuration to your `vars.yml` file.

**Note**: the path should be something like `inventory/host_vars/mash.example.com/vars.yml` if you use the [MASH Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

```yaml
########################################################################
#                                                                      #
# redlib                                                               #
#                                                                      #
########################################################################

redlib_enabled: true

########################################################################
#                                                                      #
# /redlib                                                              #
#                                                                      #
########################################################################
```

### Set the hostname

To enable Redlib you need to set the hostname as well. To do so, add the following configuration to your `vars.yml` file. Make sure to replace `example.com` with your own value.

```yaml
redlib_hostname: "example.com"
```

After adjusting the hostname, make sure to adjust your DNS records to point the domain to your server.

**Note**: hosting Redlib under a subpath (by configuring the `redlib_path_prefix` variable) is technically possible but not recommended, as most of the functions do not work as expected due to Redlib's technical limitations (pages and resources are not correctly loaded, and links are broken).

### Configure instance and user settings (optional)

There are various options for the instance and user settings.

For example, if you want to enable SFW-only mode for the instance, add the following configuration to your `vars.yml` file.

```yaml
redlib_environment_variables_redlib_sfw_only: on
```

If you want to set the default theme for users, add and adjust the following configuration to your `vars.yml` file:

```yaml
# Valid values: system, light, dark, black, dracula, nord, laserwave, violet, gold, rosebox, gruvboxdark, gruvboxlight
redlib_environment_variables_redlib_default_theme: system
```

To change the default front page for users, add and adjust the following configuration to your `vars.yml` file:

```yaml
# Valid values: default, popular, all
redlib_environment_variables_redlib_default_front_page: default
```

To enable blurring NSFW content by default for users, add the following configuration to your `vars.yml` file:

```yaml
redlib_environment_variables_redlib_default_blur_nsfw: on
```

### Extending the configuration

There are some additional things you may wish to configure about the component.

Take a look at:

- [`defaults/main.yml`](../defaults/main.yml) for some variables that you can customize via your `vars.yml` file. You can override settings (even those that don't have dedicated playbook variables) using the `redlib_environment_variables_additional_variables` variable

See [`.env.example`](https://github.com/redlib-org/redlib/blob/main/.env.example) for a complete list of Redlib's config options that you could put in `redlib_environment_variables_additional_variables`.

## Installing

After configuring the playbook, run the installation command of your playbook as below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start
```

If you use the MASH playbook, the shortcut commands with the [`just` program](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/just.md) are also available: `just install-all` or `just setup-all`

## Usage

After running the command for installation, Redlib becomes available at the specified hostname like `https://example.com`.

[Libredirect](https://libredirect.github.io/), an extension for Firefox and Chromium-based desktop browsers, has support for redirections to Redlib.

If you would like to make your instance public so that it can be used by anyone including Libredirect, please consider to send a PR to the [upstream project](https://github.com/redlib-org/redlib-instances) to add yours to the list, which Libredirect automatically fetches using a script (see [this FAQ entry](https://libredirect.github.io/faq.html#where_the_hell_are_those_instances_coming_from)). See [here](https://github.com/redlib-org/redlib-instances/blob/main/README.md) for details about how to do so.

## Troubleshooting

### Check the service's logs

You can find the logs in [systemd-journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html) by logging in to the server with SSH and running `journalctl -fu redlib` (or how you/your playbook named the service, e.g. `mash-redlib`).
