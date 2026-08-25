#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Slavi Pantaleev
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Exercises bin/compute-next-tag.sh against throwaway git repositories.
#
# Usage: bin/test-compute-next-tag.sh
#
# Every scenario creates a repository in a temporary directory, gives it role
# files and a release history, and then replays a series of merges through the
# real script, tagging as it goes just like the autotag workflow does. This
# repository is never touched and no network access is needed.

set -euo pipefail

script_under_test="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/compute-next-tag.sh"

failures=0
workdir=''

cleanup() {
	cd /
	if [ -n "$workdir" ]; then
		rm -rf "$workdir"
		workdir=''
	fi
}

trap cleanup EXIT

# Starts a scenario with a repository at FMD Server 0.16.0 which has already
# seen two releases of it (v0.16.0-0 and v0.16.0-1), plus the neighbouring
# v0.14.x tags this repository really carries. Those must not be counted as
# releases of anything else.
#
# The defaults file deliberately carries the traps this role's real one has:
# the Renovate annotation, a commented-out example of the version variable, an
# image tag derived from the version, and a self-build revision that prefixes
# the version with a literal `v`. None of them may be picked up as the version.
scenario() {
	echo "$1"

	cleanup
	workdir="$(mktemp -d)"

	mkdir -p "$workdir/bin" "$workdir/defaults" "$workdir/meta" "$workdir/tasks" "$workdir/templates"
	cp "$script_under_test" "$workdir/bin/"
	cd "$workdir"

	git init -q -b main .
	git config user.email 'test@example.com'
	git config user.name 'Test'
	git config commit.gpgsign false

	cat > defaults/main.yml <<-'YAML'
		# fmd_server_version: 9.9.9

		# renovate: datasource=docker depName=registry.gitlab.com/fmd-foss/fmd-server versioning=semver
		fmd_server_version: 0.16.0

		fmd_server_container_image_tag: "{{ fmd_server_version }}"
		fmd_server_container_image_self_build_repo_version: "{{ 'v' + fmd_server_version if fmd_server_version != 'latest' else 'master' }}"
	YAML
	printf 'placeholder\n' > meta/main.yml
	printf 'placeholder\n' > tasks/main.yml
	printf 'placeholder\n' > templates/env.j2
	printf 'placeholder\n' > README.md

	git add -A
	git commit -qm 'Initial commit'

	local tag
	for tag in v0.14.0-0 v0.14.0-1 v0.14.1-0 v0.14.2-0 v0.16.0-0 v0.16.0-1; do
		git tag "$tag"
	done
}

# Applies a change, commits it, and tags whatever the script says it should be.
# Prints the tag, or nothing when the script decided against a release.
merge() {
	local change="$1" tag

	eval "$change"
	git add -A
	git commit -qm 'Merge'

	tag="$(bin/compute-next-tag.sh 2>/dev/null)"

	if [ -n "$tag" ]; then
		git tag "$tag"
	fi

	printf '%s' "$tag"
}

expect() {
	local description="$1" expected="$2" actual="$3"

	if [ "$actual" = "$expected" ]; then
		printf '  ok   | %s -> %s\n' "$description" "${actual:-no release}"
	else
		printf '  FAIL | %s -> expected %s, got %s\n' "$description" "${expected:-no release}" "${actual:-no release}"
		failures=$((failures + 1))
	fi
}

bump_version="sed -i 's|^fmd_server_version: 0.16.0|fmd_server_version: 0.17.0|' defaults/main.yml"
revert_version="sed -i 's|^fmd_server_version: 0.17.0|fmd_server_version: 0.16.0|' defaults/main.yml"
patch_version="sed -i 's|^fmd_server_version: 0.16.0|fmd_server_version: 0.16.1|' defaults/main.yml"
edit_task="printf 'a task\n' >> tasks/main.yml"
edit_template="printf 'a line\n' >> templates/env.j2"
edit_readme="printf 'documentation\n' >> README.md"
edit_script="printf '# a comment\n' >> bin/compute-next-tag.sh"

# The two merge orders below apply the same updates and must each end up with
# every update released exactly once, whichever order they arrive in.

scenario 'A version bump merged before other role changes'
expect 'version bump' v0.17.0-0 "$(merge "$bump_version")"
expect 'task edit'    v0.17.0-1 "$(merge "$edit_task")"
expect 'template'     v0.17.0-2 "$(merge "$edit_template")"

scenario 'A version bump merged after other role changes'
expect 'task edit'    v0.16.0-2 "$(merge "$edit_task")"
expect 'version bump' v0.17.0-0 "$(merge "$bump_version")"

# A patch bump is the update class Renovate is allowed to raise most often, and
# its tag must start a fresh counter rather than continue v0.16.0's.
scenario 'A patch bump of FMD Server'
expect 'patch bump' v0.16.1-0 "$(merge "$patch_version")"
expect 'task edit'  v0.16.1-1 "$(merge "$edit_task")"

# v0.14.1-0 and v0.14.2-0 exist in every scenario. Neither is a release of
# 0.14.0, so a repository sitting at 0.14.0 must continue from v0.14.0-1.
scenario 'Neighbouring patch versions of an older release'
merge "sed -i 's|^fmd_server_version: 0.16.0|fmd_server_version: 0.14.0|' defaults/main.yml" > /dev/null
expect 'a task' v0.14.0-3 "$(merge "$edit_task")"

scenario 'Commits that do not affect the role'
expect 'README'   ''         "$(merge "$edit_readme")"
expect 'a script' ''         "$(merge "$edit_script")"
expect 'a task'   v0.16.0-2  "$(merge "$edit_task")"

scenario 'Release numbers past 9'
for release_number in 2 3 4 5 6 7 8 9 10; do
	git tag "v0.16.0-$release_number"
done
expect 'a task' v0.16.0-11 "$(merge "$edit_task")"

scenario 'Reverting to an already released version'
merge "$bump_version" > /dev/null
# The role is now identical to what v0.16.0-1 already published, so there is
# nothing new to release.
expect 'a revert' ''         "$(merge "$revert_version")"

scenario 'Reverting to an already released version, with a change'
merge "$bump_version" > /dev/null
expect 'a revert' v0.16.0-2 "$(merge "$revert_version && $edit_task")"

if [ "$failures" -gt 0 ]; then
	echo >&2 "$failures scenario(s) behaved unexpectedly"
	exit 1
fi

echo 'All scenarios behaved as expected'
