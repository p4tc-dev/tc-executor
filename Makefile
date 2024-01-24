CURDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

all: shell

image:
	docker build --no-cache --build-arg UID=$(shell id -u) --build-arg GID=$(shell id -g) -t nipa-executor .

shell: image
	docker run --device=/dev/kvm:/dev/kvm --rm -v $(realpath .)/tc-executor-storage:/storage --entrypoint ash -it nipa-executor

local: 
	bash ${CURDIR}/run-executor.sh -l

remote: 
	bash ${CURDIR}/run-executor.sh

clean:
	docker image rmi -f nipa-executor
	docker builder prune -f

install:
	cpp -E -DINSTALL=${CURDIR} -DUSER=$(shell id -un) tc-executor.service | sed -e 's/\/ //' -e 's/#.*//' > /tmp/tc-executor.service
	sudo cp /tmp/tc-executor.service /etc/systemd/system/
	sudo cp ${CURDIR}/tc-executor.timer /etc/systemd/system/
	sudo systemctl daemon-reload
	sudo systemctl enable tc-executor.service
	sudo systemctl enable tc-executor.timer
	sudo systemctl start tc-executor.timer

uninstall:
	sudo systemctl disable tc-executor.service
	sudo systemctl disable tc-executor.timer
	sudo rm -v /etc/systemd/system/tc-executor.*

help:
	@echo "TC Executor:"
	@echo  "\tall - Build the image and drop into a shell"
	@echo  "\tshell - Same as all"
	@echo  "\tlocal - Run a test and save the artifacts locally"
	@echo  "\tremote - Run a test and push the artifacts to remote storage"
	@echo  "\tclean - Remove image and docker cache"
	@echo  "\tinstall - Install and start the tc-executor systemd service/timer"
	@echo  "\tuninstall - Remove systemd files"
