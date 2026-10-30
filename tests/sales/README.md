# Flow 02 — Basic POS Sale

Login → prepare POS → create/select order → add one item → verify item →
verify price → verify total → open payment → select cash → enter exact
payment amount → complete payment → verify sale completed → verify
receipt/transaction result.

Planned test cases (implement and stabilize one at a time, in order):

- POS-SALE-001 — Basic Cash Sale
- POS-SALE-002 — Cash Payment With Change
- POS-SALE-003 — Multiple-Item Cash Sale

Status: POS-SALE-001 is implemented and iterated against real runs
(`docs/inspection-log.md`). POS-SALE-003 reuses the same keywords with a
second item from the same menu subcategory (confirmed in the reference
project) and passes on the real POS. POS-SALE-002 needs the change /
non-exact amount path of the payment dialog inspected first.
