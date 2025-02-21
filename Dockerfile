FROM jekyll/jekyll:4.2.2

WORKDIR /site
EXPOSE 4200
CMD ["jekyll", "serve", "--host", "0.0.0.0", "--port", "4200", "--destination", "/dist"]
