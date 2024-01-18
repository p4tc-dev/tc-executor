all: image shell

image: clean
	docker build -t nipa-executor .

shell:
	docker run --rm -v $(realpath .)/tc-executor-storage:/storage -it nipa-executor ash

clean:
	docker image rmi -f nipa-executor
