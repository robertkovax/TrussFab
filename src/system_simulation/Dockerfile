FROM ubuntu:19.04
RUN apt-get update

RUN apt-get install -y wget build-essential git ruby

# Install minimal OpenModelica Components
RUN for deb in deb deb-src; do echo "$deb http://build.openmodelica.org/apt disco stable"; done | tee /etc/apt/sources.list.d/openmodelica.list
RUN wget -q http://build.openmodelica.org/apt/openmodelica.asc -O- | apt-key add -
RUN apt-get update
RUN apt-get install -y omc omlib-modelica-3.2.2

# Ruby Project dependencies
RUN apt-get install -y ruby-dev ruby-sinatra libgsl0-dev
RUN gem install rb-gsl

COPY . /opt/code

WORKDIR /opt/code/server

# # Change the container to non-root "openmodelicauser" and set the env
# USER openmodelicausers
# ENV HOME /home/openmodelicausers
# ENV USER openmodelicausers
# WORKDIR $HOME

EXPOSE 8080

CMD ["ruby", "simulation_runner_server.rb"]
