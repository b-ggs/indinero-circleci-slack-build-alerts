FROM ruby:2.3

MAINTAINER boggs <hello@boggs.xyz>

RUN apt-get update && apt-get -y install cron

RUN gem install bundler -v '1.15.1'

RUN mkdir /root/app
WORKDIR /root/app

COPY Gemfile .

RUN bundle install --without development test

COPY secrets.yml .
COPY app.rb .
COPY check_failed_builds.rb .
COPY entrypoint.sh .
RUN mkdir helpers
COPY helpers helpers
RUN mkdir config
COPY config config

EXPOSE 4567
RUN whenever -i
RUN chmod +x entrypoint.sh
CMD ./entrypoint.sh
