install:
	npm install && make build_docker && make up

build_docker:
	(cd src/system_simulation && docker build -t trussfab .)

up:
	docker run --name trussfab_instance --rm -d -p 8080:8080 trussfab

down:
	docker stop trussfab_instance
