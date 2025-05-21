#!/bin/bash

set -e

cleanup() {
	docker image rmi nipa-executor || true
	docker builder prune -f || true
}

trap cleanup EXIT SIGINT SIGTERM

CUR=$(dirname -- "$( readlink -f -- "$0"; )";)
REMOTE=true
DEBUG=false
KERNEL_DIR="testing"
STORAGE="tc-executor-storage"
STORAGE_BRANCH="storage"

while getopts "ld" opt; do
	case "$opt" in
		l) REMOTE=false
			;;
		d) DEBUG=true
			;;
	esac
done

if [ "$DEBUG" = "true" ]; then
	STORAGE_BRANCH=storage-dbg
fi

# About 5-6 minutes window
for time in 30 60 120 240; do
	if ping -q -c1 github.com -W 2 > /dev/null; then
		INTERNET=y
		break
	else
		INTERNET=n
		sleep $time
	fi
done

if [ $REMOTE = true ]; then
	if ! [ -f "$CUR/token" ]; then
		echo "Missing GH token"
		exit 1
	fi
	if ! [ -d "$CUR/$STORAGE" ]; then
		cd "$CUR" && \
		git clone --depth=1 \
			--no-single-branch \
			-b "$STORAGE_BRANCH" \
			https://github.com/p4tc-dev/tc-executor.git \
			"$STORAGE"
	else
		if ! [ -d "$CUR/$STORAGE/.git" ]; then
			echo "Please remove $CUR/$STORAGE"
			exit 1
		fi
	fi

	pushd "$CUR/$STORAGE"
		git checkout -f "$STORAGE_BRANCH"
		date -u > checkpoint
		mkdir -p artifacts
		mkdir -p results
		if [ $INTERNET = "n" ]; then
			echo "$(date -u): No connection to the internet" >> ../failure
			exit 1
		fi
	popd
else
	STORAGE="$(date +%Y-%m-%d-%H%M%S)"
	mkdir "$STORAGE"
	pushd "$CUR/$STORAGE"
		mkdir -p artifacts
		mkdir -p results
		if [ $INTERNET = "n" ]; then
			echo "$(date -u): No connection to the internet" >> ../failure
			exit 1
		fi
	popd
fi

pushd "$CUR"
	bash make-testing.sh sync
	docker image rmi nipa-executor || true
	docker build --no-cache \
		--build-arg UID=$(id -u) \
		--build-arg GID=$(id -g) \
		--build-arg DEBUG=$DEBUG \
		-t nipa-executor .
	docker run --device=/dev/kvm \
		--rm \
		-v $(realpath .)/$STORAGE:/storage \
		-v $(realpath .)/$KERNEL_DIR:/nipa-data/kernel \
		-it \
		nipa-executor
	bash make-testing.sh clean
popd

if [ $REMOTE = true ]; then
	pushd "$CUR/$STORAGE"
		# Adjust artifacts browsing on dashboard
		RESULT="$(find results -name '*-*' -type f | sort -n -r -t'-' -k2 | awk 'NR==1')"

		if grep -q 'raw\.githubusercontent' $RESULT; then
			sed -i 's#raw\.githubusercontent\.com/p4tc-dev/tc-executor/#github.com/p4tc-dev/tc-executor/tree/#g' $RESULT

			# Copy container logs to storage
			ARTPATH="$CUR/$STORAGE/$(jq .link "$RESULT" | grep -o -P 'artifacts\/[0-9]+')"
			cp /tmp/tc-executor-output "$ARTPATH/executor.log"
		fi

		cp /tmp/tc-executor-output "$CUR/$STORAGE/last-executor.log"

		# Push changes
		git add .
		git commit -m "$(date)"
		git push https://$(cat $CUR/token)@github.com/p4tc-dev/tc-executor.git
	popd
fi
