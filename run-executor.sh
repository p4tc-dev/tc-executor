#!/bin/bash

set -e

cleanup() {
	docker image rmi nipa-executor || true
	docker builder prune -f || true
}

trap cleanup EXIT SIGINT SIGTERM

CUR=$(dirname -- "$( readlink -f -- "$0"; )";)
REMOTE=true
STORAGE="tc-executor-storage"

while getopts "l" opt; do
	case "$opt" in
		l) REMOTE=false
			;;
	esac
done

if [ $REMOTE = true ]; then
	if ! [ -d "$CUR/$STORAGE" ]; then
		cd "$CUR" && \
		git clone --depth=1 \
			-b storage \
			https://github.com/tammela/tc-executor.git \
			"$STORAGE"
	fi

	pushd "$CUR/tc-executor-storage"
		git checkout storage
		date -u > checkpoint
		mkdir -p artifacts
		mkdir -p results
	popd
else
	STORAGE="$(date +%Y-%m-%d-%H%M%S)"
	mkdir "$STORAGE"
	pushd "$CUR/$STORAGE"
		mkdir -p artifacts
		mkdir -p results
	popd
fi

pushd "$CUR"
	docker image rmi nipa-executor || true
	docker build --no-cache -t nipa-executor .
	docker run --device=/dev/kvm \
		--rm \
		-v $(realpath .)/$STORAGE:/storage \
		nipa-executor
popd

if [ $REMOTE = true ]; then
	pushd "$CUR/tc-executor-storage"
		# Adjust artifacts browsing on dashboard
		RESULT="$(find results -name '*-*' -type f | sort -n -r | head -1)"
		ARTIFACTS="$(cat $RESULT | jq .link | sed s/raw\.githubusercontent/github/g -)"
		jq ".link = $ARTIFACTS" "$RESULT" | sponge "$RESULT"

		# Push changes
		git add .
		git commit -m "$(date)"
		#git push https://$(cat $CUR/token | tr -d'\n')@github.com/p4tc-dev/tc-executor.git
	popd
fi
