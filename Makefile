CURDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SYSTEMD := ${CURDIR}/systemd/
DEBUG ?= false

ifeq ($(DEBUG), true)
	FLAGS := -d
endif

all: shell

image:
	docker build --no-cache --build-arg DEBUG=${DEBUG} --build-arg UID=$(shell id -u) --build-arg GID=$(shell id -g) -t nipa-executor .

shell: image
	docker run --device=/dev/kvm:/dev/kvm --rm -v $(realpath .)/tc-executor-storage:/storage --entrypoint sh -it nipa-executor

local: 
	bash -x ${CURDIR}/run-executor.sh -l ${FLAGS}

remote: 
	bash -x ${CURDIR}/run-executor.sh ${FLAGS}

clean:
	docker image rmi -f nipa-executor
	docker builder prune -f

install:
	cpp -E -DINSTALL=${CURDIR} -DUSER=$(shell id -un) ${SYSTEMD}/tc-executor.service | sed -e 's/\/ //' -e 's/#.*//' > /tmp/tc-executor.service
	cpp -E -DINSTALL=${CURDIR} -DUSER=$(shell id -un) ${SYSTEMD}/tc-executor-debug.service | sed -e 's/\/ //' -e 's/#.*//' > /tmp/tc-executor-debug.service
	sudo cp /tmp/tc-executor.service /etc/systemd/system/
	sudo cp /tmp/tc-executor-debug.service /etc/systemd/system/
	sudo cp ${SYSTEMD}/tc-executor.timer /etc/systemd/system/
	sudo cp ${SYSTEMD}/tc-executor-debug.timer /etc/systemd/system/
	sudo systemctl daemon-reload
	sudo systemctl enable tc-executor.service tc-executor-debug.service
	sudo systemctl enable tc-executor.timer tc-executor-debug.timer
	sudo systemctl start tc-executor.timer tc-executor-debug.timer

uninstall:
	sudo systemctl disable tc-executor.service
	sudo systemctl disable tc-executor.timer
	sudo systemctl disable tc-executor-debug.service
	sudo systemctl disable tc-executor-debug.timer
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
