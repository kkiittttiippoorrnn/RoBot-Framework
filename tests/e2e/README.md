# Flow 05 — End-to-End Sale + Database Validation

Login → create order → add item → payment → complete sale → capture
SaleNum from Sale Lookup → query SQL Server → validate the persisted sale.

## POS-E2E-001 — Cash Sale Is Saved To Database

`tests/e2e/pos_sale_db.robot`. The UI steps are POS-SALE-001's confirmed
flow, unchanged. After the sale the database must show:

- `Total` equal to what the screen charged,
- `Tendered` = `Total` and `Change` = 0 (exact cash),
- a `SaleItem` line containing the item that was added.

Database checks complement the UI assertions; they don't replace them, and
they don't just prove a row exists. Queries are read-only
(`libraries/PosDatabase.py`); connection values come from `POS_DB_*` in
`.env`.

Status: ported from the reference project; passing on the real POS since
2026-10-30.

## POS-E2E-002 — Cash Sale With Change Is Saved To Database

Same flow paying the next round hundred: `Tendered` = the amount paid and
`Change` = `Tendered` - `Total`.

## POS-E2E-DD-01..03 — data-driven sale (`pos_sale_items_db.robot`)

One `Test Template` keyword, one row per menu item (`POS_SALE_ITEMS` in
`.env`). Each row is its own test with the POS-E2E-001 checks. The button
text must equal the item name saved on the bill: on this POS some buttons
show a different text from the item name (found while choosing the data),
so those cannot be checked by name in the database.
