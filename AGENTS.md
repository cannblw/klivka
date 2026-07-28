# AGENTS.md

## Commands

- `bin/dev` — run the app (Rails server + Tailwind watcher)
- `bin/rails test` — run tests (Minitest + fixtures)
- `bin/rubocop` — lint (rubocop-rails-omakase)
- `bin/ci` — full CI suite locally

## Database rules (dual SQLite/Postgres support)

- Only portable column types: `string`, `text`, `integer`, `decimal`, `boolean`, `datetime`, `json`, `date`. Never `jsonb`, PG arrays, or `uuid` columns.
- No adapter-conditional migrations. `schema.rb` must load identically on both adapters.
- Avoid raw SQL; use ActiveRecord/Arel. If raw SQL is unavoidable and must differ by adapter, use `ApplicationRecord.adapter_sql(sqlite:, postgres:)` to branch cleanly.

## Product principles

- Adding a friend requires a name. Nothing else, ever. All other data is optional `Entry` records (typed blocks: phone, note, etc.).
- Don't add required fields or mandatory steps to any flow without explicit discussion.

## Code conventions

- Comments explain **why**, never what. No comments that restate the code. Prefer no comment over an obvious one.
- Views: hybrid. UI that is reusable, parameterized, or logic-bearing is a ViewComponent (Ruby class + template + test) with an explicit initializer interface. Plain ERB for layouts, page templates, and one-off page chrome. No shared partials — anything rendered from 2+ places becomes a component.
- Prefer componentizing any HTML that is expected to be reused, even within a single feature. Buttons, form controls, avatars, and similar primitives should be components by default; don't wait for a second usage to extract them.
- Tailwind is used as intended: utilities inline in markup; deduplicate by extracting components, never with `@apply`.
- Validations live in the model AND as DB constraints (`null: false`, FKs) — both, not either.
- Responsive design is mandatory: mobile-first (base styles target small screens, `sm:`/`md:`/`lg:` scale up), but layouts must feel natural on desktop too — no mobile-only or desktop-only UI.
- All UI strings go through i18n (`t(...)`, lazy lookup keys). Supported locales: English (`en`, default) and Spanish (`es`); every key must exist in both. No hardcoded UI strings in views, components, or code-triggered UI (flash messages, validation-facing attribute names, etc.).
- Em dashes (—) are forbidden in UI copy in any locale; use a period, comma, or colon instead.
- Never commit without being asked. `db/schema.rb` is committed alongside migrations.
