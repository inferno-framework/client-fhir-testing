FROM ruby:2.7.3

WORKDIR /var/www/proxy

### Install dependencies

COPY Gemfile* /var/www/proxy/
RUN gem install bundler
# Throw an error if Gemfile & Gemfile.lock are out of sync
RUN bundle config --global frozen 1
RUN bundle install

### Install client-fhir-testing
COPY . /var/www/proxy/

EXPOSE 9292

RUN chmod -R 0755 /var/www/proxy/

CMD ["bundle", "exec", "ruby", "./start-proxy.rb"]
