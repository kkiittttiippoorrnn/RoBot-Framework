# Flow 04 — Receipt / Transaction Verification

Recall a finalized sale from the main menu's Recall Receipt screen and
verify SubTotal, Discount, Tax and Total against the `Sale` row in SQL
Server.

## POS-RECEIPT-001 — Recall Receipt Matches Database

`tests/receipt/recall_receipt.robot`. Picks a random finalized SaleNum from
the database → Launch And Login To POS → Open Recall Receipt → Recall Sale →
waits until the recalled Total equals the database Total (bill loaded),
then compares the other three amounts.

Status: ported from the reference project (see `docs/inspection-log.md`,
"Flow 04-06 - ported from the reference project"); passing on the real
POS since 2026-10-30. The amount fields use positional `path:` locators.
