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

## Development

- `bin/dev` — run the app (Rails server + Tailwind watcher)
- `bin/rails test` — run the test suite (Minitest)
- `bin/rubocop` — lint
- `bin/ci` — full CI suite locally

## Database support

SQLite and PostgreSQL are both first-class. The schema and queries stick to a portable subset.

## License

[AGPL-3.0](LICENSE)
