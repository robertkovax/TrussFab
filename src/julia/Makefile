sysimage:
	julia --threads 8 create_sysimage.jl

lambda_docker_image:
	docker build . -t 744659377532.dkr.ecr.eu-central-1.amazonaws.com/trussfab
	docker push 744659377532.dkr.ecr.eu-central-1.amazonaws.com/trussfab