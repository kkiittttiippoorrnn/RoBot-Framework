# POS Automation

![CI](https://github.com/kkiittttiippoorrnn/RoBot-Framework/actions/workflows/ci.yml/badge.svg)

Robot Framework automation project for a Windows-based POS system, built as
a standalone Automation Tester portfolio piece. It demonstrates realistic
POS business-flow testing: reliable synchronization, reusable keywords,
clean separation between test scenarios / locators / data, meaningful UI
and database assertions, and no invented application behavior.

## Status

- **Flow 01 (Login)** and **Flow 02 (POS-SALE-001)** are built from real
  UI-Automation inspection and have been iterated against real runs on the
  live POS - every fix and what it was based on is in
  `docs/inspection-log.md`.
- **Flows 04-06** (Recall Receipt, sale + database check, dine-in sale +
  database check) were ported from an older automation of the same POS
  install. Their first run here (2026-10-30) needed a few fixes - the
  reference matched English captions, this POS runs in Thai - listed in
  `docs/inspection-log.md`.
- Latest full run on the real POS: **13 / 13 passed** (2026-10-30).
- **Flow 03** (payment edge cases) is not started.

## Scope

Six business flows, built one at a time and reusing keywords across them.
Full detail in `docs/flows.md`:

- **Flow 01** — Login (`POS-LOGIN-001`).
- **Flow 02** — Basic POS sale (cash, change, multi-item).
- **Flow 03** — Payment validation.
- **Flow 04** — Receipt/transaction recall and verification.
- **Flow 05** — End-to-end sale with SQL Server validation of persisted data.
- **Flow 06** — Dine-in (table) sale with SQL Server validation.

## Structure

```
pos-automation/
├── tests/                  # One folder per business flow; test cases only
│   ├── login/
│   ├── sales/
│   ├── payment/
│   ├── receipt/
│   ├── e2e/
│   └── dine_in/
├── resources/
│   ├── keywords/           # Reusable, business-level keywords (.resource)
│   ├── locators/           # UI Automation selectors, separate from keywords
│   └── variables/          # Environment-sourced config (no hard-coded secrets)
├── libraries/               # Custom Python library code, added only if genuinely needed
├── test-data/                # Static, non-secret test data
├── evidence/                  # Run output: logs, screenshots, captured IDs (git-ignored)
├── docs/                       # Architecture decisions, flow spec, inspection log
├── requirements.txt
├── .env.example
└── .gitignore
```

## Setup

```
python -m venv .venv
.venv\Scripts\activate        # Windows
pip install -r requirements-dev.txt   # requirements.txt + Robocop
copy .env.example .env        # then fill in POS_PIN, POS_APP_*, POS_DB_*
```

Robot Framework's Windows desktop automation (`RPA.Windows`) has to run on
Windows, since it drives the OS's UI Automation tree — this project is not
runnable purely from a Linux/macOS machine. Database checks also need
"ODBC Driver 17 for SQL Server".

## Running tests

Use `run.ps1` - it picks the project venv, fixes the console encoding Robot
needs, and writes each run to its own `evidence/<timestamp>/` folder.
UI tests drive the real POS on the desktop, so leave the mouse and keyboard
alone while they run.

```
.\run.ps1                               # everything
.\run.ps1 -Include smoke                # quick check: login + one sale
.\run.ps1 -Exclude pending-first-run    # only tests already run on the real POS
.\run.ps1 -Tests tests/sales            # one flow
.\run.ps1 -DryRun                       # keywords/arguments/imports only, no POS
.\run.ps1 -Tests tests/receipt -Variable RECALL_SALE_NUM:<SaleNum>   # re-run one bill
```

Each test launches its own POS and closes it afterwards, so tests don't
depend on execution order. When a test fails, a desktop screenshot named
after it is saved next to `log.html`.

### Tags

| Tag | Meaning |
|---|---|
| `smoke` | Minimal health check: POS-LOGIN-001, POS-SALE-001 |
| `flow-01` ... `flow-06` | One tag per business flow (`docs/flows.md`) |
| `login`, `sales`, `receipt`, `e2e`, `dine-in` | Functional area |
| `db` | Also validates data in SQL Server |
| `pending-first-run` | Written or ported, but not yet run on the real POS from this project |

### Static checks

```
robocop --argumentfile .robocop tests resources
```

CI (`.github/workflows/ci.yml`) runs Robocop and a Robot dry run on every
push. The UI tests themselves need the real POS and database, so they run
on the test machine only.

## Principles this project follows

- Real application behavior only — every locator and assertion comes from
  actually inspecting the running POS (`docs/inspection-log.md`), never
  guessed. Where something genuinely couldn't be confirmed yet, it's
  flagged as an open question there rather than assumed.
- Reusable keywords over copy-pasted click sequences; test cases stay
  readable at the business-flow level (see `tests/login/pos_login.robot`).
- Locators, test data, and scenario logic are kept in separate files.
- Deterministic waits on real application/element state (RPA.Windows's
  built-in locator polling, `Wait Until Keyword Succeeds`). The only fixed
  delay is a 0.5s settle before re-attaching after a state-changing click,
  added in response to a specific real-run failure (`docs/inspection-log.md`, Fix #7).
- Every action that matters has a meaningful assertion; database checks in
  Flows 04-06 complement the UI assertions, they don't replace them or just
  prove a row exists.
- No hard-coded credentials — config comes from environment variables (see
  `resources/variables/environment.py` and `.env.example`).
- Grow the architecture only when a real flow needs it (see
  `docs/architecture-decisions.md`); avoid pre-building abstractions.

## Not in scope

No AI agents, RPA workflow tooling beyond the Windows UI library itself, or
unrelated frameworks. This project is scoped to Robot Framework POS test
automation only.
