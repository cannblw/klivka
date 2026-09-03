<h1 align="center">
  <br>
  <a href="./"><img src="./public/icon.svg" height="180" width="180" alt="Klivka icon"></a>
  <br>
  Klivka
  <br>
</h1>

<h4 align="center">An open-source personal CRM you can self-host with Docker.</h4>

<p align="center">
  <a href="#getting-started">Getting started</a> •
  <a href="#development">Development</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#database-support">Database support</a>
</p>

The core principle: **adding a person requires a name. Nothing else.** Klivka helps you keep a small, intentional record of family, friends, and other meaningful relationships. Add useful context as optional entries, then record interactions when you reach out.

Klivka is designed for private, personal use. Its progressive interface keeps the essentials close while giving each relationship room to grow over time.

## Stack

- Ruby on Rails 8.1 (Ruby 4.0)
- Hotwire (Turbo + Stimulus via importmap), Propshaft — no Node required
- Tailwind CSS (standalone binary) + ViewComponent
- SQLite by default; PostgreSQL also supported
- Solid Queue / Cache / Cable; deployable with Kamal

## Getting started

Run Klivka with Docker:

```bash
docker run -d --name klivka --restart unless-stopped -p 80:80 -v klivka_storage:/rails/storage ghcr.io/cannblw/klivka:development
```

Klivka is now available at http://localhost. The `klivka_storage` volume keeps your data when the container restarts or is replaced. Keep this volume and include it in your backups.

Or use Docker Compose:

```yaml
services:
  klivka:
    image: ghcr.io/cannblw/klivka:development
    ports:
      - "80:80"
    volumes:
      - klivka_storage:/rails/storage
    restart: unless-stopped

volumes:
  klivka_storage:
```

Save this as `compose.yml`, run `docker compose up -d`, then open http://localhost.

## Development

```bash
bin/setup
bin/rails db:seed # Optionally seed mock data
bin/dev
```

Then open http://localhost:3000.

In development, a default user with mock data is available after running `bin/rails db:seed` (optional):

- Email: `admin@example.com`
- Password: `admin`

Set `DEVELOPMENT_SEED_EMAIL_ADDRESS` and `DEVELOPMENT_SEED_PASSWORD` to use different credentials.

- `bin/dev` — run the app (Rails server + Tailwind watcher)
- `bin/rails test` — run the test suite (Minitest)
- `bin/rubocop` — lint
- `bin/ci` — full CI suite locally

## Configuration

Optional settings are read from environment variables; see [.env.example](.env.example). Copy it to `.env` for local overrides.

- `REQUIRE_EMAIL_CONFIRMATION` (default `false`): when `true`, new users must confirm their email address before signing in. Requires working SMTP settings in production.
- `DEVELOPMENT_SEED_EMAIL_ADDRESS` and `DEVELOPMENT_SEED_PASSWORD`: override the local mock-data account credentials.
- `APPLICATION_URL` (default `http://localhost:3000`): base URL used for links in reminder emails.
- `MAIL_FROM` (default `Klivka <from@example.com>`): sender used by application mailers.
- `REMINDER_MAIL_TRANSPORT` (default `rails`): reminder transport. `rails` uses the configured Action Mailer delivery method; `resend` uses the Resend API.
- `REMINDER_DELIVERY_RETRY_ATTEMPTS` (default `5`): maximum transport attempts for one reminder delivery job.
- `REMINDER_DELIVERY_CLAIM_TIMEOUT_MINUTES` (default `30`): how long an abandoned delivery claim remains active before it can be retried.
- `RESEND_API_KEY`: required when `REMINDER_MAIL_TRANSPORT=resend`. Provide it as a deployment secret.

Mail transports are registered in [`config/initializers/mail_transports.rb`](config/initializers/mail_transports.rb). Each adapter has its own file under [`app/services/mail_transports`](app/services/mail_transports) and implements `deliver(message:, delivery_id:)`. New mail features can use the same registry without coupling their delivery policy or templates to a provider.

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

[AGPL-3.0](LICENSE) for the source code. See the [trademark and brand policy](TRADEMARKS.md) for the Klivka name, logo, and visual identity.
