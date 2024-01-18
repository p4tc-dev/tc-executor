#!/bin/bash

cleanup() {
	docker image rmi nipa-executor
}

trap cleanup EXIT SIGINT SIGTERM

CUR=$(dirname -- "$( readlink -f -- "$0"; )";)

if ! [ -d "$CUR/tc-executor-storage" ]; then
	cd "$CUR" && \
	git clone --depth=1 -b storage \
	https://github.com/tammela/tc-executor.git tc-executor-storage
fi

pushd "$CUR/tc-executor-storage"
	git checkout storage
	date -u > checkpoint
	mkdir -p artifacts
	mkdir -p results
popd

pushd "$CUR"
	docker image rmi nipa-executor
	docker build --no-cache -t nipa-executor .
	docker run --rm -v $(realpath .)/tc-executor-storage:/storage -it nipa-executor
popd

pushd "$CUR/tc-executor-storage"
	git remote set-url origin git@github.com:p4tc-dev/tc-executor.git
	git add .
	git commit -m "$(date)"
	git push
popd
