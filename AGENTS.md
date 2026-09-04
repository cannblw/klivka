# AGENTS.md

## Commands

- `bin/dev` — run the app (Rails server + Tailwind watcher)
- `bin/rails test` — run tests (Minitest + fixtures)
- `bin/rubocop` — lint (rubocop-rails-omakase)
- `bin/ci` — full CI suite locally

## Database rules (dual SQLite/Postgres support)

- Only portable column types: `string`, `text`, `integer`, `decimal`, `boolean`, `datetime`, `json`, `date`. Never `jsonb`, PG arrays, or `uuid` columns.
- No adapter-conditional migrations. `schema.rb` must load identically on both adapters.
- Treat migrations absent from `main` as unreleased. Consolidate related unreleased migrations when one coherent migration best represents the final schema, such as folding new columns into a branch-only create-table migration. Keep migrations separate when they cover meaningfully independent tables or concerns, and never rewrite a migration already present on `main`.
- Keep migrations deterministic by defining schema-bound policy values inside the migration instead of referencing mutable application constants. When the same policy also has a shared application constant, keep the values synchronized: ask the user whether an application-level change should include a new migration for the database constraint, and update the application constant in the same changeset when a migration changes the database value.
- Prefer straightforward last-write-wins behavior. Introduce optimistic or pessimistic locking only when a concrete concurrency risk justifies the added schema, UI, error-handling, and testing complexity, and discuss that tradeoff with the developer before implementing it.
- Avoid raw SQL; use ActiveRecord/Arel. If raw SQL is unavoidable and must differ by adapter, use `ApplicationRecord.adapter_sql(sqlite:, postgres:)` to branch cleanly.
- Explain non-obvious database portability choices with a concise comment describing why the adapters need that representation, constraint, constant, or query. Keep comments focused on the adapter difference rather than restating the code.

## Temporal data

- Use `date` for civil calendar facts that must not change when a user changes time zone. `Entry::Date` and its descendants are date-only; do not add an optional time or reinterpret `entry_date` when a profile time zone changes.
- Use `datetime` only for exact instants. Store and compare those values in UTC; never store a local wall-clock time in a datetime without converting it.
- The profile's IANA `time_zone` is authoritative for user-facing “today.” Requests run in that zone; background work must explicitly use `User#local_date` or `Time.use_zone(user.time_zone)`.
- Browser values may help detect a time zone or keep a date control current, but the server derives authoritative user-local dates from the saved profile time zone.

## Product principles

- Adding a person requires a name. Nothing else, ever. All other data is optional `Entry` records (typed blocks: phone, note, etc.).
- Don't add required fields or mandatory steps to any flow without explicit discussion.
- When adding or changing a product feature, revisit people search, filters, and sorting to decide whether the new information or state should be searchable, filterable, or sortable. Add retrieval behavior only when it helps users find or organize people; otherwise explicitly keep the feature out of search, filters, and sorting.
- When adding or changing a product feature, revisit the versioned account export to decide whether the new information or state should be included. Update the export contract, corresponding import schema, and their stability tests when it stores durable user data; otherwise explicitly keep operational or temporary data out of both. Keep emitted export versions and accepted import versions declared separately, and require the current export version to remain importable so schema changes are deliberate in both directions.
- When adding or changing a product feature, revisit the demo reset in `DemoSeedData#reset!` and `DemoPersonaSeedData` to decide whether new user-owned data needs to be cleared and re-seeded as part of the reset. The persona seeder must always find the state it expects; any mismatch raises at reset time and leaves the demo broken.
- When adding or changing a feature, revisit account deletion for every new durable, temporary, scheduled, cached, or externally stored resource. Account-owned database records must be reachable through the ownership graph used by `AccountDeletion::Destroy`, use appropriate `dependent:` behavior and foreign keys, and have tests proving that deletion removes only the owning account's data and rolls back atomically on failure. Jobs that may outlive their records must safely stop when the account or source is gone; work that can contact a user must coordinate through `AccountOperationLock` so it cannot begin after deletion completes.
- External resources that remain outside the account-deletion transaction must be discoverable from a non-sensitive account ID after the user row is gone. Add an idempotent callable to `config.x.account_deletion_cleanup_handlers`; each handler receives `account_id:` and must remove all resources and derivatives in its account namespace, succeed when they are already absent, and raise on failure so `AccountDeletion::ExternalCleanupJob` retries it. Keep user content and personal identifiers out of handler arguments, job metadata, exceptions, and logs. If a provider cannot locate resources from the account ID alone, extend the cleanup contract to capture the minimum non-sensitive locator before deletion and add failure and retry tests rather than relying on a model callback that can strand external data.

## Code conventions

