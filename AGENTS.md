# AGENTS.md

## Commands

- `bin/dev` — run the app (Rails server + Tailwind watcher)
- `bin/rails test` — run tests (Minitest + fixtures)
- `bin/rails zeitwerk:check` — verify autoloading and constant naming
- `bin/rubocop` — lint (rubocop-rails-omakase)
- `bin/erb_lint` — lint ERB templates
- `bin/ci` — full CI suite locally

## Database rules (dual SQLite/Postgres support)

- Only portable column types: `string`, `text`, `integer`, `decimal`, `boolean`, `datetime`, `json`, `date`. Never `jsonb`, PG arrays, or `uuid` columns.
- Migrations must be adapter-independent and load the same `schema.rb` on both databases. Never rewrite a migration present on `main`; related branch-only migrations may be consolidated when one migration better expresses the final schema.
- Define schema-bound policy values inside migrations, never through mutable application constants. Keep matching application constants synchronized, and ask whether changing application policy also requires a constraint migration.
- Prefer straightforward last-write-wins behavior. Introduce optimistic or pessimistic locking only when a concrete concurrency risk justifies the added schema, UI, error-handling, and testing complexity, and discuss that tradeoff with the developer before implementing it.
- Avoid raw SQL; use ActiveRecord/Arel. If raw SQL is unavoidable and must differ by adapter, use `ApplicationRecord.adapter_sql(sqlite:, postgres:)` to branch cleanly.
- Comment only non-obvious portability choices, explaining why the adapters need the representation or query.

## Temporal data

- Use `date` for civil calendar facts. `Entry::Date` descendants remain date-only; never reinterpret `entry_date` after a time-zone change.
- Use `datetime` only for exact instants, stored and compared in UTC after converting local wall-clock input.
- The saved IANA profile `time_zone` determines user-facing “today.” Requests run in it; background work uses `User#local_date` or `Time.use_zone(user.time_zone)`. Browser values may suggest a zone or update a control, but are never authoritative.

## Product principles

- A person requires only a name. Everything else is an optional `Entry`; never add required fields or mandatory steps without explicit discussion.
- For every feature change, explicitly review:
  - People search, filters, and sorting. Add retrieval behavior only when it helps users find or organize people.
  - Versioned export/import. Durable user data updates both contracts and stability tests; operational or temporary data stays out. Declare emitted and accepted versions separately, and keep the current export importable.
  - Demo reset. `DemoSeeder#reset!` must clear applicable user-owned data before `DemoPersonaSeeder` recreates its expected state; mismatches must raise.
  - Account deletion. Every durable, temporary, scheduled, cached, or external resource needs a deletion path. Database records belong in the `AccountDeletion::Destroy` ownership graph with suitable dependencies, foreign keys, isolation tests, and atomic rollback coverage. Long-lived jobs stop safely when sources disappear; user-contacting work coordinates through `AccountOperationLock`.
- External resources that remain outside the account-deletion transaction must be discoverable from a non-sensitive account ID after the user row is gone. Add an idempotent callable to `config.x.account_deletion_cleanup_handlers`; each handler receives `account_id:` and must remove all resources and derivatives in its account namespace, succeed when they are already absent, and raise on failure so `AccountDeletion::ExternalCleanupJob` retries it. Keep user content and personal identifiers out of handler arguments, job metadata, exceptions, and logs. If a provider cannot locate resources from the account ID alone, extend the cleanup contract to capture the minimum non-sensitive locator before deletion and add failure and retry tests rather than relying on a model callback that can strand external data.

## Code conventions

