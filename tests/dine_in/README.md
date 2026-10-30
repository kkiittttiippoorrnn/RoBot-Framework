# Flow 06 — Dine-in Sale + Database Validation

Login → Dine In → zone → table → guest count → order → pay exact →
finalize (no receipt print) → Sales Lookup → validate the persisted sale.

## POS-DINEIN-001 — Dine-in Sale Is Saved To Database

`tests/dine_in/dine_in_sale_db.robot`. Same database checks as POS-E2E-001
(Total, Tendered = Total, Change = 0, item present).

Status: ported from the reference project; passing on the real POS since
2026-10-30. Known fragile point: the table tile is a positional `path:`
locator - see `resources/locators/dine_in_screen.resource`.