- Comments explain **why**, never what. No comments that restate the code. Prefer no comment over an obvious one.
- Test descriptions use natural domain language and name the subject explicitly. Avoid shorthand such as “before enable,” “stale state,” or other wording that requires reading the implementation to understand the behavior.
- Do not add tests whose purpose is to assert exact translations or locale-specific wording. Never switch locales solely to verify translated text, and do not duplicate locale-file values in test expectations. Test localized UI through behavior and stable semantic structure in one representative locale; rely on locale completeness checks to ensure every supported locale has the required keys.
- Before implementing common formatting, parsing, localization, or infrastructure behavior, check whether Rails, an existing dependency, or established application code already provides it. Prefer a maintained existing capability when it fits the domain semantics; add custom code only when the existing options cannot express the required behavior cleanly.
- Prevent legacy compatibility code from remaining in the runtime codebase. Update callers, fixtures, seeds, and internal data to the current vocabulary and interfaces instead of adding aliases, translation maps, fallback branches, or other compatibility shims. The agent's default position is to remove legacy code and actively defend that choice. If retaining any legacy path appears necessary, stop and ask the developer first, explain the concrete reason and maintenance cost, and recommend against keeping it unless the compatibility requirement clearly outweighs that cost. Keep required one-time data migration logic isolated to the migration rather than carrying it into application code.
- Reuse `StringNormalizer` for single-line user text that needs Unicode canonicalization and whitespace cleanup. Compose domain-specific case or accent folding on top instead of duplicating the shared normalization.
- Configuration and tunable values use one predictable path: define the safe default in Rails application configuration under `config.x`, parse and validate an optional environment-variable override there, and have application code read only the resulting `config.x` value. Document every environment override in `.env.example`. Do not read `ENV` directly from models, queries, controllers, components, or other consumers.
- Treat the Rails signing key as infrastructure for sessions and transient tokens, not as storage for application secrets or as an encryption root for durable user data. Application secrets must use explicit environment variables, and persisted user data must remain recoverable from its documented data backup without requiring the signing key. Changing or losing the signing key may invalidate ephemeral authentication artifacts, but must never make account data unreadable.
- Do not hide magic numbers, strings, or other policy values in application logic. Give them a named configuration value or constant, and route user-facing strings through i18n.
- Views: hybrid. UI that is reusable, parameterized, or logic-bearing is a ViewComponent (Ruby class + template + test) with an explicit initializer interface. Plain ERB for layouts, page templates, and one-off page chrome. No shared partials — anything rendered from 2+ places becomes a component.
- Prefer componentizing any HTML that is expected to be reused, even within a single feature. Buttons, form controls, avatars, and similar primitives should be components by default; don't wait for a second usage to extract them.
- Before adding a JavaScript utility, search for existing code that solves the same browser concern and extract one shared implementation when appropriate.
- Keep Stimulus controllers focused on one UI responsibility. Shared structural components must not inject undocumented controller targets or actions; declare behavior explicitly at each integration boundary.
- Cross-controller browser events must describe a specific completed intent and use an explicit payload contract. Do not use a generic global event when unrelated workflows could observe it, and do not signal successful completion before the relevant operation or navigation can proceed.
- JavaScript may toggle state and documented variant classes, but must not replace a component's complete class list. Keep structural and design-system classes owned by the rendering component.
- Tests locate interactive UI through stable IDs or explicit component/controller hooks. Use ARIA attributes to assert accessibility semantics, not as behavioral selectors.
- Never silence a caught error completely. Best-effort behavior may recover or continue when failure is safe, but it must report enough non-sensitive context through the appropriate logger or `console.error` so the problem remains diagnosable. Never include user content or personal data in diagnostic output.
- Before adding a platform or adapter-specific implementation, search for an existing reusable abstraction and extend it when appropriate.
- Namespace application operations under an established domain when that domain clearly owns the work, such as scheduling, reconciling, claiming, building, or delivering its records. Do not create a namespace merely to shorten a class name; it must communicate real ownership.
- Name objects that populate or reset seed data with the `Seeder` suffix. Reserve `*Data` names for passive data containers.
- Keep pure transformations, domain policies, and value objects with the model/domain layer rather than presenting them as application services. Service-style directories are for operations that coordinate work or side effects.
- Follow Zeitwerk naming and file-path conventions for application and test code. When an internal class is renamed or moved, update every caller, test class, and test path to the current name instead of adding a compatibility alias.
- Tailwind is used as intended: utilities inline in markup; deduplicate by extracting components, never with `@apply`.
- Validations live in the model AND as DB constraints (`null: false`, FKs) — both, not either.
- Responsive design is mandatory: mobile-first (base styles target small screens, `sm:`/`md:`/`lg:` scale up), but layouts must feel natural on desktop too — no mobile-only or desktop-only UI.
- All UI strings go through i18n (`t(...)`, lazy lookup keys). Supported locales: English (`en`, default) and Spanish (`es`); every key must exist in both. No hardcoded UI strings in views, components, or code-triggered UI (flash messages, validation-facing attribute names, etc.).
- UI copy uses direct, conversational language at the user's level. Prefer concrete questions, verbs, and familiar phrases over technical terms or abstract nouns. Write each locale naturally; do not translate literally when idiomatic wording differs.
- Use American English for code identifiers, comments, documentation, and English UI copy unless an established external term requires different spelling. Write other locales naturally rather than applying English spelling conventions to them.
- Em dashes (—) are forbidden in UI copy in any locale; use a period, comma, or colon instead.
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

