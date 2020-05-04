FROM elixir:1.10.3-alpine AS app_builder

ENV MIX_ENV=prod \
    SECRET_KEY_BASE=secret-key-that-should-be-overriden-on-build

RUN apk add --update nodejs nodejs-npm \
    && mix local.hex --force \
    && mix local.rebar --force

COPY . /app
WORKDIR /app

RUN mix deps.get --only prod \
    && mix compile \
    && npm install --prefix ./assets \
    && npm run deploy --prefix ./assets \
    && mix phx.digest \
    && mix release

FROM alpine as app

EXPOSE 4000

RUN apk add --update openssl ncurses-libs \
    && rm -rf /var/cache/apk/*

RUN adduser -D -h /home/app app
WORKDIR /home/app
COPY --from=app_builder /app/_build/prod/rel/planningpoker .
RUN chown -R app: .
USER app

CMD ["bin/planningpoker", "start"]
