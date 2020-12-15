FROM ubuntu:20.04
RUN apt-get update

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get install -y wget build-essential git ruby cmake clang autoconf automake libtool g++ gfortran default-jdk pkg-config flex bison gettext libz-dev libcurl4-openssl-dev

RUN git clone https://github.com/OpenModelica/OpenModelica.git /opt/OpenModelica
WORKDIR /opt/OpenModelica/OMCompiler
RUN git checkout v1.16.0-dev.02
RUN git submodule update --init --recursive
RUN apt-get install  libexpat-dev libblas-dev liblapack-dev -y
RUN autoconf && ./configure --without-CORBA
RUN make -j 8

RUN ln -s /opt/OpenModelica/OMCompiler/build/bin/omc /usr/local/bin/omc
RUN echo 'installPackage(Modelica, "3.2.3", exactMatch=true)' > installModelicaStandardLib.mos && omc installModelicaStandardLib.mos

# Ruby Project dependencies
RUN apt-get install -y ruby-dev ruby-sinatra libgsl0-dev
RUN gem install bundler
COPY ./server/Gemfile /opt/code/server/Gemfile
RUN bundle install --gemfile=/opt/code/server/Gemfile

COPY . /opt/code
WORKDIR /opt/code/server

EXPOSE 8080

CMD ["ruby", "simulation_runner_server.rb"]
