# Flow 03 — Payment

Expands payment validation once the basic cash sale (POS-SALE-001) is
stable: exact cash payment, cash with change, payment result validation,
and invalid/insufficient payment only if the real POS actually supports
that path.

Validates business results such as amount paid, total, change, payment
status, and sale completion — not invented payment rules.

Not started. Depends on Flow 02 and on inspecting the real payment screen's
behavior for edge cases.