- Comments explain **why**, never what; prefer none over an obvious comment.
- Test descriptions name the subject in natural domain language without implementation-dependent shorthand.
- Test localized UI through behavior and stable semantics in one representative locale. Never test exact translations, duplicate locale values in expectations, or switch locales only to verify wording; locale-completeness tests cover keys.
- Before adding custom formatting, parsing, localization, infrastructure, browser, or adapter-specific behavior, search Rails, dependencies, and established application abstractions. Extend a maintained fit before creating another implementation.
- Do not retain legacy compatibility code at runtime. Update callers, fixtures, seeds, and internal data instead of adding aliases, translation maps, fallbacks, or shims. If compatibility appears necessary, stop, explain its concrete need and cost, and recommend against it. Isolate required one-time conversion in a migration.
- Reuse `StringNormalizer` for single-line user text that needs Unicode canonicalization and whitespace cleanup. Compose domain-specific case or accent folding on top instead of duplicating the shared normalization.
- Configuration and tunable policy values use named constants or `config.x`. Define safe defaults and validated environment overrides in Rails configuration, document overrides in `.env.example`, and never read `ENV` from consumers.
- Rails signing keys secure sessions and transient tokens, not application secrets or durable-data encryption. Application secrets use explicit environment variables; persisted user data remains recoverable from documented backups without the signing key.
- Use ViewComponents with explicit initializers and tests for reusable, parameterized, logic-bearing, or expected-to-be-reused UI, including primitives. Keep layouts, page templates, and one-off chrome as plain ERB. Never add shared partials.
- Keep Stimulus controllers focused on one UI responsibility. Shared structural components must not inject undocumented controller targets or actions; declare behavior explicitly at each integration boundary.
- Cross-controller browser events must describe a specific completed intent and use an explicit payload contract. Do not use a generic global event when unrelated workflows could observe it, and do not signal successful completion before the relevant operation or navigation can proceed.
- JavaScript may toggle state and documented variant classes, but must not replace a component's complete class list. Keep structural and design-system classes owned by the rendering component.
- Keep Turbo enabled for forms and links unless a concrete fallback requirement justifies opting out. Preserve server behavior and test validation plus successful continuation without unintended document reloads; successful mutations redirect.
- Tests locate interactive UI through stable IDs or explicit component/controller hooks. Use ARIA attributes to assert accessibility semantics, not as behavioral selectors.
- Never silence a caught error completely. Best-effort behavior may recover or continue when failure is safe, but it must report enough non-sensitive context through the appropriate logger or `console.error` so the problem remains diagnosable. Never include user content or personal data in diagnostic output.
- Keep `Current` limited to request-global identity or context, currently `session` and its delegated `user`. Pass users and other dependencies explicitly to jobs, models, queries, and domain operations.
- Name and place objects by responsibility: domain-owned operations use an established domain namespace; side-effecting coordinators belong in service-style directories; pure transformations, policies, and value objects stay in the model/domain layer. Use `Seeder` for objects that populate or reset data and reserve `Data` for passive containers. Follow Zeitwerk paths and update all callers and tests after renames.
- Tailwind is used as intended: utilities inline in markup; deduplicate by extracting components, never with `@apply`.
- Validations live in the model AND as DB constraints (`null: false`, FKs) — both, not either.
- Responsive design is mandatory: mobile-first (base styles target small screens, `sm:`/`md:`/`lg:` scale up), but layouts must feel natural on desktop too — no mobile-only or desktop-only UI.
- Route every UI string through i18n, including code-triggered messages and validation-facing names. Every key exists in English and Spanish; never hardcode UI copy.
- Write direct, conversational, idiomatic copy with concrete verbs and familiar language. Use American English for identifiers, documentation, and English UI unless an external term requires otherwise. Write other locales naturally; never use em dashes in UI copy.
- Never commit without being asked. `db/schema.rb` is committed alongside migrations.

## Design system

### Typography

The application uses **DM Sans** (loaded from Google Fonts) as its typeface, configured as the default `--font-sans` in `app/assets/tailwind/application.css`. Do not add other typefaces without discussion.

Heading hierarchy:

- Page title (`<h1>`): `text-2xl font-bold`
- Section heading (`<h2>`): `text-lg font-semibold`
- Subsection heading or label: `text-sm font-medium text-stone-700 dark:text-stone-200`
- Muted label: `text-sm font-medium text-stone-500 dark:text-stone-400`
- Body text: `text-sm`
- Small or helper text: `text-xs`

### Color palette

