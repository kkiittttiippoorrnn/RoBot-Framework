# Flow 03 — Payment rules

Checks the payment dialog's own rules, using only behavior seen on the real
POS (`tests/payment/payment_validation.robot`).

## POS-PAY-001 — Insufficient Cash Cannot Finish Sale

Pay half the total in cash: paid and balance are right. *Finish Sale* shows
the warning "Payment is not valid, please check." and the sale stays open
with the same balance. Cancelling the payment returns to the order screen
with the same total.

## POS-PAY-002 — Same Payment Method Cannot Be Added Twice

After a partial cash payment, choosing cash again shows "Payment type is
already exist in payment list, please check" and paid / balance do not
change. (Found while trying to write a split cash payment: the POS allows
one payment per method, so a split payment needs two different methods.)

Warnings are matched in Thai or English, so the test does not depend on the
POS language.
