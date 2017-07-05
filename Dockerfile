FROM ubuntu:16.04

MAINTAINER boggs <hello@boggs.xyz>

RUN apt-get update
RUN apt-get install -y --force-yes build-essential wget git zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev cron
RUN apt-get clean

RUN wget -P /root/src https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.1.tar.gz
WORKDIR /root/src
RUN tar xvf ruby-2.3.1.tar.gz
WORKDIR /root/src/ruby-2.3.1
RUN ./configure
RUN make install

# FROM ruby:2.3
#
# MAINTAINER boggs <hello@boggs.xyz>
#
# RUN apt-get update && apt-get -y install cron

RUN gem install bundler -v '1.15.1'

RUN mkdir /root/app
WORKDIR /root/app

COPY Gemfile .

RUN bundle install --without development test

COPY secrets.yml .
COPY check_builds.rb .
COPY check_previously_failing_important_branches.rb .
COPY entrypoint.sh .
RUN mkdir helpers
COPY helpers helpers
RUN mkdir config
COPY config config
RUN touch app.log

RUN whenever -i
RUN chmod +x entrypoint.sh
CMD ./entrypoint.sh
