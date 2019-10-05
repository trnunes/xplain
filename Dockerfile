FROM jruby:9.1.17.0-jre
# RUN apk update && apk add build-base
RUN mkdir /xplain
WORKDIR /xplain
COPY Gemfile /xplain/Gemfile
COPY Gemfile.lock /xplain/Gemfile.lock
COPY . /xplain
RUN jgem install bundler -v 1.16.2
RUN bundle install --local --binstubs

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
