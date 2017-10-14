FROM ruby:2.4.1
RUN apt-get update -qq && \
  apt-get install -y build-essential imagemagick
RUN mkdir /greatjobify
WORKDIR /greatjobify
ADD Gemfile* /greatjobify/
RUN bundle install
ADD . /greatjobify
EXPOSE 9292
CMD ["unicorn", "-p", "9292"]
