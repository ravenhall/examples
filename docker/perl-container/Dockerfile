# Dockerfile for building Perl Development container
# Author: Nathan Waddell <nathan.waddell@hilton.com>
# Date: 5/2/2017
FROM perl:latest

LABEL maintainer "nathan.e.waddell@gmail.com"

# got root?
USER root

# let's be up to date
RUN apt-get update -y && apt-get upgrade -y

# we need gcc and friends
RUN apt-get install -y build-essential openssl patch git git-email expat libxml2 memcached \
lynx curl wget emacs24                   

# enable parallel make
RUN echo 'export MAKEFLAGS="-j $(grep -c ^processor /proc/cpuinfo)"' >> ~/.bashrc

# enable parallel tests
RUN echo 'TEST_JOBS="$(grep -c ^processor /proc/cpuinfo)"' >> ~/.bashrc

# make login shells aware of bashrc so we can store everything in one spot
RUN echo '[ -f ~/.bashrc ] && source ~/.bashrc' >> ~/.bash_profile

# Clone plenv and configure
RUN [ "/bin/bash", "-cl", "git clone https://github.com/tokuhirom/plenv.git ~/.plenv" ]

# clone perl-build
RUN [ "/bin/bash", "-cl", "git clone https://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/" ]

# add plenv to PATH
RUN echo 'export PATH="~/.plenv/bin:$PATH"' >> ~/.bashrc

# init plenv
RUN echo 'eval "$(plenv init -)"' >> ~/.bashrc

# install Perl 5.26.1 (latest stable as of 1/27/2018)
RUN [ "/bin/bash", "-cl", "plenv install 5.26.1" ]

# Set 5.26.1 as global version of Perl
RUN [ "/bin/bash", "-cl", "plenv global 5.26.1" ]

# install cpanm
# a circular dependency between Test::More and Storable is currently causing cpanm install to fail
# so we force it for now. Remove PERL_CPANM_OPT='-fn' when it's fixed
RUN [ "/bin/bash", "-cl", "curl -L https://cpanmin.us | PERL_CPANM_OPT='-fn' perl - App::cpanminus" ]

# rehash plenv shims
RUN [ "/bin/bash", "-cl", "plenv rehash" ]

# Force install Test::More
RUN [ "/bin/bash", "-cl", "cpanm -fn Test::More" ]

# Force install Storable
RUN [ "/bin/bash", "-cl", "cpanm -fn Storable" ]

# Force install Path::Tiny
RUN [ "/bin/bash", "-cl", "cpanm -fn Path::Tiny" ]

# let's use Carton to manage our Perl apps
RUN [ "/bin/bash", "-cl", "cpanm -f Carton" ]

# copy application code in this directory to the container
#COPY . /usr/src/myapp
#WORKDIR /usr/src/myapp
#CMD [ "perl", "./your-daemon-or-script.pl" ]
