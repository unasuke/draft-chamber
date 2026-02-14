# draft-chamber

A Rails application that serves as an MCP (Model Context Protocol) server for IETF meeting materials.
It fetches data from the IETF Datatracker API and controls access via GitHub authentication.

## Tech Stack

- Ruby 4.0.1 / Rails 8.1.2
- SQLite3
- Propshaft (asset pipeline)
- esbuild + Hotwire (Turbo + Stimulus)
- Tailwind CSS
- Faraday (HTTP client for IETF Datatracker API)
- Solid Cache / Solid Queue / Solid Cable
- OmniAuth (GitHub authentication)
- Doorkeeper (OAuth 2.1 Authorization Server)
- Kamal (deployment)

## Setup

```bash
bin/setup
```

## Development

```bash
# Start the server (Rails + JS build)
bin/dev

# Run tests
bin/rails test

# Lint
bin/rubocop

# Security audit
bin/brakeman
bundle exec bundler-audit check
```
