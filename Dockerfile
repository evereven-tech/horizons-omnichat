FROM ruby:3-slim

WORKDIR /site
RUN apt-get update && apt-get install -y build-essential git
COPY Gemfile* ./
RUN bundle install
EXPOSE 4200

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4200", "--destination", "/site/dist"]
