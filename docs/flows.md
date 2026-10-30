# Business Flows

Built and stabilized one at a time, in order. Flows 04-06 were ported from
an older, already-working automation of the same POS install and still
need their first run from this project (see `docs/inspection-log.md`,
"Flow 04-06 - ported from the reference project").

## Flow 01 — Login
See `tests/login/README.md`. POS-LOGIN-001 (Successful Login) is the only
test case for now.

## Flow 02 — Basic POS Sale
See `tests/sales/README.md`. POS-SALE-001 (exact cash), POS-SALE-002
(cash with change) and POS-SALE-003 (multi-item) pass on the real POS.

## Flow 03 — Payment
See `tests/payment/README.md`. Expands payment validation once Flow 02 is
stable.

## Flow 04 — Receipt / Transaction Verification
See `tests/receipt/README.md`. POS-RECEIPT-001 (Recall Receipt Matches
Database) - ported, passing on the real POS since 2026-10-30.

## Flow 05 — End-to-End Sale + Database Validation
See `tests/e2e/README.md`. POS-E2E-001 (exact cash), POS-E2E-002 (cash with
change) and the data-driven POS-E2E-DD-01..03 pass on the real POS. SQL Server via `pyodbc` (`libraries/PosDatabase.py`).

## Flow 06 — Dine-in Sale + Database Validation
See `tests/dine_in/README.md`. POS-DINEIN-001 (Dine-in Sale Is Saved To
Database) - ported, passing on the real POS since 2026-10-30.

## Automation principles

Business-level test cases, reusable keywords for common POS operations,
deterministic waits on real application/control state (RPA.Windows's
built-in timeout/retry on locator keywords — no arbitrary sleeps), stable
`id:` selectors over coordinates, independent tests, test data kept out of
test logic, no hard-coded secrets, and evidence captured on failure. Full
detail in `README.md`.

## Build order

1. Project + environment scaffold.
2. Inspect the application (screens, controls, identifiers) before each flow.
3. Only the reusable foundation the current flow actually needs.
4. Implement → run on the real POS → validate → stabilize → move on.
5. Refactor only where real duplication/maintainability problems show up.
