FROM jekyll/jekyll:4

WORKDIR /srv/jekyll
COPY Gemfile .
RUN bundle install

EXPOSE 4200
CMD ["jekyll", "serve", "--host", "0.0.0.0", "--port", "4200", "--source", "/docs"]