- **Neutrals:** `stone-50` backgrounds, `stone-100` page background, `stone-200` borders, `stone-300` input borders, `stone-400`–`stone-500` muted text, `stone-600` secondary text, `stone-700` labels, `stone-800` dark cards, and `stone-900` dark pages/light body text.
- **Brand actions and links:** `brand-action`/`brand-action-hover` are primary controls with white text. `brand-link`/`brand-link-hover` are light-mode links. Use `brand-on-dark`/`brand-on-dark-hover` for links and accents on dark surfaces.
- **Brand UI states:** `brand-focus` is for focus rings, selected-control borders, checkbox accents, and meaningful status indicators. `brand-surface`/`brand-surface-strong`, `brand-border`, and `brand-ink` form light accent treatments; use `brand-dark-surface` with opacity for dark-mode accent backgrounds.
- **Brand artwork:** `brand-mark` and `brand-highlight` match the logo and are only for the logo or decorative artwork. Their contrast is insufficient for normal-sized white-text controls. Do not use raw `amber-*` utilities for brand styling.
- **Destructive:** the muted red scale is defined in the Tailwind theme. Use `red-600` for light-mode actions and errors, `red-500` for hover and alert backgrounds, `red-400` for dark-mode text, `red-300` for dark-mode text hover, `red-50` for light hover surfaces, and `red-900/20` for dark hover surfaces. Do not use undeclared red shades.
- **Success:** `emerald-600` success flashes.
- Do not introduce colors outside this palette; discuss any new semantic color first.

### Dark mode

Dark mode is driven by `data-theme="dark"` on the `<html>` element, not `prefers-color-scheme`. Every visual element must include `dark:` variants. The custom variant is defined in `app/assets/tailwind/application.css`.

### Icons

Use Material Icons via `<span class="material-icons" style="font-size: Npx" aria-hidden="true">icon_name</span>`. Always include `aria-hidden="true"` and ensure a text alternative exists nearby through a visible label, an `aria-label` on the parent control, or screen-reader-only text.

### Component catalog

Use these components instead of equivalent inline markup. Review this catalog whenever a reusable component changes; catalog application-wide patterns and leave feature-specific presentation uncatalogued.

| Components | Required use and contract |
|------------|---------------------------|
| `ButtonComponent` | Standard buttons; variants `:primary`, `:destructive`, `:ghost`; sizes `:sm`, `:md`. |
| `InputFieldComponent`, `TextareaFieldComponent`, `SelectFieldComponent`, `FileFieldComponent` | All supported form-builder fields. File fields receive translated labels and optional accepted-file guidance. |
| `FilterSearchFieldComponent`, `TogglePillGroupComponent` | Client-filtered search and small exclusive choices. Disabled pill guidance needs a stable tooltip ID. |
| `SectionComponent`, `CardComponent`, `SettingsPageComponent` | Bordered content sections, narrow authentication cards, and all settings pages. Use `heading_id:` when a section needs an accessible name and a declared `active:` settings destination. |
| `BackLinkComponent` | History-aware back actions; always provide `fallback_path:`. |
| `DialogComponent`, `ConfirmDialogComponent`, `PasswordConfirmDialogComponent` | All modal shells, destructive confirmations, and password reauthentication. Name dialogs with visible `labelledby:` where practical or `aria-label`; declare Stimulus behavior at the call site. |
| `InteractionFieldsComponent`, `QuickInteractionComponent` | All interaction fields and the quick-contact workflow. Keep submit and workflow-specific hidden fields in the owning form; quick interactions receive person, interaction, authoritative time zone, and open/return state. |
| `ContactEntryValueComponent`, `PersonContactActionsComponent`, `ContactReminderScheduleFieldsComponent` | Phone/email entry values, profile-level contact actions, and every editable contact-reminder schedule. Schedule fields receive form scope, cadence, saved date, local date, and unique ID prefix. |
| `PersonAvatarComponent`, `ContactMethodIconComponent` | Standard avatars and contact-method icons. Pass the person or stored icon library/name; invalid icons render nothing. |
| `MailerButtonComponent`, `FlashComponent`, `InlineNoticeComponent` | Primary mailer links, toast messages, and inline non-dismissible warnings. Mailer buttons receive translated labels and absolute URLs. |

Dialog triggers are buttons unless they have a genuine navigation fallback. Opening, closing, changing modes, failed submissions, and successful completion must leave focus in a logical place. ERB lint rejects ARIA menu semantics by default; any intentional menu requires a narrow inline exemption that explains why and system tests for its complete keyboard and focus behavior.

### Shared form styling

Use form field components for supported builder-backed fields. `FormStyling::INPUT_CLASSES` and `TEXTAREA_CLASSES` are for `_tag` helpers and specialized field-component bases.

### Spacing and responsive layout

- Page sections: `space-y-6`; form fields: `space-y-4` or compact `space-y-3`; section items: `space-y-3`.
- Heading/description to section content: `mt-4` via `SectionComponent`; page heading to first section: `mt-6`.
- Section cards fill their responsive parent. Use `max-w-xl` only where control width or line length would hurt readability.
