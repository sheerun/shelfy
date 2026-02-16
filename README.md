# Shelfy Library [![CI](https://github.com/sheerun/shelfy/actions/workflows/ci.yml/badge.svg)](https://github.com/sheerun/shelfy/actions/workflows/ci.yml)

API for a library management system (recruitment task solution)

## Development

To test development stack, simply run:

```sh
docker compose up
```

To edit and debug application, issue "Reopen in Container" command in VS Code. LSP, and debugging for tests should work out of the box for tests.

To rebuild container, including "bundle install", issue "Rebuild Container" VS Code command.

The tests can be executed by running:

```sh
bin/rspec
```

Continuous Integration scripts can be run as:

```sh
bin/ci rails    # run rails tests
bin/ci lint     # run lint checks
bin/ci security # run security checks
bin/ci          # run all checks above
```



## Design decisions

Where the specification lacked detail, reasonable assumptions were made to keep the solution self-contained and easy to evaluate, without unnecessary back and forth that would normally occur to develop such an app. The notes below explain important implementation choices and trade-offs.

### Project initialization

The project was initialized with the following options for `rails new`:

- `-B` to skip bundle install
- `-d postgresql` to use Postgres for reliability and scalability
- `--api` for a lightweight API-focused Rails stack
- `--minimal` to reduce boilerplate and unnecessary dependencies
- `--devcontainer` to provide containerized development environment
- `--skip-test` as we will use rspec for testing
- `--no-skip-action-mailer` to include Action Mailer for email functionality
- `--no-skip-brakeman` to enable security scanning
- `--no-skip-bundler-audit` to audit gem vulnerabilities
- `--no-skip-ci` to include CI configuration
- `--no-skip-docker` to include Docker setup
- `--no-skip-dev-gems` to include development gems
- `--no-skip-solid` to include Solid Stack components

It implied following flags:

- `--skip-active-storage` this API app doesn't require file uploads or storage
- `--skip-action-mailbox` email processing isn't needed for a library management API
- `--skip-action-text` rich text editing isn't required for this API-focused app
- `--skip-javascript` no frontend JavaScript is needed in this API-only Rails app
- `--skip-hotwire` Hotwire is for interactive web UIs, not applicable to an API
- `--skip-action-cable` real-time WebSocket features aren't needed for this app
- `--skip-bootsnap` it's skipped via --minimal, and we don't need faster boot times in a simple API
- `--skip-jbuilder` JSON rendering can be handled directly without Jbuilder templates
- `--skip-kamal` deployment tooling isn't necessary for this recruitment task solution
- `--skip-rubocop` we'll use standardrb for code formatting instead
- `--skip-system-test` system tests aren't relevant for an API without a web interface
- `--skip-thruster` asset serving isn't needed in this API app

### Code formatting

[Standardrb](https://github.com/standardrb/standard) is used for formatting and linting. It is known for its sensible defaults, ensuring consistent code style across the project. It automatically formats code on commit via a pre-commit hook to avoid unnecessary CI fails.

### Testing

RSpec is the chosen testing framework for this project for its behavior-driven syntax.

### Application architecture (Commands / Queries)

Business logic is implemented as small, explicit use-cases rather than being spread across controllers and ActiveRecord models. Commands (writes) and Queries (reads) live under `app/commands/library` and `app/queries/library` and share the same `#execute` API.

Each use-case returns a `Library::Result` that carries `status`, `data`, and `errors`, so controllers stay thin and response shaping is consistent. This also keeps validation and error translation close to the use-case, without relying on exceptions for expected user mistakes.

Serialization is handled via Blueprinter blueprints (`app/serializers/library`) to keep response shapes stable and to make eager-loading decisions explicit inside queries (avoid accidental N+1s).

### Data model choices

All primary keys use UUIDv7 (PostgreSQL 18 supports it natively) to keep identifiers globally unique and roughly time-ordered, which works well for distributed systems and avoids exposing sequential IDs.

Models are intentionally kept “boring”: schema, associations, and simple invariants only. Use-case specific rules (like whether a reminder should be sent) are enforced by commands/jobs.

### Background jobs (Solid Queue)

The app uses Solid Queue for background job processing to keep infrastructure minimal while still supporting scheduled work. Jobs are designed to be idempotent and safe to retry.

### E-mail reminders for due books

When a book is borrowed, two reminder records are created: a 3-day warning and a due-date alert. Each reminder is scheduled via Solid Queue using `wait_until` so delivery happens on the intended day without polling.

Reminder sending is guarded by a “send-once” approach implemented as a command run by the job: the reminder row is locked, the command exits if `sent_at` is already set, and it also skips sending if the borrow was already returned. The mail delivery and `sent_at` update happen inside the same DB transaction to avoid duplicates under concurrency/retries.

The e-mail content is generated from the `book_borrow` association (book title, serial number, due date) so messages reflect the actual borrow state and remain correct even if job execution is delayed.

### API Documentation

The API is accessible at `/` which redirects to the documentation.

The API documentation is generated using [rswag](https://github.com/rswag/rswag) from api specifications at `spec/requests` with [Scalar](https://scalar.com/) dashboard at `/docs` api endpoint. To re-generate dashboard one can use `script/docs` command.

## Health Endpoints

The application provides health check endpoints for monitoring and deployment:

- `GET /health/live` - Liveness probe (returns `{"status": "ok"}`)
- `GET /health/ready` - Readiness probe (returns `{"status": "ok", "uptime": 123.4, "checks": {"database": "ok"}}`)

These endpoints are suitable for Kubernetes liveness and readiness probes.


