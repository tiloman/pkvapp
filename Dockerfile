FROM cimg/ruby:3.0.2-node

ENV RAILS_ENV production
ENV SECRET_KEY_BASE asdoiasodyui23476asirfuhs876gsjdyf78698u32l
ENV RAILS_LOG_TO_STDOUT true
ENV PATH /app/bin:$PATH

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg -o /root/yarn-pubkey.gpg && apt-key add /root/yarn-pubkey.gpg
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y nodejs yarn postgresql-client

RUN mkdir /app

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN gem install bundler

RUN bundle install
RUN yarn install

COPY . .

EXPOSE 3000

RUN RAILS_ENV=production bundle exec rake assets:precompile

CMD ["rails", "server", "-b", "0.0.0.0"]
