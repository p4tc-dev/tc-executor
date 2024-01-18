all: image shell

image:
	docker build -t nipa-executor .

shell:
	docker run --rm -it nipa-executor ash

clean:
	docker image rmi -f nipa-executor
