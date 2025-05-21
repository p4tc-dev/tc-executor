#!/bin/bash

# Yes, permissions are OK
git config --global --add safe.directory /nipa-data/kernel

if [ "$(cat /debug-mode)" = "true" ]; then
	echo "=== >>> DEBUG KERNEL <<< ==="
	timeout 10m ./nipa/contest/remote/vmksft-p.py /tmp/tdc-debug.config
else
	timeout 10m ./nipa/contest/remote/vmksft-p.py /tmp/tdc.config
fi

chown -R $A_UID:$A_GID /nipa-data/kernel/
chown -R $A_UID:$A_GID /storage 
