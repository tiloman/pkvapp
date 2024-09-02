FROM ruby:3.3.0-alpine AS base

ENV RAILS_ENV production
ENV SECRET_KEY_BASE asdoiasodyui23476asirfuhs876gsjdyf78698u32l
ENV RAILS_LOG_TO_STDOUT true
ENV PATH /app/bin:$PATH

RUN apk add --update \
  postgresql-dev \
  tzdata \
  nodejs \
  yarn \
  git \
  gcompat \
  imagemagick

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

USER app

WORKDIR /home/app

COPY --from=dependencies /usr/local/bundle/ /usr/local/bundle/

COPY --chown=app --from=dependencies /node_modules/ node_modules/

COPY --chown=app . ./

RUN RAILS_ENV=production SECRET_KEY_BASE=assets bundle exec rake assets:precompile

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
