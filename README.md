# Friend CRM

A low-friction personal CRM to keep track of your friends.

The core principle: **adding a friend requires a name. Nothing else.** Met someone today and know nothing about them yet? Add their name, done. Everything else is an optional entry you attach to their profile whenever you learn it.

## Stack

- Ruby on Rails 8.1 (Ruby 4.0)
- Hotwire (Turbo + Stimulus via importmap), Propshaft — no Node required
- Tailwind CSS (standalone binary) + ViewComponent
- SQLite by default; PostgreSQL also supported
- Solid Queue / Cache / Cable; deployable with Kamal

## Getting started

```bash
bin/setup
bin/dev
```

Then open http://localhost:3000.

In DEVELOPMENT, a default user is seeded so you can sign in right away:

- Email: `admin@example.com`
- Password: `admin`

This user is never created in production. Password length limits are only enforced outside development.

## Development

- `bin/dev` — run the app (Rails server + Tailwind watcher)
- `bin/rails test` — run the test suite (Minitest)
- `bin/rubocop` — lint
- `bin/ci` — full CI suite locally

## Configuration

Optional settings are read from environment variables; see [.env.example](.env.example). Copy it to `.env` for local overrides.

- `REQUIRE_EMAIL_CONFIRMATION` (default `false`): when `true`, new users must confirm their email address before signing in. Requires working SMTP settings in production.

## Database support

SQLite and PostgreSQL are both first-class.

## License

[AGPL-3.0](LICENSE)
