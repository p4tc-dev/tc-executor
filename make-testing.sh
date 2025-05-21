#!/bin/bash

set -e

CUR=$(dirname -- "$( readlink -f -- "$0"; )";)

if ! [ -d "$CUR/testing" ]; then
	git clone --no-single-branch --depth=1 https://github.com/linux-netdev/testing.git
fi

pushd $CUR/testing
	case "$1" in
		"sync")
			git fetch origin -p --depth=1
			;;
		"clean")
			git clean -dfx > /dev/null
			git restore .
			;;
		*)
			echo "wrong command: '$1'"
			exit 1
			;;
	esac
popd
