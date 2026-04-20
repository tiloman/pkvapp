[![Build Status](https://ci.timolohmann.de/api/badges/tiloman/pkvapp/status.svg)](https://ci.timolohmann.de/tiloman/pkvapp)

# Abile

PKV-Organisation – a Ruby on Rails application for organising private health
insurance (Private Krankenversicherung) records, people and related
operations.

## Stack

- Ruby 3.3.0
- Rails 6.1
- PostgreSQL
- Webpacker + Bootstrap 5
- Devise for authentication
- Delayed Job for background jobs
- Sentry for error reporting
- Docker for deployment

## Getting started

### Requirements

- Ruby 3.3.0
- PostgreSQL
- Node.js and Yarn
- ImageMagick (for image processing)

### Setup

```bash
bundle install
yarn install
bin/rails db:setup
```

### Running locally

```bash
bin/rails server
./bin/webpack-dev-server
```

### Tests

```bash
bundle exec rspec
bundle exec rubocop
```

## Deployment

A production `Dockerfile` is included. The image runs `rails server` on port
3000 and expects `SECRET_KEY_BASE` and database credentials to be provided at
runtime.

```bash
docker build -t abile .
docker run -e SECRET_KEY_BASE=... -e DATABASE_URL=... -p 3000:3000 abile
```

Database migrations are run automatically on deploy via the `app.json` Dokku
`postdeploy` hook.

## Features

- User accounts (Devise)
- People and operations management
- iCal / Webcal feeds (`icalendar`)
- Todoist integration
- Filtering and pagination (`filterrific`, `will_paginate`)
- Background processing (`delayed_job`)
- S3-backed file storage (`aws-sdk-s3`)
