FROM ruby:2.5.6

WORKDIR /var/www/inferno

### Install dependencies

COPY Gemfile* /var/www/inferno/
RUN gem install bundler
# Throw an error if Gemfile & Gemfile.lock are out of sync
RUN bundle config --global frozen 1
RUN bundle install

### Install client-fhir-testing
COPY . /var/www/inferno/

EXPOSE 9292

RUN chmod -R 0755 /var/www/inferno/

CMD ["bundle", "exec", "ruby", "./start-proxy.rb"]
