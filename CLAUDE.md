# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Phoenix 1.8 web application (Elixir) with LiveView, Tailwind CSS v4 + daisyUI, PostgreSQL, and esbuild. App name: `:resume`, module prefix: `Resume` / `ResumeWeb`.

## Commands

```bash
mix setup                    # Install deps, create DB, build assets (first-time setup)
mix phx.server               # Start dev server at localhost:4000
iex -S mix phx.server        # Start dev server with interactive Elixir shell
mix test                     # Run all tests (auto-creates/migrates test DB)
mix test test/path_test.exs  # Run a single test file
mix test --failed            # Re-run previously failed tests
mix format                   # Format all Elixir/HEEx files
mix precommit                # Full check: compile --warnings-as-errors, unused deps, format, test
mix ecto.migrate             # Run pending migrations
mix ecto.gen.migration name  # Generate a new migration
mix ecto.reset               # Drop, create, migrate, seed
```

**Always run `mix precommit` after completing changes.** It runs in the `:test` environment.

## Architecture

- **`lib/resume/`** — Business logic (contexts, schemas, repo). `Resume.Repo` is the Ecto repository (PostgreSQL).
- **`lib/resume_web/`** — Web layer. `ResumeWeb` module (`resume_web.ex`) defines macros for controllers, LiveViews, and components.
  - `endpoint.ex` — HTTP entry point, static files, sessions, LiveView socket at `/live`
  - `router.ex` — Routes with `:browser` pipeline. Scope is aliased to `ResumeWeb`, so routes use short module names.
  - `components/core_components.ex` — Shared UI components (`<.icon>`, `<.input>`, `<.button>`, `<.form>`, `<.table>`, etc.)
  - `components/layouts.ex` — Root and app layouts. Flash messages live here, not in individual views.
- **`assets/`** — Frontend: `js/app.js` (LiveView init), `css/app.css` (Tailwind v4 imports), `vendor/` (daisyui, heroicons, topbar)
- **`config/`** — Environment configs. `runtime.exs` reads `DATABASE_URL`, `SECRET_KEY_BASE`, `PHX_HOST`, `PORT` from env.
- **`priv/repo/migrations/`** — Database migrations
- **`test/support/`** — Test case modules: `ConnCase` (HTTP tests), `DataCase` (DB tests)

Dev routes available at `/dev/dashboard` and `/dev/mailbox`.

## Key Rules (see AGENTS.md for full details)

- **HTTP client**: Use `Req` (already included). Never use `:httpoison`, `:tesla`, or `:httpc`.
- **LiveView templates**: Must begin with `<Layouts.app flash={@flash}>`. Use `<.icon>` for Heroicons, `<.input>` for form fields.
- **Forms**: Always use `to_form/2` to create forms from changesets/params. Never pass changesets directly to templates.
- **Streams**: Use LiveView streams for all collections. Never use deprecated `phx-update="append"/"prepend"`.
- **CSS**: Tailwind v4 with `@import "tailwindcss" source(none)` syntax. No `tailwind.config.js`. Never use `@apply`.
- **JS**: Only `app.js` and `app.css` bundles. No inline `<script>` tags — use colocated hooks (`:type={Phoenix.LiveView.ColocatedHook}`, names prefixed with `.`).
- **Router scopes** auto-alias modules — don't add redundant aliases.
- **Ecto**: Schema fields use `:string` type even for text columns. Always preload associations accessed in templates. Use `Ecto.Changeset.get_field/2` to read changeset fields.
- **Billing gates**: Any feature that makes an LLM call must check `Resume.Billing.check_allowance(user, action)` first. Gate at the context level for `:generation` and `:adjustment`; gate at the LiveView level for `:fact_update` (because onboarding must stay free). Returns `{:error, :limit_reached, message}` when over the free limit.
- **Resume templates**: When adding a new resume template, register it in `lib/resume_web/resume_templates.ex` — the gallery page, show page, and PDF controller all read from this single registry.
