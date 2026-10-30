# Flow 01 — Login

Every later flow depends on this. Reusable keyword: `Login To POS`
(`resources/keywords/login.resource`).

## POS-LOGIN-001 — Successful Login

Launch/attach to the POS → enter a valid PIN → submit → wait for the POS to
reach its main/ready state → verify login succeeded and no error is shown.

Status: implemented from real UI-Automation inspection of the login screen
(`docs/inspection-log.md`) and iterated against real runs; all eight
login tests pass on the live POS.
