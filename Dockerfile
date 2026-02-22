FROM ruby:3.3.0-alpine AS base

ENV RAILS_ENV=production
# Override at runtime (e.g. docker run -e SECRET_KEY_BASE=…)
ENV SECRET_KEY_BASE=replace-at-runtime
ENV RAILS_LOG_TO_STDOUT=true
ENV PATH=/app/bin:$PATH
ENV NODE_OPTIONS=--openssl-legacy-provider

RUN apk add --update \
  postgresql-dev \
  tzdata \
  nodejs \
  yarn \
  git \
  gcompat \
  imagemagick \
  ca-certificates \
  curl

FROM base AS dependencies

RUN apk add --update build-base

COPY Gemfile Gemfile.lock ./

RUN gem install bundler:2.4.12
RUN gem install nokogiri

RUN bundle config set without "development test" && \
  bundle install --jobs=3 --retry=3

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

FROM base

RUN adduser -D app

WORKDIR /home/app

COPY --from=dependencies /usr/local/bundle/ /usr/local/bundle/

COPY --from=dependencies /node_modules/ node_modules/

COPY . ./

RUN RAILS_ENV=production SECRET_KEY_BASE=precompile-dummy bundle exec rake assets:precompile

RUN chown -R app:app /home/app

USER app

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
