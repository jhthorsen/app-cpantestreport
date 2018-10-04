# git clone https://github.com/jhthorsen/app-cpantestreport
# cd app-cpantestreport
# docker build --no-cache -t cpantestreport .
# mkdir /some/dir/fordata
# docker run -d --restart always --name cpantestreport -p 5555:8080 cpantestreport
# http://localhost:5555

FROM alpine:3.5
MAINTAINER jhthorsen@cpan.org

RUN mkdir -p /app/data
RUN apk add -U perl perl-io-socket-ssl \
  && apk add -t builddeps build-base curl perl-dev wget \
  && curl -L https://github.com/jhthorsen/app-cpantestreport/archive/master.tar.gz | tar xvz \
  && curl -L https://cpanmin.us | perl - App::cpanminus \
  && cpanm -M https://cpan.metacpan.org --installdeps ./app-cpantestreport-master \
  && apk del builddeps curl \
  && rm -rf /root/.cpanm /var/cache/apk/*

ENV MOJO_MODE production
ENV MOJO_REDIS_CACHE_OFFLINE=1
EXPOSE 8080

ENTRYPOINT ["/app-cpantestreport-master/script/cpantestreport", "prefork", "-l", "http://*:8080"]
