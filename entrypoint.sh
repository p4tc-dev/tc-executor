#!/bin/bash

if [ "$(cat /debug-mode)" = "true" ]; then
	echo "=== >>> DEBUG KERNEL <<< ==="
	timeout 10m ./nipa/contest/remote/vmksft-p.py /tmp/tdc-debug.config
else
	timeout 10m ./nipa/contest/remote/vmksft-p.py /tmp/tdc.config
fi

chown -R $A_UID:$A_GID /storage 
