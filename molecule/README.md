<!--
SPDX-FileCopyrightText: 2018-2025 Slavi Pantaleev
SPDX-FileCopyrightText: 2019-2022 Aaron Raimist
SPDX-FileCopyrightText: 2019-2023 MDAD project contributors
SPDX-FileCopyrightText: 2023 QEDeD
SPDX-FileCopyrightText: 2024 Fabio Bonelli
SPDX-FileCopyrightText: 2024 Nikita Chernyi
SPDX-FileCopyrightText: 2024-2026 Suguru Hirahara
SPDX-FileCopyrightText: 2026 spatterlight

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Molecule Testing

This role supports [Molecule](https://docs.ansible.com/projects/molecule/), an Ansible testing framework designed for developing and testing Ansible collections, playbooks, and roles.

## Prerequisites

To utilize Molecule you need to prepare several requirements:

- **x86** computer running one of these operating systems that make use of [systemd](https://systemd.io/):
  - **Archlinux**
  - **CentOS**, **Rocky Linux**, **AlmaLinux**, or possibly other RHEL alternatives (although your mileage may vary)
  - **Debian** (10/Buster or newer)
  - **Ubuntu** (18.04 or newer, although [20.04 may be problematic](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/ansible.md#supported-ansible-versions) if you run the Ansible playbook on it)
- `root` access on the computer which Molecule runs against
- [Ansible](http://ansible.com/) program
- [Python](https://www.python.org/)
  - Most distributions install Python by default, but some don't (e.g. Ubuntu 18.04) and require manual installation (something like `apt-get install python3`)
- [Docker](https://www.docker.com)
  - Access to Docker UNIX socket (`/var/run/docker.sock`) is required by default

## Installation

To set up the environment for using Molecule, run the command below on the terminal:

```bash
python3 -m venv ./molecule/venv
source ./molecule/venv/bin/activate
pip3 install -r ./molecule/requirements.txt
```

## Scenarios

Currently these testing scenarios are available:

### `default`

Tests a standard FMD Server installation, against the container image published by upstream.

### `default-selfbuild`

Tests a standard FMD Server installation with self-building the container image.

This scenario is not part of every CI run. Self-building compiles FMD Server from the tag that `fmd_server_version` points at, so it only changes behavior when that version changes; CI runs it on branches whose `defaults/main.yml` bumps a version, and on demand via `workflow_dispatch`.

## What the scenarios check

Both scenarios share [`verify_tasks.yml`](./verify_tasks.yml), which performs a round-trip against the running instance rather than merely watching the systemd unit turn active. That distinction matters here: the unit is configured with `Restart=always`, and an FMD Server started with no configuration at all still answers `200` on `/` and reports its version on `/version`, so neither of those observations can tell a working installation from a broken one.

The shared verification:

- moves the in-container port off the 8080 that the image listens on by default, so that reaching FMD Server at all proves `fmd_server_container_http_port` arrived both at the process and at the published port mapping
- asserts that the running process reports the version `fmd_server_version` pins
- requires FMD Server to reject a registration made without a registration token — an FMD Server that never read the role's `config.yml` hands out accounts to anyone who asks
- registers a device, logs in as it, pushes locations and reads the newest one back
- confirms that reading a location without a valid access token is answered with `401`, and that logging in with the wrong password is answered with `403`
- pushes one more location than `fmd_server_config_maxsavedloc` permits and confirms the oldest one was pruned — the scenario sets a value that differs from FMD Server's own default of 500
- looks the pushed location up on disk, under the host path that the container really bind-mounts its database from

On top of that, `default` asserts that the running image is the one pulled from the registry, and `default-selfbuild` asserts that it was built locally, from a source tree checked out at the pinned tag.

## Running

By default it is configured to run the scenarios on Ubuntu 26.04.

```bash
molecule test --scenario-name default
```

You can utilize other distributions by setting one to the `MOLECULE_DISTRO` environment variable:

```bash
# Ubuntu 24.04
MOLECULE_DISTRO=ubuntu2404 molecule test --scenario-name default

# Debian 13
MOLECULE_DISTRO=debian13 molecule test --scenario-name default

# Debian 12
MOLECULE_DISTRO=debian12 molecule test --scenario-name default
```
