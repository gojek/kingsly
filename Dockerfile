FROM ruby:2.3.3

RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list

RUN apt-get update \
    && apt-get install \
    build-essential \
    libpq-dev \
    nodejs -y

ADD . /usr/src/app
WORKDIR /usr/src/app
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

RUN bundle install
RUN bundle exec rake assets:precompile --trace
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["rails", "s", "-p", "8080", "-b", "0.0.0.0"]
