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
- Explain non-obvious database portability choices with a concise comment describing why the adapters need that representation, constraint, constant, or query. Keep comments focused on the adapter difference rather than restating the code.

## Temporal data

- Use `date` for civil calendar facts that must not change when a user changes time zone. `Entry::Date` and its descendants are date-only; do not add an optional time or reinterpret `entry_date` when a profile time zone changes.
- Use `datetime` only for exact instants. Store and compare those values in UTC; never store a local wall-clock time in a datetime without converting it.
- The profile's IANA `time_zone` is authoritative for user-facing “today.” Requests run in that zone; background work must explicitly use `User#local_date` or `Time.use_zone(user.time_zone)`.
- Browser values may help detect a time zone or keep a date control current, but the server derives authoritative user-local dates from the saved profile time zone.

## Product principles

- Adding a friend requires a name. Nothing else, ever. All other data is optional `Entry` records (typed blocks: phone, note, etc.).
- Don't add required fields or mandatory steps to any flow without explicit discussion.

## Code conventions

- Comments explain **why**, never what. No comments that restate the code. Prefer no comment over an obvious one.
- Test descriptions use natural domain language and name the subject explicitly. Avoid shorthand such as “before enable,” “stale state,” or other wording that requires reading the implementation to understand the behavior.
- Before implementing common formatting, parsing, localization, or infrastructure behavior, check whether Rails, an existing dependency, or established application code already provides it. Prefer a maintained existing capability when it fits the domain semantics; add custom code only when the existing options cannot express the required behavior cleanly.
- Configuration and tunable values use one predictable path: define the safe default in Rails application configuration under `config.x`, parse and validate an optional environment-variable override there, and have application code read only the resulting `config.x` value. Document every environment override in `.env.example`. Do not read `ENV` directly from models, queries, controllers, components, or other consumers.
- Do not hide magic numbers, strings, or other policy values in application logic. Give them a named configuration value or constant, and route user-facing strings through i18n.
- Views: hybrid. UI that is reusable, parameterized, or logic-bearing is a ViewComponent (Ruby class + template + test) with an explicit initializer interface. Plain ERB for layouts, page templates, and one-off page chrome. No shared partials — anything rendered from 2+ places becomes a component.
- Prefer componentizing any HTML that is expected to be reused, even within a single feature. Buttons, form controls, avatars, and similar primitives should be components by default; don't wait for a second usage to extract them.
- Before adding a JavaScript utility, search for existing code that solves the same browser concern and extract one shared implementation when appropriate.
- Never silence a caught error completely. Best-effort behavior may recover or continue when failure is safe, but it must report enough non-sensitive context through the appropriate logger or `console.error` so the problem remains diagnosable. Never include user content or personal data in diagnostic output.
- Before adding a platform or adapter-specific implementation, search for an existing reusable abstraction and extend it when appropriate.
- Tailwind is used as intended: utilities inline in markup; deduplicate by extracting components, never with `@apply`.
- Validations live in the model AND as DB constraints (`null: false`, FKs) — both, not either.
- Responsive design is mandatory: mobile-first (base styles target small screens, `sm:`/`md:`/`lg:` scale up), but layouts must feel natural on desktop too — no mobile-only or desktop-only UI.
- All UI strings go through i18n (`t(...)`, lazy lookup keys). Supported locales: English (`en`, default) and Spanish (`es`); every key must exist in both. No hardcoded UI strings in views, components, or code-triggered UI (flash messages, validation-facing attribute names, etc.).
- UI copy uses direct, conversational language at the user's level. Prefer concrete questions, verbs, and familiar phrases over technical terms or abstract nouns. Write each locale naturally; do not translate literally when idiomatic wording differs.
- Em dashes (—) are forbidden in UI copy in any locale; use a period, comma, or colon instead.
- Never commit without being asked. `db/schema.rb` is committed alongside migrations.
