# Abile (PKVApp)

Rails app for organising private health insurance (PKV) records. German locale (`de`).

## Commands

```bash
# Dev
bin/rails server                # port 3000
./bin/webpack-dev-server        # separate terminal for JS

# Test
bundle exec rspec               # full suite
bundle exec rspec spec/models/  # scoped
bundle exec rubocop             # lint

# DB
bin/rails db:setup              # first time
bin/rails db:migrate            # after schema changes

# Background jobs
bin/delayed_job start           # or run inline in dev
```

## Architecture

```
app/
  models/         User -> Person -> Operation (core domain)
  services/       TodoistClient (Faraday HTTP, 10s timeout)
  interactors/    SyncTodoist, ExtractBill, BuildOperationProposal, ApplyAiRun, RevertAiRun (interactor gem pattern)
  jobs/           ExtractBillJob (ActiveJob -> Delayed Job)
  controllers/    Standard RESTful + Devise auth overrides
  javascript/     Stimulus controllers (Webpacker, not esbuild)
  views/          ERB + simple_form + ActionText
```

### Domain model

- **User** has_many :people, has_one :todoist_integration (Devise auth)
- **Person** has_many :operations, belongs_to :user (name, color, ratio)
- **Operation** belongs_to :person, has_one_attached :bill, has_many_attached :insurance_notices, has_rich_text :content

### AI bill extraction

`AiRun` is the audit record for every AI step: user uploads a bill (or reuses `Operation#bill`) -> `ExtractBillJob` calls `AiClient#extract` with the user's own Claude/Gemini key -> status `proposed` with per-field `{value, confidence, evidence}` in `output` -> user reviews on `/ai_runs/:id` -> `ApplyAiRun` creates/updates the Operation (`accepted`, `applied_changes` stores before/after, `RevertAiRun` undoes it).
Statuses: processing -> proposed -> accepted / rejected / failed / reverted. The AI never writes to Operation directly.

### Operation state machine (AASM)

```
editing (initial) --close--> closed
editing           --wait-->  waiting
waiting           --close--> closed
waiting           --open-->  editing
closed            --open-->  editing
closed            --wait-->  waiting
```

Auto-transitions in `update_status`: all paid flags set -> close; submitted flags set -> wait; otherwise -> open.

### Key routes

- `/dashboard` (authenticated root) - operations overview
- `/operations` - CRUD with filterrific + will_paginate (15/page)
- `/calendar` - fullcalendar view of operations
- `/webcal` - iCal feed (icalendar gem)
- `/delayed_job` - Delayed Job admin UI
- `/integrations`, `/todoist_integrations` - Todoist setup

## Stack choices

| Concern | Choice | Note |
|---------|--------|------|
| Jobs | Delayed Job | Not Sidekiq. Jobs stored in `delayed_jobs` table |
| Frontend | Webpacker + Stimulus | Not esbuild/importmaps |
| Filtering | filterrific (<= 5.2.3) | Pinned version, integrated into Operation model |
| Pagination | will_paginate-bootstrap4 | 15 per page |
| State machine | AASM | On Operation model |
| Files | Active Storage + S3 | Local disk in dev/test |
| Rich text | ActionText + Trix | On Operation.content |
| Forms | simple_form | With Bootstrap integration |
| HTTP | Faraday ~> 2.0 | For Todoist API |
| CSS | Bootstrap 5.2.3 | Via Webpacker, not gem |

## Gotchas

- **concurrent-ruby pinned** `< 1.3.5` in Gemfile for Rails 6.1 compatibility
- **mimemagic** pinned to a specific GitHub ref (licensing fix)
- **Delayed Job handler search** uses YAML string matching (`handler like`) in `Operation#find_reminder_job` -- fragile if serialization format changes
- **NODE_OPTIONS=--openssl-legacy-provider** required in Dockerfile for Webpack 4 + newer Node
- **Sentry DSN** is hardcoded in `config/initializers/sentry.rb` (not via ENV)
- **Validation side effects**: `insurance_submitted?` and `assistance_submitted?` on Operation use `throw :abort` -- they halt the save chain, not just add errors
- **AI extraction rules**: the LLM only extracts, Ruby computes (deadline from `payment_terms_days`, person matched from `patient_name` against the user's people, only unambiguous matches). `ApplyAiRun` requires `value` and `bill_deadline` because the operation pages crash without them. Users must consent once (`users.ai_consented_at`) because bills contain health data. Models are configurable via `AI_CLAUDE_MODEL` / `AI_GEMINI_MODEL`; the Gemini default `gemini-flash-latest` is an alias and unverified against a live key. Image downscaling needs ImageMagick (in the Dockerfile, not necessarily locally) and falls back to the original.
- **`User#create_person`** calls `Person.create` without a user, so it silently fails validation -- new users start without people
- **Request specs rendering the layout** must stub `javascript_pack_tag`/`stylesheet_pack_tag` (no webpack manifest in test)
- **Rails 5.2 defaults** still loaded (`config.load_defaults 5.2` in application.rb) despite running Rails 6.1
- **`search_query` scope** interpolates directly into LIKE -- safe only because `%` is the only special char handled

## Environment

Required for production:
- `SECRET_KEY_BASE`
- `PKVAPP_DATABASE_PASSWORD`
- `LOCKBOX_MASTER_KEY` (64 hex chars; encrypts users' AI API keys -- losing it makes them unreadable)
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `S3_BUCKET_NAME`

Optional:
- `RAILS_SERVE_STATIC_FILES` - enable in containerized deploys
- `RAILS_LOG_TO_STDOUT` - Docker logging
- `RAILS_MAX_THREADS` - DB pool size (default 5)

## Deployment

Docker (Alpine + Ruby 3.3.0) -> Dokku. `bin/docker-entrypoint` runs `db:migrate` before `rails server` starts (skip with `SKIP_MIGRATIONS=1`; one-off commands like `dokku run` do not migrate). The `postdeploy` hook in `app.json` is not reliable for this image-based deploy. CI pushes image via GitHub Actions to GitLab registry.
