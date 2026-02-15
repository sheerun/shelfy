# README

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

### API Documentation

The API documentation is generated using rswag and Scalar. To generate the OpenAPI specification and static documentation:

```sh
script/docs
```

This will:
- Generate `public/v1/docs/openapi.json` from the rswag tests
- Create an HTML documentation at `public/v1/docs/index.html` with the OpenAPI spec embedded using Scalar's API reference

The API is accessible at `/v1` which redirects to the documentation.

## Health Endpoints

The application provides health check endpoints for monitoring and deployment:

- `GET /v1/health/live` - Liveness probe (returns `{"status": "ok"}`)
- `GET /v1/health/ready` - Readiness probe (returns `{"status": "ok", "uptime": 123.4, "checks": {"database": "ok"}}`)

These endpoints are suitable for Kubernetes liveness and readiness probes.


