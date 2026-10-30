# Keywords

Reusable, business-level Robot Framework keywords (`.resource` files), one
file per functional area (e.g. login, order, payment, receipt). Keywords
here wrap locators from `resources/locators/` — test cases never reference
raw locators directly.

`login.resource` is the first one, built from real inspection of the login
screen (see `docs/inspection-log.md`). Further files are added only as
each flow's screens are inspected and implemented.
