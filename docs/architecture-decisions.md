# Architecture Decisions

Short-form log of decisions that shape the project, made before real
application inspection where the decision doesn't depend on app-specific
behavior. Revisit any of these if inspection reveals a reason to.

## ADR-001: Windows UI automation library — RPA.Windows

**Status:** Accepted

**Context:** The target POS is a native Windows desktop application
(WinForms/WPF or similar), not a web app. Robot Framework has no built-in
support for Windows desktop UI; a dedicated library is required, and it has
to run on the Windows machine where the POS is installed.

**Options considered:**
- `RPA.Windows` (package `rpaframework-windows`) — pure Python, built on the
  `uiautomation`/`comtypes` stack, no separate .NET agent process to manage.
  Ships as a normal Robot Framework library (`Library    RPA.Windows`).
- `robotframework-flaui` — wraps the .NET FlaUI library; generally strong
  UI Automation coverage for WPF, but requires a .NET runtime and a
  separate driver process alongside the Python side, which is more moving
  parts to set up and explain in a portfolio repo.
- Raw `pywinauto` behind a custom Robot Framework library — more control,
  but means writing and maintaining a custom library layer before there is
  a demonstrated need for one.

**Decision:** Start with `RPA.Windows`. It's pip-installable on its own,
integrates directly as a Robot Framework library, and is well documented
for exactly this kind of desktop UI automation.

**Consequence:** All Windows UI keywords/locators target `RPA.Windows`'s
real selector syntax — verified against the installed package's source
(`RPA/core/windows/locators.py`), not assumed: `id:` / `automationid:`
(AutomationId), `name:` (Name), `class:` (ClassName), `control:` / `type:`
(ControlType), `subname:` (contains-match on Name), chained with ` > ` for
parent/child and space for AND. The POS app's AutomationIds are unique and
stable enough (confirmed via real UI-tree inspection, see
`inspection-log.md`) that plain `id:xxx` selectors are sufficient — no
brittle coordinates needed.

## ADR-002: Database library deferred, engine confirmed as SQL Server

**Status:** Accepted

**Context:** Flow 05 needs database validation. The engine is now confirmed
as SQL Server (pyodbc), but the schema and exact credentials aren't yet.

**Decision:** Don't add `robotframework-databaselibrary` + `pyodbc` to
`requirements.txt` until Flow 05 implementation actually starts and the
real schema has been inspected — even though the driver choice itself is
now settled, adding the dependency early with nothing to run it against
just adds noise.

## ADR-003: Launch the POS itself (attach remains available)

**Status:** Accepted

**Context:** The two original UI-tree exports used to inspect the login
screen were both captured from an already-running POS process, and no
executable path or launch procedure was available at the time, so `Login To
POS` originally only attached (`Control Window id:FrmMainMenu3`) rather than
launching. Real launch data has since become available: `pos_keywords.robot`
/ `pos_variables.robot`, files from a separately-maintained, already-working
automation project that targets this same POS (same executable name,
confirmed working `Start Process` + `Control Window` pattern, real
`WINDOW_TIMEOUT` value). See "POS launch" in `docs/inspection-log.md` for
the exact values and the one caveat on how confident we can be it's the same
POS install.

**Decision:** Add `Launch POS` (a plain `Start Process ${POS_APP_PATH}
cwd=${POS_APP_WORKDIR}`) and `Wait For And Attach To POS Window` (`Control
Window ${LOGIN.WINDOW} timeout=${POS_LAUNCH_WINDOW_TIMEOUT}`) as new
keywords that run *before* the existing, real-run-validated `Login To POS`
flow, rather than changing `Login To POS` itself — `Login To POS` (plain
attach, no launch) is unchanged and still available on its own.
`POS_APP_PATH` is derived from `POS_APP_WORKDIR` + `POS_APP_EXE_NAME` (via
`.env`, never hard-coded), matching how the referenced working project
builds the same path, rather than storing one pre-joined path.

A first real run of `POS-LOGIN-001` under the *original* attach-only
lifecycle failed for exactly the reason this ADR anticipated:
`WindowControlError: Could not locate window with locator: 'id:FrmMainMenu3'`
— no POS was running yet, so there was nothing to attach to. That failure is
itself real confirmation that this project's actual test environment does
not keep a POS running between runs, so `POS-LOGIN-001` was updated to call
`Launch And Login To POS` (launch, then reuse `Login To POS` and
`Main Menu Should Be Displayed For Logged In User` unchanged) instead of
`Login To POS` alone, and passed. `POS-LAUNCH-001`, added earlier to trial
the launch lifecycle separately, now calls the exact same keyword and is
fully redundant with `POS-LOGIN-001` — flagged for a decision on removal,
not yet deleted.

**Consequence:** The explicit `POS_LAUNCH_WINDOW_TIMEOUT` (60s, taken from
the referenced project's real `WINDOW_TIMEOUT`) is only used for the
post-launch wait — a fresh launch is expected to take longer to reach a
queryable window than an already-running instance does, which is why
`Login To POS`'s own `Attach To POS Window` (unchanged, no explicit timeout)
was left as-is rather than widening it for every caller. The login-screen
state right after a fresh launch has since been confirmed by a real launch
(see "Login screen signal after a fresh launch" in the inspection log) —
`Verify Login Screen Is Displayed` / `POS Login Panel Should Be In Visible
Slot` now assert on it instead of only logging.

## ADR-004: PIN entry via the on-screen keypad, not direct text injection

**Status:** Accepted, pending validation on a real run

**Context:** The login screen is PIN-based: a `txtPin` Edit control plus a
numeric keypad (`btn0`-`btn9`, `btnClear`, `btnDel`). `txtPin` supports UI
Automation's Value pattern, so a PIN could technically be written directly
with `Set Value` instead of clicking digits.

**Decision:** `Enter POS PIN` clicks the keypad buttons instead of writing
directly to `txtPin`. This matches how a real cashier uses a touchscreen
till, and avoids depending on whether the app's business logic (e.g.
enabling `Login` once enough digits are entered) actually reacts the same
way to a programmatic `Value` write as it does to real button presses —
something that can't be confirmed without inspecting the app's code.
