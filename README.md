<h1 align="center">
  <br>
  <a href="./"><img src="./public/icon.svg" height="180" width="180" alt="Klivka icon"></a>
  <br>
  Klivka
  <br>
</h1>

<h4 align="center">A low-friction personal CRM to keep track of your friends.</h4>

<p align="center">
  <a href="#getting-started">Getting started</a> •
  <a href="#development">Development</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#database-support">Database support</a>
</p>

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

The account includes 100 deterministic sample friends with a realistic mix of empty profiles, phone numbers, emails, notes, birthdays, and combinations of those entries. Rebuild the sample data at any time with:

```bash
bin/rails db:seed
```

Seeding replaces every friend belonging to `admin@example.com`, so treat this account as disposable development data. The admin user is never created in production. Password length limits are only enforced outside development.

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

For most cases, plain SQLite is all you need. I won't judge you, my friends also fit in a SQLite database 🙂

If you prefer PostgreSQL, set these env vars:

```
DB_ADAPTER=postgresql
DB_HOST=localhost
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=klivka
```

## License

[AGPL-3.0](LICENSE)
