# AWS provided base image (Amazon Linux 2)
# It includes Lambda Runtime Emulator for testing locally.
FROM public.ecr.aws/lambda/provided:al2

# Download and install Julia
WORKDIR /usr/local
RUN yum install -y tar gzip bzip2 \
    && curl -LO https://julialang-s3.julialang.org/bin/linux/x64/1.5/julia-1.5.3-linux-x86_64.tar.gz \
    && tar xf julia-1.5.3-linux-x86_64.tar.gz \
    && rm julia-1.5.3-linux-x86_64.tar.gz \
    && ln -s julia-1.5.3 julia

# Install application
WORKDIR /var/task
COPY . .

# Downloading artifacts by running the image once
RUN /usr/local/julia/bin/julia -q -Jsysimage -e "println(\"ok\")"

# That's because /var/task is a read-only path during runtime.
ENV JULIA_DEPOT_PATH /tmp/.julia:/var/task/.julia

# Install bootstrap script
WORKDIR /var/runtime
COPY bootstrap .

CMD [ "yo" ]