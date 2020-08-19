FROM ubuntu:19.10
RUN apt-get update

RUN apt-get install -y wget build-essential git ruby cmake clang autoconf automake libtool g++ gfortran default-jdk pkg-config flex bison gettext libz-dev libcurl4-openssl-dev

RUN git clone https://github.com/OpenModelica/OpenModelica.git /opt/OpenModelica
WORKDIR /opt/OpenModelica/OMCompiler
RUN git checkout v1.16.0-dev.02
RUN git submodule update --init --recursive
RUN apt-get install  libexpat-dev libblas-dev liblapack-dev -y
RUN autoconf && ./configure --without-CORBA
RUN make -j 8

# Install minimal OpenModelica Components
# RUN for deb in deb deb-src; do echo "$deb http://build.openmodelica.org/apt eoan stable"; done | tee /etc/apt/sources.list.d/openmodelica.list
# RUN wget -q http://build.openmodelica.org/apt/openmodelica.asc -O- | apt-key add -
# RUN apt-get update
# RUN apt-get install -y omlib-modelica-3.2.2

# Ruby Project dependencies
RUN apt-get install -y ruby-dev ruby-sinatra libgsl0-dev
RUN gem install bundler

COPY . /opt/code

WORKDIR /opt/code/server
RUN bundle install

EXPOSE 8080

CMD ["ruby", "simulation_runner_server.rb"]