- **Neutrals** (stone): `stone-50` backgrounds, `stone-100` page background, `stone-200` borders, `stone-300` input borders, `stone-400` to `stone-500` muted text, `stone-600` secondary text, `stone-700` labels, `stone-800` dark-mode card background, `stone-900` dark-mode page background and light-mode body text.
- **Brand accent** (amber): `amber-600` primary buttons and active states, `amber-500` hover and focus, `amber-700` link text in light mode, `amber-400` link text in dark mode, `amber-50` active pill backgrounds, `amber-100` avatar backgrounds, `amber-900/30` dark-mode accent backgrounds.
- **Destructive** (red): `red-600` delete buttons and error text, `red-500` hover, `red-400` dark mode.
- **Success** (emerald): `emerald-600` success flash backgrounds.

Do not introduce new colors outside this palette. Discuss any new semantic color first.

### Dark mode

Dark mode is driven by `data-theme="dark"` on the `<html>` element, not `prefers-color-scheme`. Every visual element must include `dark:` variants. The custom variant is defined in `app/assets/tailwind/application.css`.

### Icons

Use Material Icons via `<span class="material-icons" style="font-size: Npx" aria-hidden="true">icon_name</span>`. Always include `aria-hidden="true"` and ensure a text alternative exists nearby through a visible label, an `aria-label` on the parent control, or screen-reader-only text.

### Component catalog

Use these shared components instead of writing equivalent markup inline. Do not duplicate the patterns they encapsulate.

| Component | Purpose | When to use |
|-----------|---------|-------------|
| `ButtonComponent` | `<button>` with variant and size styling | Every standard clickable button. Variants: `:primary`, `:destructive`, and `:ghost`. Sizes: `:sm` and `:md`. |
| `SectionComponent` | Responsive, full-width bordered card with an optional heading and description | Related content in a visual section, such as settings panels and upload forms. Use `heading_id:` when the section needs an accessible name. Do not hand-write the equivalent card container. |
| `InputFieldComponent` | Text, email, password, search, number, or date input with consistent styling and inline errors | Supported form-builder-backed input fields. |
| `TextareaFieldComponent` | Textarea with consistent styling and inline errors | Every form-builder-backed textarea. |
| `SelectFieldComponent` | Select with consistent styling and a chevron icon | Form-builder-backed select fields. |
| `FilterSearchFieldComponent` | Search input wired to client-side list filtering | Filterable lists that use the `filter-list` controller. |
| `TogglePillGroupComponent` | Radio buttons styled as horizontal pills | Small exclusive choice sets such as language and theme. Supply a stable tooltip ID when disabled guidance is shown. |
| `ConfirmDialogComponent` | Accessible confirmation dialog with confirm and cancel actions | Every destructive-action confirmation. Do not write inline confirmation dialogs. |
| `DialogComponent` | Structural native dialog shell with required accessible naming | Every modal dialog. Supply `labelledby:` for a visible heading when practical, or an explicit `aria-label`; declare all Stimulus behavior at the call site. |
| `PasswordConfirmDialogComponent` | Password reauthentication dialog attached to an existing form | Sensitive account operations that require the current password before submission. |
| `InteractionFieldsComponent` | Shared interaction date, contact-method, note, and validation fields | Every interaction form. Pass the active form builder, interaction, and context-appropriate note row count; keep submit controls and workflow-specific hidden fields in the owning form. |
| `ContactEntryValueComponent` | Linked phone or email value with copy action and optional label | Phone and email entry cards. Pass an `Entry::Phone` or `Entry::Email`; use `PersonContactActionsComponent` for profile-level contact actions. |
| `CardComponent` | Narrow centered card | Authentication screens such as sign in, registration, and password reset. |
| `FlashComponent` | Toast notification | Flash messages, normally rendered by the application layout. |
| `InlineNoticeComponent` | Inline warning banner | Non-dismissible warnings within page content. |

Dialog triggers are buttons unless they have a genuine navigation fallback. Opening, closing, changing modes, failed submissions, and successful completion must leave focus in a logical place. Do not use `role="menu"` unless the complete keyboard interaction pattern is implemented.

### Shared form styling

`FormStyling` (`app/components/form_styling.rb`) defines `INPUT_CLASSES` and `TEXTAREA_CLASSES`. Use these constants for `_tag` helpers such as `text_field_tag` and `text_area_tag` that cannot use field components. Specialized field components may also use them as their base styling.

For supported form-builder-backed fields, use `InputFieldComponent`, `TextareaFieldComponent`, or `SelectFieldComponent` instead of referencing the constants directly.

### Spacing and responsive layout

- Between page sections: `space-y-6`
- Between form fields: `space-y-4`, or `space-y-3` for compact forms
- Between items within a section: `space-y-3`
- Section content below a heading or description: `mt-4`, handled by `SectionComponent`
- Page heading to the first section: `mt-6`
- Let section cards fill their responsive parent. Constrain inner content with `max-w-xl` when wider controls or line lengths would hurt readability on desktop.
