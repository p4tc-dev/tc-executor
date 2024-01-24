# TC Executor

This an executor for NIPA that runs tdc, the TC testing suite.
It can also be used to reliably test TC tests locally with new patches.

```
$ make help
TC Executor:
        all - Build the image and drop into a shell
        shell - Same as all
        local - Run a test and save the artifacts locally
        remote - Run a test and push the artifacts to remote storage
        clean - Remove image and docker cache
        install - Install and start the tc-executor service/timer
```

The timer will trigger the executor every 3 hours following NIPA's patch publishing schedule.

## Requirements for running host

```
	bash
	docker
	git
	systemd
	moreutils (sponge)
```

## Testing upstream changes locally

Changes to either Linux or iproute2 can be tested locally by copying patches to `kernel-patches` or `iproute2-patches`.

```
	cd linux/
	git format-patch HEAD~1
	cp my-change.patch ../tc-executor/kernel-patches/
	cd ..
	make local
```

The changes are tested on top of the most recent [`testing`](https://github.com/linux-netdev/testing).
Make sure your patches are rebased on top of [`net-next`](https://git.kernel.org/pub/scm/linux/kernel/git/netdev/net-next.git) for Linux and [`iproute2-next`](https://git.kernel.org/pub/scm/network/iproute2/iproute2-next.git) for iproute2.
