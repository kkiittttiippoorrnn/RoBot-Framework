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
