# Inspection Log

> Chronological lab notebook: every real run, what failed and why each
> fix was made. For an overview start with `README.md` and `docs/flows.md`.

Source of truth for what the real POS application actually does. Locators
and keywords are written from what's recorded here — never guessed.

## How to capture a screen

For each screen/dialog, the most useful things to share: a screenshot in
its normal state, and for each control interacted with, its **Name**,
**AutomationId**, and **ControlType** from a UI Automation inspector
(Accessibility Insights for Windows, Inspect.exe, or an exported full UI
tree as JSON). Also useful: what visibly changes after an action, and any
loading/transition state worth waiting on.

## Login screen — confirmed from `FullUiTree-1.json` / `FullUiTree-2.json`

Both are full UI-Automation tree exports of the same running window
(`automationId: FrmMainMenu3`, title "POS System", WinForms). Two captures
were provided; comparing them was itself informative (see "Reading the two
captures" below).

### Confirmed controls

| Purpose | AutomationId | ControlType | Notes |
|---|---|---|---|
| Login window | `FrmMainMenu3` | Window | Login is a panel inside this window, not a separate window |
| Login panel (container) | `pnlLogin` | Pane | |
| PIN prompt text | `lblPin` | Text | "Please input PIN code to log on." — confirms PIN-based login, not username/password |
| PIN field | `txtPin` | Edit | Supports UI Automation `Value` pattern, but see ADR-004 — keypad is used instead |
| Numeric keypad | `NumPad1` > `tbl` | Pane | Contains the digit buttons |
| Digit buttons | `btn0` .. `btn9` | Button | Invoke pattern |
| Clear PIN | `btnClear` | Button | |
| Delete last digit | `btnDel` | Button | |
| Submit login | `btnLogin` | Button | Name: "Login" |
| Language selector | `cbxLanguage` | ComboBox | Not needed for basic login; options include Thai/English/French/Lao/Vietnamese/Chinese/Arabic/Myanmar |
| Main menu panel (post-login) | `pnlMenu` | Pane | Contains Front End / Back End / Other radio buttons (`rdbFrontEnd`, `rdbBackEnd`, `rdbOther`) and their sub-menus |
| Front End menu entry point | `btnPOS` | Button | Likely the entry into the actual sale screen for Flow 02 |
| Recall receipt entry point | `btnRecallReceipt` | Button | Relevant later for Flow 04 |
| Log off | `btnLogout` | Button | In the footer (`pnlBottom`), Name "Log Off" |
| Current user label | `txtUserFullName` | Text | In the footer; showed "Administrator" in both captures — see open question below |

### Reading the two captures

The login panel (`pnlLogin`) and the settings panel (`pnlSetting`) appear to
share one "drawer" slot on the right edge of the window:

- In `FullUiTree-1.json`, `pnlLogin` is at `x=1412` (on-screen, in the
  drawer slot) while `pnlSetting` is at `x=1921` (parked, off the 1920px-wide
  window — effectively hidden).
- In `FullUiTree-2.json`, `pnlLogin` has moved to `x=1921` (parked/hidden)
  and `pnlSetting` is also parked at `x=1921`. Neither drawer occupies the
  visible slot, leaving the main menu (`pnlMenu`, unchanged at `x=1412` in
  both captures) as the unobstructed foreground content.

**Working interpretation:** capture 1 is the login/PIN-entry screen
(drawer open), capture 2 is the state right after a successful login (drawer
parked, main menu visible). This is a reasonable read of two real exports,
not an assumption about business logic, but it hasn't been confirmed
against an actual login attempt yet.

### Open questions (need a real run or explicit confirmation before Login To POS is considered stable)

1. **Launch vs. attach.** No executable path or launch procedure has been
   given, and both captures already show a running instance. Current
   implementation (ADR-003) attaches to the already-running window via
   `Control Window id:FrmMainMenu3` rather than launching a fresh process.
   Confirm this is how the test environment actually works, or provide the
   real launch procedure/path if tests need to start the POS themselves.
2. **What "Administrator" / "Log Off" in the footer actually represents.**
   Both captures show `txtUserFullName = "Administrator"` and an enabled
   `btnLogout`, even in the capture believed to be the login screen. This
   might be the Windows/workstation session (unrelated to the PIN-based
   POS login), or it might mean the PIN prompt is actually a re-lock/
   re-authentication screen rather than a cold-start login. Needs
   confirmation — ideally by capturing the UI tree right after a genuinely
   fresh app launch, before any PIN is entered.
3. **Login success signal — RESOLVED from a real run; `IsOffscreen` does
   not work for this control.** `pnlMenu` and its buttons exist in the tree
   in both captures regardless of login state (common WinForms pattern —
   panels are pre-created, not created on demand), so their mere presence
   can't be the success check. The original implementation waited for
   `pnlLogin` to report `IsOffscreen = True` (derived from the x-position
   shift described above). A real run against the live POS showed
   `Get Attribute id:pnlLogin IsOffscreen` returning `False` on all 20
   retries after a successful login — that hypothesis is falsified.

   A follow-up real run captured actual post-login attribute values via a
   temporary diagnostic step:

   ```
   DIAG pnlLogin: IsOffscreen=False BoundingRectangle=(1921,69,2430,1199)[509x1130] IsEnabled=True
   DIAG pnlMenu:  IsOffscreen=False BoundingRectangle=(1412,70,1920,1131)[508x1061] IsEnabled=True
   DIAG txtUserFullName: Name="Administrator"
   DIAG rdbFrontEnd: IsEnabled=True IsOffscreen=False
   ```

   `IsEnabled` is `True` for both panels either way, so it can't
   distinguish the states. What the data does confirm is position:
   `pnlLogin.BoundingRectangle.left` (1921) sits at/past
   `pnlMenu.BoundingRectangle.right` (1920) — i.e. the login panel has been
   pushed just past the window's visible edge, matching the drawer-parking
   pattern already seen when comparing the two inspection captures. This
   is now the validated signal: `resources/keywords/login.resource`'s
   `POS Login Panel Should Be Parked` keyword compares `pnlLogin`'s left
   edge against `pnlMenu`'s right edge (not a hard-coded pixel value, so it
   still holds if the window is a different size), wrapped in
   `Wait Until Keyword Succeeds` via `Wait Until POS Login Completes`. The
   temporary diagnostic-logging step has been removed now that a real
   signal has been picked from its output.

   First real run of this keyword failed with a parsing bug, not a wrong
   signal: the values were originally parsed with a regex
   (`re.match(r"\((-?\d+),", ...)`), but Robot Framework treats backslash
   as its own escape character in `.robot`/`.resource` source text and
   silently strips backslash sequences it doesn't recognize, so the regex
   that reached `Evaluate` at runtime was actually `((-?d+),` (missing
   parenthesis, `\d` reduced to `d`) — confirmed by the real error message.
   Rather than fight Robot's escaping with more backslashes, the parsing
   was rewritten with plain string splitting on the already-confirmed
   `(left,top,right,bottom)[widthxheight]` format
   (`$rect.split("(")[1].split(",")[0]` for left,
   `$rect.split("(")[1].split(")")[0].split(",")[2]` for right), which
   needs no backslash escaping at all. The `login_left >= menu_right`
   assertion itself is unchanged.
4. **Test PIN.** Needs a valid PIN supplied via the `POS_PIN` environment
   variable (see `.env.example`) — ideally a dedicated automation account
   rather than a shared Administrator PIN, if the POS supports creating one.

5. **Login screen signal after a fresh launch — RESOLVED from a real run.**
   The only earlier data on what the login screen looks like (`pnlLogin` at
   the visible `x=1412` slot, "Reading the two captures" above) came from
   `FullUiTree-1.json`, a static export of an app that was already running
   when it was captured — never from an automated `Start Process` launch.
   A real run of `POS-LAUNCH-001` (POS launched fresh by the automation,
   nothing already running beforehand) captured the actual post-launch
   values:

   ```
   DIAG (post-launch) pnlLogin: BoundingRectangle=(1412,69,1921,1199)[509x1130]
   DIAG (post-launch) pnlMenu:  BoundingRectangle=(1412,70,1920,1131)[508x1061]
   DIAG (post-launch) txtPin: IsEnabled=True
   DIAG (post-launch) btnLogin: IsEnabled=True
   ```

   This independently confirms the static capture's interpretation was
   right: `pnlLogin.BoundingRectangle.left` (1412) equals
   `pnlMenu.BoundingRectangle.left` (1412) — the login panel is occupying
   the same visible slot as the main menu, i.e. not parked. `IsEnabled` is
   `True` for both `txtPin`/`btnLogin` either way (same limitation as the
   login-success signal — not a usable distinguishing signal on its own).

   The validated signal, `POS Login Panel Should Be In Visible Slot` in
   `resources/keywords/login.resource`: `pnlLogin.left < pnlMenu.right`
   (1412 < 1920 → `True` on the login screen; the same comparison against
   the earlier post-login DIAG data, 1921 < 1920 → `False`, correctly does
   *not* say the login screen is displayed once actually logged in). This
   is the direct logical inverse of the already-validated
   `POS Login Panel Should Be Parked` (`login_left >= menu_right`) — same
   two attributes, opposite comparison, no coordinate hard-coded.

## POS launch — confirmed from a separately-maintained automation project

`pos_keywords.robot` / `pos_variables.robot`: files from another,
already-working Robot Framework automation project that targets this same
POS, shared by the user. Real, working values from there:

| Variable | Value | Notes |
|---|---|---|
| Executable name | `IG.MainMDI.exe` | |
| Working directory | `D:/<DEV_FOLDER>/<PROJECT_FOLDER>/<POS_BUILD_FOLDER>` | Used as `cwd=` for `Start Process` |
| Window locator | `regex:".*POS System"` | Confirmed valid syntax against the installed `rpaframework-core` source (`RPA/core/windows/locators.py`) — `regex:` maps to a `Name` regex match, and the quoting is required by the locator tokenizer because the value contains a space. Not adopted for our own `Wait For And Attach To POS Window`, which reuses the already real-run-validated `id:FrmMainMenu3` (`${LOGIN.WINDOW}`) instead — both identify the same real window. |
| PIN locator | `id:txtPin` | Matches `${LOGIN.PIN_FIELD}` already in `login_screen.resource` exactly |
| Login button locator | `id:btnLogin` | Matches `${LOGIN.SUBMIT_BUTTON}` exactly |
| Window wait timeout | `60` (seconds) | Adopted as `${POS_LAUNCH_WINDOW_TIMEOUT}` for the post-launch attach |

**Observation, not a confirmed match — version string.** The working
directory name (`<POS_BUILD_FOLDER>`) and the footer label captured from our
own real successful login run (`Version:3.99.2608.2(260922.1710)`) are close
but not identical (`2608.1` vs `2608.2`). This is recorded as an open
observation only — a version bump between when that folder was named and
the currently-installed build is a plausible, unremarkable explanation, but
the version string alone is not being treated as proof this is definitely
the same install rather than a similar/updated one. The executable name,
window identity, and locators matching exactly what we've independently
confirmed ourselves are the stronger evidence here.

## Close POS / stale window investigation (open, diagnostic instrumentation added)

Real run (`evidence/poslogin3`, both tests in one suite,
`POS-LOGIN-001` then `POS-LAUNCH-001`):

```
POS-LOGIN-001 - Successful Login                              | PASS |
POS-LAUNCH-001 - Launch POS And Login Successfully            | FAIL |
Keyword 'POS Login Panel Should Be In Visible Slot' failed after retrying
20 times. The last error was: pnlLogin (left=1921) is not in the visible
slot (pnlMenu right=1920) yet
```

`left=1921` is the already-logged-in (parked) position, seen immediately
after `POS-LAUNCH-001`'s own supposedly-fresh `Launch POS` — i.e.
`Wait For And Attach To POS Window` attached to an already-logged-in
window, not the freshly-launched one.

Immediately after that run, the user captured real OS process state:

```
Get-Process IG.MainMDI -ErrorAction SilentlyContinue

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
-------  ------    -----      -----     ------     --  -- -----------
    428      40    77448     104192       0.84  19312   3 IG.MainMDI
    825      88   216176     275880       5.92  25380   3 IG.MainMDI
```

Two `IG.MainMDI` processes are alive after the suite finished, even though
`POS-LOGIN-001` reported `PASS` — which, given `Close POS`'s
`[Teardown]`/`Test Teardown` semantics, means its `Close POS` run did not
raise (no "Cleanup error"), i.e. `Is Process Running handle=pos` returned
`False` for the process `Start Process` tracked under alias `pos`. So the
tracked process genuinely stopped — Robot's own bookkeeping is not lying —
yet a real `IG.MainMDI` process (almost certainly `POS-LOGIN-001`'s, since
`POS-LAUNCH-001` should have its own) is still running.

Source-verified facts relevant here (read directly, not assumed):
- `robot.libraries.Process.start_process`: "Processes are started so that
  they create a new process group" (Windows `CREATE_NEW_PROCESS_GROUP`).
- `robot.libraries.Process.terminate_process`: graceful stop sends
  `CTRL_BREAK_EVENT` (a console-control event); "On Windows... forceful
  kill only stops the main process, not possible child processes."
  `CTRL_BREAK_EVENT` is a console signal — a windowed (non-console) GUI app
  like `IG.MainMDI.exe` has no console control handler to receive it, so it
  is expected to have no effect, and Robot then escalates to the forceful
  Win32 `TerminateProcess()` after the 30s timeout — which unconditionally
  kills whatever PID `Start Process` actually tracked.
- `RPA/core/windows/window.py` (installed `rpaframework-core` source):
  window objects expose a real `ProcessId` attribute (`win.ProcessId`), and
  `RPA.Windows`'s `Get Attribute` keyword (`RPA/Windows/keywords/elements.py`)
  is a generic `getattr` over the underlying element — so
  `Get Attribute    ${LOGIN.WINDOW}    ProcessId` is valid and returns the
  real OS PID of whatever window we actually attached to.

**Root cause confirmed (real WMI process trace, `Register-WmiEvent -Class
Win32_ProcessStartTrace`, run live while `robot ... tests/login/pos_login.robot`
executed).** `${POS_APP_PATH}` (`IG.MainMDI.exe`) does not run as a single
process - launching it produces a two-hop relaunch chain:

```
python.exe (Robot)
└── IG.MainMDI.exe                  <- the process Start Process/alias 'pos' tracks
    └── IG.MainMDILauncher.exe      <- intermediate, short-lived
        └── IG.MainMDI.exe          <- the actual, final process; owns FrmMainMenu3
```

Confirmed twice in the same run (one chain per test case):
```
15320 (Robot) -> 12308 IG.MainMDI.exe -> 9844 IG.MainMDILauncher.exe -> 25048 IG.MainMDI.exe
15320 (Robot) -> 15020 IG.MainMDI.exe -> 3828 IG.MainMDILauncher.exe -> 9352 IG.MainMDI.exe
```
This matches every earlier observation exactly: the PID `Start Process`
tracks under alias `pos` is only the first, outermost hop - it reliably
exits on its own (confirmed separately: `Is Process Running handle=pos`
already read `False` *before* `Close POS` even called `Terminate Process`),
so terminating it was always closing a process that had already exited by
itself, never the real GUI. `IG.MainMDILauncher.exe` is a second,
also-short-lived hop in between. The real, final `IG.MainMDI.exe` (the one
that actually owns the login/main window) is a grandchild that Robot's
`Process` library never started and has no handle for at all - which is
also why `Control Window`'s locator (`id:FrmMainMenu3`, global/not
PID-scoped) could pick up a previous test's leftover one.

**Fix implemented in `resources/keywords/login.resource`:**
- `Wait For And Attach To POS Window` now reads `Get Attribute
  ${LOGIN.WINDOW} ProcessId` right after `Control Window` and stores it as
  `${POS_REAL_PID}` (Suite Variable). This is the real OS PID of the window
  we actually attached to (a genuine `uiautomation` attribute, exposed
  generically by `RPA.Windows`'s `Get Attribute` - see the source citations
  above) - correct regardless of how many hops the relaunch chain has,
  without needing to walk `IG.MainMDI.exe -> IG.MainMDILauncher.exe ->
  IG.MainMDI.exe` at all.
- `Close POS` (`resources/keywords/login.resource`) now runs as both
  `Test Setup` and `Test Teardown` (see `pos_login.robot`) - closing any
  leftover before a test starts, and what the test itself started
  afterwards, always. It closes `${POS_REAL_PID}` specifically via
  `taskkill /PID <exact pid> /F` (never `/IM` - scoped to one exact process
  ID, so an unrelated already-running POS instance is never touched),
  verifies with `tasklist /FI "PID eq <pid>"`, and - as a safety net for the
  case where `Wait For And Attach To POS Window` never got far enough to
  record `${POS_REAL_PID}` - still also attempts the original alias-based
  `Terminate Process handle=pos`, unchanged. Either step failing for a real
  reason raises a "Cleanup error", distinct from the test's own result, and
  per Robot Framework's own teardown semantics does not hide an earlier
  test-body failure.
- The temporary `[DIAG]` logging added to investigate this has been
  removed now that the root cause is confirmed.
- `Verify Login Screen Is Displayed` / `POS Login Panel Should Be In
  Visible Slot` / `POS Login Panel Should Be Parked` / `Login To POS` were
  not touched.

Mechanics of the new `Close POS` (Suite Variable handoff between Test Setup
and Test Teardown across test cases, the IF branching, `Run Process`
result handling, the `TRY`/`EXCEPT` alias fallback) were verified with a
real executed Robot Framework run in the cloud sandbox against real
background OS processes (Linux `kill`/`ps` standing in for
`taskkill`/`tasklist`, which don't exist there) before asking for another
real Windows run - confirming the suite-variable clear-before-close
ordering, the "nothing tracked yet" no-op path, and that a failure in one
cleanup step still lets the fallback step run and still reports correctly,
all behave as designed.

## Correction - Get Attribute ProcessId reverted (real run regression)

The `${POS_REAL_PID}` approach above (reading `Get Attribute ${LOGIN.WINDOW}
ProcessId` inside `Wait For And Attach To POS Window`) caused a real
regression: `POS-LOGIN-001` started failing with
`ElementNotFound: Element not found with locator 'id:FrmMainMenu3'`. Source
inspection (`RPA/core/windows/context.py`, `RPA/Windows/keywords/window.py`,
`RPA/core/windows/locators.py`) confirmed this is a different exception
than `Control Window`'s own `WindowControlError`, and comes specifically
from `Get Attribute`'s independent re-search of the same locator - which
uses a short default timeout (not the 60s given to `Control Window`) and
can lose the race during POS's own relaunch churn (confirmed separately via
WMI trace: launching `${POS_APP_EXE_NAME}` is itself a multi-hop, async
relaunch, and an unrelated "Error" window can appear during it).

`Wait For And Attach To POS Window` has been reverted to its original,
poslogin3-passing single-call form (`Control Window` only, no PID lookup).
`Close POS` no longer depends on anything captured there - it now
identifies "its" POS instance(s) purely at the OS process level (any
currently running `${POS_APP_EXE_NAME}` whose parent process is no longer
alive - the signature its own relaunch chain leaves behind), entirely
self-contained, with no UI Automation calls and no Sleep. See the `Close
POS` keyword's own documentation in `resources/keywords/login.resource`
for the exact mechanism and its accepted trade-off.

## Flow 02 - Sales/order screen inspection

Four real FullUiTree captures of the order (FrmOrder) and payment
(DlgPaymentW8) screens were provided and cross-referenced before
implementing POS-SALE-001. Confirmed controls (all with stable, developer-
assigned string AutomationIds, identical across every capture where they
appear):

- `FrmOrder` (Window) - the order screen itself.
- `lstItems` (id, class ListViewEx) - the order/item list.
- `btnTotal` (id) - Name shows the running order total as text, e.g.
  "0.00" on an empty cart, confirmed identically in two separate captures
  taken minutes apart with no items added.
- `DlgPaymentW8` (Window, Name "ชำระเงิน") - the payment dialog, appears as
  a child window of FrmOrder (FrmOrder becomes disabled while it is open).
- `txtTotalDue`, `txtPaid`, `txtBalance` (id, Edit controls, Value pattern)
  - all inside DlgPaymentW8.
- `btnCustomerExact` (id, Name "พอดี") - inside DlgPaymentW8's cash-
  denomination panel.
- `btnOK` (id, Name "สิ้นสุดการขาย") - finish-sale button inside
  DlgPaymentW8.
- `DlgAskPrintKitchen` (Window) / `btnNo` (id, Name "ไม่พิมพ์") - the
  post-sale kitchen-print prompt and its decline button.

### AutomationId instability (quick-sale grid and payment-method grid)

Two of the four captures showed the *same* quick-sale product page (by
which buttons appear) roughly three minutes apart, on the same running
session. Comparing them by button Name:

- "<PRODUCT_NAME>": AutomationId 856010 in the earlier capture,
  856578 in the later one.
- "<PRODUCT_B>": 922016 vs 987082.
- "<PRODUCT_C>": also differed between the two captures.

No developer-assigned string AutomationId anywhere else in these captures
(FrmOrder, lstItems, btnTotal, DlgPaymentW8 and its children,
DlgAskPrintKitchen, btnNo) ever changed across any capture. This points to
the quick-sale grid (pnlQuickButton/UCQuickSaleFlat) and the payment-method
grid (pnlPayment) using runtime-generated AutomationIds that are
reassigned when the panel is recreated, rather than IDs the developer set
explicitly.

Consequence for POS-SALE-001: `resources/locators/sales_screen.resource`
addresses the quick-sale product button and the Cash payment-method button
by `name:` instead of the literal AutomationId values seen in the
evidence (856578 for "<PRODUCT_NAME>", 266664 for the Cash
button/"เงินสด") - those literal IDs are not expected to stay valid on a
different POS session. Every other control above uses `id:` exactly as
captured, since its stability was directly confirmed.

### lstItems has no readable content

In every capture, `lstItems` reports `childrenCount: 0` and supports only
the `LegacyIAccessible` pattern (no `Value`/`Table`/`Grid` pattern). Its
own `Name` attribute is always the static string "listViewEx1" (a
class-like label), not its actual contents. There is currently no
confirmed way, via `Get Attribute`/child-element traversal, to read an
individual line item's name or price out of it.

Consequence: "verify the item appears in the order" (step 4 of the
confirmed POS-SALE-001 flow) is implemented as a proxy check instead -
`Order Total Should Have Changed From` confirms the order total moved away
from the confirmed "0.00" empty-cart baseline after adding the item,
rather than reading the item back out of `lstItems` directly. If a way to
read `lstItems`' contents is found later (e.g. a different pattern
becomes available, or a child-control structure appears under real
conditions this evidence didn't capture), this can be tightened.

### Two inferred (not directly observed) transitions

Two steps in the confirmed flow don't have a directly-captured
click-then-result trace in the evidence gathered so far:

- Which control opens the order screen from the main menu. Implemented as
  a click on the already-confirmed `${MAIN_MENU.POS_BUTTON}`
  (`id:btnPOS`), since it is the confirmed "POS" entry point on the main
  menu - not a captured click-to-FrmOrder trace.
- Which control opens the payment dialog from the order screen. Implemented
  as a click on `${ORDER.TOTAL_BUTTON}` (`btnTotal`), based on its
  structural position (`pnlBottom`/`tblTotalRow`) - not a captured
  click-to-DlgPaymentW8 trace.

Both are implemented so that a wrong inference fails loudly (a
`Control Window` timeout/`WindowControlError` on the expected next window)
rather than silently continuing against the wrong screen. Both need
confirmation from a real run.

### Real run #1 - btnTotal not queryable right after Open Front End

A real run of POS-SALE-001 failed before `Add Quick Sale Item` ever ran,
at the first `Order Total Should Be 0.00` check right after
`Open Front End` (`results/output.xml`):

```
Getting element with locator: id:FrmOrder and type:WindowControl
Returning element: ... id='FrmOrder' ...
Getting element with locator: id:btnTotal
Find Control Timeout(10.0s): {AutomationId: 'btnTotal'}
[FAIL] ElementNotFound: Element not found with locator 'id:btnTotal'
```

`Control Window` had already returned the `FrmOrder` window element
successfully; the very next call, reading `btnTotal`'s `Name` via
`Get Attribute`, failed with `ElementNotFound` after its own internal 10s
search. Root cause: the window container is queryable before its child
controls have finished rendering - the same class of timing issue already
documented once before in this project for a fresh POS launch (see
"Correction - Get Attribute ProcessId reverted" above), just triggered
here by entering the order screen instead of launching the app.

Fix applied: a new `Wait Until Order Screen Is Ready` keyword in
`resources/keywords/sales.resource`, called from `Open Front End` right
after `Control Window`, wraps `Get Order Total` in
`Wait Until Keyword Succeeds 10x 1s` - the same scoped-retry pattern
already used for POS's own slow transitions elsewhere (`Wait Until POS
Login Completes`, `Verify Login Screen Is Displayed` in
`login.resource`). `btnTotal`'s locator (`id:btnTotal`), `Get Attribute`'s
own internal timeout, and every Login/lifecycle/payment keyword were left
untouched - this is a targeted retry around the one read that needed the
control to exist, not a global timeout increase.

### Confirmed: quick-sale navigation is 3 levels deep, not flat

The same real run's underlying premise - that `Add Quick Sale Item` could
click "<PRODUCT_NAME>" directly off the top-level quick-sale
screen - turned out not to match the real POS. The actual path is:

1. Click **"<CATEGORY_NAME>"** - a category button in `pnlQuickPage` (confirmed
   earlier from `95b9c837-...json` / `99e49705-...json`; AutomationId
   790220 vs 921578 across those two captures - unstable, hence `name:`).
2. Click **"<SUBCATEGORY_NAME>"** - a subcategory button. Found by re-examining the
   payment-dialog capture (`b52ed8ce-...json`) more closely: it snapshots
   `FrmOrder` mid-navigation (disabled, underneath the open
   `DlgPaymentW8`), and at that moment `pnlQuickButton` was showing seven
   subcategory buttons - <OTHER_SUBCATEGORY>, <OTHER_SUBCATEGORY>, <OTHER_SUBCATEGORY>, **<SUBCATEGORY_NAME>**,
   <OTHER_SUBCATEGORY>, <OTHER_SUBCATEGORY>, <OTHER_SUBCATEGORY> - AutomationId 200970 for <SUBCATEGORY_NAME> in
   that capture. This is the same `pnlQuickButton` panel that, in the
   other two captures, was instead showing actual salad products - i.e.
   the panel is reused for both the subcategory list and the product list
   depending on navigation state.
3. Click **"<PRODUCT_NAME>"** - a product button in the same
   `pnlQuickButton` panel once "<SUBCATEGORY_NAME>" has been selected (already
   confirmed, AutomationId 856010 vs 856578 across two captures).

All three steps use `name:` locators (`${QUICK_SALE.CATEGORY_FOOD}`,
the subcategory locator, and `name:${item_name}` for the
product) in `resources/locators/sales_screen.resource` /
`resources/keywords/sales.resource`'s `Add Quick Sale Item`, consistent
with the AutomationId instability already established for this grid. This
path is currently confirmed only for "<PRODUCT_NAME>" -
`Add Quick Sale Item` does not generalize this to other products, since no
other product's category/subcategory path has been confirmed yet.

### Real run #2 - btnTotal still not found after the retry fix; run interrupted

A second real run (`results/output.xml`, 2026-09-25 09:37) used the
`Wait Until Keyword Succeeds 10x 1s` fix from real run #1. `Control Window`
on `FrmOrder` again succeeded quickly (~1.9s). `Get Attribute id:btnTotal`
then failed twice in a row, each after its own full ~10s internal search
(~21s of continuous failure). `log.html`/`report.html` in that same
`results/` folder were never regenerated (still timestamped from the
*previous* run) and `output.xml` itself is malformed/incomplete - meaning
this run was stopped (manually or otherwise) before Robot Framework
finished, during the 2nd of 10 retry attempts. So this run did not
establish whether the wait would have eventually succeeded or not.

### Ruled out: no UI state/gate between FrmOrder and btnTotal

Before extending the retry further, traced `btnTotal`'s actual ancestry and
enabled/visible state across all four real captures directly (not just the
one that happened to show the quick-sale subcategory list):

```
FrmOrder -> pnlMain -> PaneBase -> pnlBottom -> splitBottom
         -> pnlTotalMain -> tblTotalRow -> TableLayoutPanel5 -> btnTotal
```

This is identical in every capture, and every node on it -
`pnlMain`, `PaneBase`, `pnlBottom`, `splitBottom`, `pnlTotalMain`,
`tblTotalRow`, `TableLayoutPanel5`, `btnTotal` itself - is
`enabled=True, visible=True` with a real, non-zero bounding rectangle in
every one of the four captures, including the very first, empty-cart one.

The "กรุณาเลือกประเภทลูกค้า" (`spltMain`) pane flagged as a possible gate
earlier is a **sibling** of `pnlBottom` under the same `PaneBase`, not an
ancestor of `btnTotal`:

```
PaneBase
 |- pnlBottom -> ... -> btnTotal          (totals/summary side)
 `- spltMain -> ... -> pnlQuickButton     (quick-sale side)
```

`spltMain` has exactly two generic, unnamed `Pane` children in every
capture (`childrenCount=2` throughout) - consistent with it being the two
halves of a plain WinForms `SplitContainer`, with its Thai name most likely
a static `AccessibleName` on the container itself, not a live
customer-type prompt. There is no disabled/hidden state anywhere on
`btnTotal`'s own ancestry in any capture. This rules out a structural
gate as the explanation for real run #2's failure.

### Fix #2 (diagnostic) - bounded, instrumented retry to find the real ceiling

Since every hand-taken capture shows `btnTotal` present and normal (just
never captured *immediately* after the screen opens), and no structural
gate explains the failure, the remaining explanation is that `FrmOrder`'s
child-control tree genuinely takes longer to finish building than the
~21s observed - or never finishes without some as-yet-unconfirmed step.
Rather than guess a duration or invent a selector, `Wait Until Order
Screen Is Ready` (`resources/keywords/sales.resource`) was changed from a
plain `Wait Until Keyword Succeeds 10x 1s` into a bounded, instrumented
loop:

- Re-confirms `${ORDER.WINDOW}` via `Control Window` on every attempt -
  the same re-attach idiom found in an older Dine-In flow from the same
  POS lineage (re-`Control Window` after a navigating action, rather than
  assuming instant readiness), reused here as a pattern only - none of
  that flow's locators or paths were copied.
- Up to `${ORDER_SCREEN_MAX_ATTEMPTS}` (10) attempts, `
  ${ORDER_SCREEN_RETRY_INTERVAL}` (2s) apart - bounded, not unbounded.
- Logs the attempt number and elapsed time at which `btnTotal` first
  becomes available.
- If it never becomes available within the bound, fails with a distinct
  "never became available" message rather than a generic timeout, so a
  real (larger) ceiling and a genuinely non-resolving case are told apart
  in the log rather than guessed at.

No selector, Login file, POS lifecycle keyword, payment keyword, or sales
locator was touched - only this one keyword's internal wait logic.

### Fix #3 (test) - repeated Control Window, isolated (no retry loop)

Before running fix #2's bounded diagnostic loop, a real older Dine-In
automation from the same POS lineage surfaced a specific, repeated
pattern: `Control Window` called again, with an explicit timeout, after a
navigation action, before touching that screen's controls - not once, but
at more than one point in that flow. Pattern only; none of that flow's
locators or paths were used here.

To test this pattern in isolation (so the result isn't confounded by a
retry loop also being in play), `Open Front End` was changed to call
`Control Window ${ORDER.WINDOW} timeout=${ORDER_WINDOW_TIMEOUT}` **twice**
in a row, and no longer calls `Wait Until Order Screen Is Ready`
afterwards. `POS-SALE-001`'s very next step (`Order Total Should Be
0.00`) is a single, unwrapped read - so this real run will show cleanly
whether the repeated-Control-Window alone resolves `btnTotal`, with
nothing else masking the result either way.

`${ORDER_WINDOW_TIMEOUT}` (30) is a new, explicit named timeout in the
same style as the old flow's own named timeout variable - not a confirmed-
necessary value (Control Window on FrmOrder has resolved in ~1-2s in
every real run so far), just explicit rather than relying on the library
default, matching the old flow's own convention.

`Wait Until Order Screen Is Ready` and its two variables
(`${ORDER_SCREEN_MAX_ATTEMPTS}`, `${ORDER_SCREEN_RETRY_INTERVAL}`) were
left in place, just unused for now, in case the repeated-Control-Window
test does not resolve `btnTotal` and the bounded retry approach needs to
be reintroduced (possibly combined with this pattern).

No selector, Login file, POS lifecycle keyword, payment keyword, or sales
locator was touched.

### Fix #4 - restructured POS-SALE-001 to avoid the early btnTotal read entirely

A real, already-working reference automation for this same POS
(`pos_walkin_sale.robot`, converted from a previously-working Python
automation) was provided for comparison. It confirmed the <CATEGORY_NAME> -> <SUBCATEGORY_NAME> ->
"<PRODUCT_NAME>" navigation exactly as already implemented, and
revealed a structural difference worth adopting: it never reads `btnTotal`
immediately after entering the order screen. It goes straight into
ordering items and only reads the total afterwards - sidestepping the
exact early-read race this project had been chasing with retries and a
repeated `Control Window` call, rather than solving it.

Two things in that reference were deliberately NOT copied, since our own
real evidence already contradicts them for this target: `Click name:POS`
(our real run log showed this button's actual Name is `การขาย`, not
`POS` - likely a different language/config of the same lineage), and
attaching to the order window via `Control Window regex:.*Easy Management
System` instead of `id:FrmOrder` (our `id:FrmOrder` attach has been fast
and reliable in every real run - not broken, no reason to replace it). Its
path-qualified `${TOTAL_BTN_LOCATOR}` (`automationid:btnTotal and
path:"1|1|3|1|1|1|1|1|1"...`) was also not adopted - our failures have
been `ElementNotFound`, not ambiguous-match errors, so there's no evidence
that qualifier is needed here.

`tests/sales/pos_sale.robot`'s `POS-SALE-001` was restructured to match
the reference's actual order of operations: the `Order Total Should Be
0.00` read immediately after `Open Front End` was removed. The confirmed
empty-cart value ("0.00", from two separate real captures) is now used
only as the baseline argument to the already-existing `Order Total Should
Have Changed From    0.00` (still wrapped in its own
`Wait Until Keyword Succeeds 10x 0.5s`, unchanged) - so `btnTotal`'s first
live read happens only after `Add Quick Sale Item`, by which point the
same natural delay the reference flow relies on has already elapsed.

Nothing else changed: `Open Front End`, `Control Window`, `btnTotal`'s
locator, the <CATEGORY_NAME> -> <SUBCATEGORY_NAME> -> <PRODUCT_NAME> navigation, Login,
POS lifecycle, and every payment keyword are all untouched (verified via
md5). This is the smallest structural change consistent with the proven
reference, not a new timeout or retry mechanism.

### Real run #3 - progress: btnTotal race is gone; new failure on product click

Real run of the restructured POS-SALE-001 got past `Open Front End` and
`Order Total Should Have Changed From` entirely without any `btnTotal`
issue - confirming the restructuring fix worked. It then failed inside
`Add Quick Sale Item`:

```
Locator 'name:<PRODUCT_NAME>' produced matcher:
MatchObject(locators=[('Name', '<FIRST_WORD>', 0), ('Name', '<REMAINING_WORDS>', 0)], ...)
Find Control Timeout(10.0s): {Name: '<REMAINING_WORDS>'}
[FAIL] ElementNotFound: Element not found with locator 'name:<PRODUCT_NAME>'
```

Root cause, confirmed directly from the log (not guessed): RPA.Windows'
locator parser split the unquoted, space-containing value into **two**
separate `Name` clauses instead of one string, so it searched for a
button matching both fragments at once - which doesn't exist. `Click
name:<CATEGORY_NAME>` and `Click name:<SUBCATEGORY_NAME>` (both single words, no space)
succeeded immediately just before this, in the same run.

This exactly matches the convention already used in the real, working
`pos_walkin_sale.robot` reference: every multi-word Name there is quoted
(`name:"<PRODUCT_NAME>"`, `name:"Product A"`,
`name:"Finalize Sales"`), while single-word ones (`<CATEGORY_NAME>`, `<SUBCATEGORY_NAME>`,
`<OTHER_SUBCATEGORY>`, `Exact`) are left unquoted - the same pattern this project
already uses for `<CATEGORY_NAME>`/`<SUBCATEGORY_NAME>`.

### Fix #5 - quote the dynamic product name in Add Quick Sale Item

`Add Quick Sale Item`'s last line in `resources/keywords/sales.resource`
changed from `Click    name:${item_name}` to
`Click    name:"${item_name}"`. Nothing else touched: `<CATEGORY_NAME>`/`<SUBCATEGORY_NAME>`
locators and clicks, `Open Front End`, `Control Window`, `btnTotal`'s
locator, Login, lifecycle, payment, and the test case structure are all
unchanged (verified via md5). Dry-run clean; project-wide dry-run still
shows exactly 10 tests, no ambiguous keywords.

### Real run #4 - Fix #5 confirmed working, new failure one step later

With Fix #5 applied, a real run resolved `<CATEGORY_NAME>`, `<SUBCATEGORY_NAME>`, and
`name:"<PRODUCT_NAME>"` successfully - the locator-splitting bug
is fixed. But the next step failed, more severely than anything seen so
far:

```
[FAIL] Keyword 'Order Total Should Have Changed From' failed after
retrying 10 times. The last error was: ElementNotFound: Element not
found with locator 'id:btnTotal'
```

Parsed directly from `results/output.xml`: all 10 attempts of the
existing `Wait Until Keyword Succeeds    10x    0.5s` wrapper each spent
the full internal `Find Control Timeout(10.0s)` searching for
`id:btnTotal` and never once succeeded - a continuous ~108s
(17:14:28 -> 17:16:16) of `ElementNotFound`. `Control Window` on
`FrmOrder` was not re-checked inside this particular retry (only
`Get Attribute` is), but the window itself had been freshly confirmed
immediately before, at the end of `Open Front End`.

This is a different failure from the earlier pre-add race (Fix #4): it
is ~5x longer, occurs one step later (after a successful product click,
not right after opening the order screen), and cannot be explained by
the previously-ruled-out static ancestry evidence (real captures show
`btnTotal` present/enabled/visible even in an after-items-added
snapshot, total="<ORDER_TOTAL>"). No UI-tree capture exists for the moment right
after clicking a quick-sale product, so there is no confirmed explanation
yet - possibilities include (unconfirmed) a modifier/quantity dialog
appearing for this specific product, without evidence to support or rule
it out.

### Fix #6 (diagnostic, no behavior change) - capture the live tree on this exact failure

Rather than guess at a cause and change `btnTotal`'s locator, the retry
counts/timing, or add another blind wait, added a diagnostic-only
capture so the *next* real run that hits this failure produces its own
evidence automatically:

- New keyword `Capture Order Screen Diagnostic Tree` in
  `resources/keywords/sales.resource` - calls RPA.Windows' own
  `Print Tree    ${ORDER.WINDOW}    max_depth=6    log_as_warnings=${True}`,
  wrapped in TRY/EXCEPT so a failure capturing the tree (e.g. the window
  is already gone) is logged and swallowed rather than replacing the real
  failure.
- In `tests/sales/pos_sale.robot`, the existing
  `Wait Until Keyword Succeeds    10x    0.5s    Order Total Should Have
  Changed From    0.00` line is now wrapped in TRY/EXCEPT: on exhaustion,
  it calls the diagnostic capture, then re-fails with the exact same
  original error message via `Fail    msg=${total_wait_error}` - so
  pass/fail behavior and the reported error are unchanged; only a control
  tree gets logged into `log.html` when this specific failure happens.

Nothing else touched: `btnTotal`'s locator, `Get Order Total`, `Open
Front End`, the confirmed <CATEGORY_NAME> -> <SUBCATEGORY_NAME> -> product navigation, Login,
POS lifecycle, and payment logic are all unchanged (verified via md5).
Dry-run clean on the Linux side (RPA.Windows keywords, including the new
`Print Tree` call, all resolve to "No keyword with name ... found" only
because RPA.Windows itself isn't installed on this side - the same
pre-existing, already-documented limitation as every other dry-run in
this project; no new/different error type was introduced by this change).

Next real run of POS-SALE-001: if it reaches this failure again,
`log.html` will now contain the live control tree under `FrmOrder` at
that moment - that capture is the next piece of evidence needed before
attempting an actual fix.

### New evidence source - <REFERENCE_PROJECT_FOLDER> folder (same POS install, confirmed)

The user connected a second folder,
`C:\Users\<WINDOWS_USER>\Desktop\<REFERENCE_PROJECT_FOLDER>`, containing an older,
independent set of real Robot Framework automations for this same class
of POS (the ones `pos_walkin_sale.robot`, studied earlier, was itself
converted from). Two facts confirm this is the *same physical POS
install* this project's own real runs use, not just "the same lineage":

- `variables/pos_variables.robot`'s `${POS_PATH}` is
  `D:/<DEV_FOLDER>/<PROJECT_FOLDER>/<POS_BUILD_FOLDER>/IG.MainMDI.exe`, matching
  this project's own real run logs (`Start Process` in `output.xml`)
  character-for-character.
- Its `${PIN}` matches the PIN this project's own real Flow 01 login runs
  use (value deliberately not recorded here - secrets live only in `.env`).

Two things directly relevant to the open `btnTotal`-after-add failure
were found in it:

1. **`${TOTAL_BTN_LOCATOR}`, used identically in both
   `tests/POS/pos_walkin_sale.robot` and
   `tests/Dine_in/dine_in_happy_case.robot`, is not a bare AutomationId**:
   ```
   automationid:btnTotal and path:"1|1|3|1|1|1|1|1|1" and control:ButtonControl
   ```
   Both files use this same compound locator, with the same path string,
   to both read and click the total button, at the same moment in the
   flow this project's own test fails at (right after items are added).
2. **Every navigating click in `tests/Dine_in_sale.robot` is followed by
   a settle delay then a fresh window re-attach before the next
   read/click** - not a one-time thing at window-open, but after *each*
   action:
   ```
   Click    name:"Product B"
   Sleep    0.5s
   Control Window    ${DINE_IN_WINDOW}    timeout=${WINDOW_TIMEOUT}
   Print Tree    log_as_warnings=${True}
   Click    automationid:txtPayment
   ```
   This refines the "repeated Control Window" idea tested earlier (Fix
   #3, a bare double-call with no delay, only once at window-open) - the
   actual proven pattern is delay-then-reattach after every navigating
   click, product selection included.

### Fix #7 - adopt both confirmed patterns from the matching real install

Given this is the same POS install (not a guess - see the two matching
facts above) and the user explicitly pointed at this folder to study and
copy from:

- `resources/locators/sales_screen.resource`: `${ORDER.TOTAL_BUTTON}`
  changed from `id:btnTotal` to the compound locator above, copied
  verbatim from both matching reference files.
- `resources/keywords/sales.resource`: `Add Quick Sale Item` now does
  `Sleep    ${QUICK_SALE_SETTLE_DELAY}` (new variable, `0.5s`, the same
  literal value both reference files use) then
  `Control Window    ${ORDER.WINDOW}` immediately after the product
  click, before returning.

Nothing else touched: Login, POS lifecycle, payment keywords, the
<CATEGORY_NAME> -> <SUBCATEGORY_NAME> navigation, the quoted `name:"${item_name}"` fix, and the
Fix #6 diagnostic capture (`Capture Order Screen Diagnostic Tree`, still
in place as a safety net if this doesn't fully resolve it) are all
unchanged (verified via md5). Dry-run clean - project-wide dry-run still
shows exactly 10 tests, and the only "not found" keywords are the
expected RPA.Windows ones (including the new `Control Window` call in
`Add Quick Sale Item` and the pre-existing `Print Tree`), consistent with
the same pre-existing RPA.Windows-on-Linux import gap as every other
dry-run in this project.

### Real run #5 - Fix #7 confirmed working, new failure one step further in

With Fix #7 applied, a real run resolved `id:btnTotal` (via the compound
locator) on the very first attempt after adding the item -
`Order Total Should Have Changed From` passed immediately, reading
"<ORDER_TOTAL>" - no retries needed at all. The flow then got all the way
through `Open Payment Dialog`, `Payment Dialog Total Due Should Be`
("<ORDER_TOTAL>", correct), and `Select Cash Payment` with no issue, and failed
one step further than ever before:

```
[FAIL] Paid amount '0.00' does not match total due '<ORDER_TOTAL>': 0.00 != <ORDER_TOTAL>
```

Parsed directly from `results/output.xml`: `Click id:btnCustomerExact`
(Pay Exact Amount) itself reported success, but the very next reads -
with no delay in between - showed `txtPaid` still "0.00" and `txtBalance`
still "<ORDER_TOTAL>" (the pre-click values), while `txtTotalDue` correctly
still read "<ORDER_TOTAL>". This is the same class of symptom already fixed
twice in this flow: a control's displayed value not yet reflecting a
just-completed click when read immediately afterward.

### Fix #8 - same settle-then-reattach pattern, applied to Pay Exact Amount

The `<REFERENCE_PROJECT_FOLDER>` reference folder's `tests/Dine_in_sale.robot`
already showed this exact pattern for this exact control:

```
Click    automationid:btnCustomerExact
Sleep    0.5s
Control Window    ${DINE_IN_WINDOW}    timeout=${WINDOW_TIMEOUT}
```

Applied the same fix: `Pay Exact Amount` in
`resources/keywords/sales.resource` now does
`Sleep    ${POS_SETTLE_DELAY}` then
`Control Window    ${PAYMENT.DIALOG}` right after clicking
`btnCustomerExact`. The settle-delay variable (previously
`${QUICK_SALE_SETTLE_DELAY}`, added in Fix #7 for the product-click case)
was renamed to the more general `${POS_SETTLE_DELAY}` since it's now
confirmed to apply to more than just the quick-sale click - same 0.5s
value, same source. All other usages/values unchanged (verified via md5:
`sales_screen.resource`, `login.resource`, `pos_login.robot`,
`pos_sale.robot` all byte-identical to before this change). Dry-run
clean - project-wide dry-run still exactly 10 tests, and the "not found"
keyword counts changed only by the one new `Control Window` call this
adds (28 -> 29), consistent with the same pre-existing RPA.Windows-on-
Linux import gap as every other dry-run in this project.

### Real run #6 - Fix #8 was treating the wrong symptom

With Fix #7 applied (btnTotal resolved), the flow got to
`Payment Should Match Total Due` and failed: `Click id:btnCustomerExact`
(Pay Exact Amount) reported success, but `txtPaid`/`txtBalance` never
changed. Fix #8 treated this as the same stale-read symptom already fixed
twice (settle delay + re-attach) and applied the same pattern to
`Pay Exact Amount`.

The user then provided a fresh, live UI-tree capture
(`FullUiTree-25690925-175220.json`) taken right after `Select Cash
Payment`, plus a plain-language description of the real flow ("click
Cash, then click OK, then click Finish Sale"). The capture showed the
actual root cause, which Fix #8 did not address:

- `DlgPaymentW8` itself was `enabled: false` in that capture - a modal
  child dialog was on top of it and owned input focus.
- That modal, `DlgAmount` (Name "จำนวน" / "Amount"), sits *inside*
  `DlgPaymentW8`'s own element tree (parent `DlgPaymentW8`) and has its
  own numeric keypad, its own `txtAmount` (pre-filled "<ORDER_TOTAL>", matching
  the confirmed order total exactly - no typing needed), and its own
  confirm/cancel buttons.
- Critically, `DlgAmount`'s confirm button's AutomationId is *also*
  `btnOK` - the same AutomationId as `${PAYMENT.FINISH_SALE_BUTTON}` -
  but it's a completely different control (Name "ตกลง" / "OK", vs.
  "สิ้นสุดการขาย" / "Finish Sale" for the one directly on `DlgPaymentW8`).

This explains the original symptom precisely: `Select Cash Payment`
(clicking เงินสด) opens `DlgAmount` automatically. The old
`Pay Exact Amount` then clicked `btnCustomerExact` ("พอดี"), a control on
`DlgPaymentW8`'s own `pnlCustomCash` panel - but `DlgPaymentW8` was
modally blocked at that moment, so the click reported success (no
exception) while having no real effect on screen. No amount of settling
or re-attaching to `DlgPaymentW8` (Fix #8) could have fixed this, because
the problem was never staleness - it was interacting with the wrong,
blocked window.

### Fix #9 - handle DlgAmount explicitly, confirmed by the user

- `resources/locators/sales_screen.resource`: added
  `${PAYMENT.AMOUNT_DIALOG}` (`id:DlgAmount`) and
  `${PAYMENT.AMOUNT_CONFIRM_BUTTON}` (`id:btnOK`, only ever used after
  explicitly re-attaching to `${PAYMENT.AMOUNT_DIALOG}` first, to avoid
  the AutomationId collision with `${PAYMENT.FINISH_SALE_BUTTON}`).
- `resources/keywords/sales.resource`: new keyword
  `Confirm Cash Payment Amount` - `Control Window
  ${PAYMENT.AMOUNT_DIALOG}` -> `Click ${PAYMENT.AMOUNT_CONFIRM_BUTTON}` ->
  settle delay -> `Control Window ${PAYMENT.DIALOG}` (re-attach back
  before the next read/click). `Pay Exact Amount` is kept, not deleted,
  but documented as not currently used in this flow and why.
- `tests/sales/pos_sale.robot`: `Select Cash Payment` is now followed by
  `Confirm Cash Payment Amount` instead of `Pay Exact Amount`.

Everything else verified unchanged via md5: Login, lifecycle, the
confirmed navigation, `${ORDER.TOTAL_BUTTON}`, `Open Front End`,
`Add Quick Sale Item`. Dry-run clean; project-wide dry-run still exactly
10 tests, with one more `Control Window` reference than before (29 -> 30),
matching the new call this adds - consistent with the same pre-existing
RPA.Windows-on-Linux import gap as every other dry-run in this project.

## Flow 04-06 - ported from the reference project

Recall Receipt (Flow 04), the walk-in sale database check (Flow 05) and
the dine-in sale (Flow 06) were moved in from the
`<REFERENCE_PROJECT_FOLDER>` project - the same POS install already
confirmed above. Its locators are copied as-is into
`resources/locators/receipt_screen.resource` and
`resources/locators/dine_in_screen.resource`, each marked as not yet
confirmed by this project's own inspection. None of these three tests has
run from this project yet.

Changes made while porting (not copied blindly):

- **One database, from `.env`.** The reference's `PosDb.py` hard-coded
  two different databases (one for the walk-in total check, another for
  dine-in/recall), and the second no longer exists on the test machine.
  The POS this project launches writes to the database in `POS_DB_NAME`
  - its latest sales match this project's own POS-SALE-001 run dates - so
  every check now uses that one database via `libraries/PosDatabase.py`.
- **No fixed Sleep after Recall.** The reference waited 8s after OK; this
  project polls until the recalled Total equals the database Total.
- **Stronger database assertions.** The reference compared Total only; Flow
  05/06 also check `Tendered` = `Total`, `Change` = 0 and that the added
  item is on the bill.
- **Walk-in UI flow not duplicated.** POS-E2E-001 reuses POS-SALE-001's
  confirmed payment path (Cash -> DlgAmount -> Finish Sale) instead of the
  reference's `Exact` / `Finalize Sales` clicks. The dine-in test keeps the
  reference's path, because no dine-in payment screen has been inspected
  here yet.

Not moved: the reference's login tests (covered by Flow 01) and
`Dine_in_sale.robot` (an earlier draft of the dine-in happy case with no
assertions).

Schema confirmed for these checks: `Sale` (SaleNum, SubTotal,
ServiceChargeAmount, DiscountAmount, Tax, Total, Tendered, Change,
IsFinalize, Active) and `SaleItem` (SaleId, ItemDesc, Active).

## Cleanup pass - keyword docs shortened, dead code removed

- Long `[Documentation]` blocks in `login.resource` / `sales.resource` /
  the Flow 01-02 test files were cut down to what a reader needs; the
  reasoning they used to carry is in the sections above (referenced as
  Fix #N where relevant). Keyword bodies were not changed.
- Removed two keywords nothing called any more: `Wait Until Order Screen
  Is Ready` (Fix #2 diagnostic, superseded by Fix #4) and `Pay Exact
  Amount` (superseded by `Confirm Cash Payment Amount`, Fix #9).
- Removed POS-LAUNCH-001: it called exactly the same keyword as
  POS-LOGIN-001.
- The payment steps shared by POS-SALE-001, POS-SALE-003 and POS-E2E-001
  are now one keyword, `Pay Exact Cash And Finish Sale`; the total wait +
  diagnostic tree capture is `Wait Until Order Total Changes From`.

## First real run of Flow 04-06 (2026-10-30)

POS build on screen: 3.99.2611.1 (261029.1135), DB `<TEST_DB>`.
Evidence folders under `evidence/` (git-ignored).

### Run #1 - smoke 2/2, pending-first-run 2/4

POS-E2E-001 and POS-SALE-003 passed first time. POS-RECEIPT-001 and
POS-DINEIN-001 both failed with `ElementNotFound: name:OK`. The failure
screenshots showed why: this POS runs in Thai, so the button reads
"ตกลง"; the reference project matched English captions.

### Fix #10 - language-independent locators from the POS source

WinForms control names are the UIA AutomationIds, so they were read from
the designer files instead of guessed:

| Locator | Was | Now | Source |
|---|---|---|---|
| Recall OK | `name:OK` | `id:DlgSearchSales > id:btnOK` | designer file of DlgSearchSales |
| Guest count OK | `name:"OK"` | `id:DlgNumOfCust > id:btnOK` | designer file of DlgNumOfCust |
| Dine-in Exact | `name:Exact` | `id:btnCustomerExact` | same DlgPaymentW8 as Flow 02 |
| Dine-in Finalize | `name:"Finalize Sales"` | `id:DlgPaymentW8 > id:btnOK` | same DlgPaymentW8 as Flow 02 |
| Dine-in Sales Lookup | `name:"Sales Lookup"` | `id:btnSaleLookup` | designer file of the floor-plan pane |
| Table "Is in use" popup | `name:"Is in use"` / `name:Yes` | `class:#32770` + caption regex / `automationid:6` | plain MessageBox; th-TH caption "มีคนใช้งานอยู่"; IDYES = 6 |

The `parent > child` scoping matters: btnOK is also the AutomationId of
DlgAmount's confirm button (see Fix #9).

### Run #2 - both got further, two new failures

- POS-RECEIPT-001: the amount controls are grid footer cells whose Name
  carries the column caption ("ยอดขาย353.10"). `Read Amount From Screen`
  now takes the last number in the text instead of the whole string.
- POS-DINEIN-001: no "Printing" slip-number window ever appeared - this
  POS goes straight back to the floor plan after finishing. The step is
  now `Enter Random Slip Number If Prompted` (5 s wait).

### Run #3 - receipt: Discount mismatch (screen 149.00, database 0.00)

Total, subtotal and tax matched. On that bill the 149.00 is an item-level
discount (`SaleItem.AmountDiscount`); `Sale.DiscountAmount` (bill-level)
was 0. `Get Sale Financials` now returns item discounts + bill discount.
Checked across all 34,301 finalized sales in the DB: SubTotal + service
charge - discount + Tax = Total for 34,284. No sale in this DB has a
bill-level discount, so that half of the formula is untested.

### Run #4 - full suite 13 / 13 passed

All pending-first-run tags removed.

### Run #5 - receipt: Total read as "4" on a 7-line bill

The amount locators were positional (`path:"1|2|1|3|n"`). A UI tree
dump of RC6812230014 (7 lines) showed GridItems' children are
`Vertical` scrollbar / `Header Panel` / `Data Panel` / `Footer Panel`;
the scrollbar only exists on long bills, so on short bills `1|2|1|3` is
the footer but on long ones it is the Data Panel (and `|4` is "Row 4").
Runs #3-#4 passed only because the random bills were short.

Fix #11: footer cells are found by name under the footer -
`automationid:GridItems > name:"Footer Panel" > regex:<caption>` (Name is
caption + amount, e.g. "ยอดขาย2,683.56"; RPA.Windows `regex:` uses
`re.match`). Added `RECALL_SALE_NUM` so a bill can be re-run
(`.\run.ps1 -Tests tests/receipt -Variable RECALL_SALE_NUM:<num>`); passed on a
long bill (RC6812230014), a short one (ENT6901130008) and one with an
item discount (RC6802250001).

### Fix #12 - faster optional-popup checks in Flow 06

`Control Window` for a window that is NOT there took far longer than its
timeout: 16.4 s for the "Is in use" check (timeout 3) and 17.3 s for the
slip-number check (timeout 5) - it searches the whole desktop, once as
WindowControl and again as PaneControl. A probe showed POS dialogs
(DlgNumOfCust, the MessageBox) sit under the POS window, not at desktop
level, and a scoped `Get Element` answers in 0.07-0.4 s.

- After clicking the table, poll every 0.2 s for whichever comes first:
  the guest-count field (done) or the "Is in use" MessageBox (click Yes,
  keep polling). Open Dine In Table: 20.3 s -> 3.5 s.
- Slip-number prompt: same scoped polling for 5 s. 17.3 s -> 5.1 s.
  Then removed altogether (see below).
- Popup path verified for real: a helper run opened the table and killed
  the POS, leaving it in use; the next POS-DINEIN-001 hit the popup,
  clicked Yes within ~0.9 s and passed.

## Screens not yet inspected

Change-due payment (non-exact amount) in the payment dialog is not yet
inspected - reserved for POS-SALE-002 per docs/flows.md. If a locator is
needed for it, capture the screen with the uitree-inspector tool
(Export Tree / Export Locators) rather than guessing.

### Removed: the "slip number" step

The reference's `Print Random Slip` (window `regex:.*Printing`, field
`automationid:1001`, button `Save`) matches the Windows Save As dialog of
a print-to-file printer - this machine has "Microsoft Print to PDF" on
`PORTPROMPT:` - i.e. the "slip number" was a PDF file name for a printed
receipt, not a POS screen. It never appeared here and depends on printer
setup, so it was removed. Receipt printing can get its own test later.

## POS-SALE-002 / POS-E2E-002 - cash payment with change

Read from the POS source before writing the test: DlgPaymentW8 has no
separate change field - `txtBalance` = total due - paid, so overpaying
shows a negative balance; DlgAmount has keypad buttons `btnNum0-9`,
`btnPoint`, `btnClear`. In the DB, `Change` = `Tendered` - `Total`
(positive) on 6,529 of the 6,551 bills that have change.

First run: payment checks passed, then the test failed waiting for the
empty order screen - the screenshot showed a "เงินทอน" dialog (DlgChange:
`txtAmount`, `btnOK`) after the kitchen-print prompt. Added `Change Dialog
Should Show` (change on screen = tendered - total, then OK). Both tests
pass; RC6910300036: total 374.50, tendered 400, change 25.50 in the DB.

## Data-driven sale (POS-E2E-DD-01..03)

While choosing items for the data table: the quick-sale button
"<PRODUCT_B>" has no item of that name in `Items`; its sale is saved under
a different description. Items whose button text differs from the saved
name cannot be checked by name in the DB, so the table uses three items
whose names match. All three pass.

## Full run with 18 tests - two start-up failures, rerun option added

First full run with the new tests: 16 / 18. POS-E2E-001 - the POS window
never appeared within 60 s (screenshot: empty desktop); POS-E2E-DD-02 -
only two PIN digits registered and login failed. Both are in launch / login,
which passed in every earlier run, and both passed when rerun with
`robot --rerunfailed`. Added `run.ps1 -RerunFailed`: reruns only the failed
tests into `rerun/` and merges both runs into `merged/` (exit code = rerun
result), so a slow POS start is told apart from a real failure.

## Flow 03 - payment rules (POS-PAY-001, POS-PAY-002)

From the POS source: *Finish Sale* with a positive balance shows a MessageBox
"Payment is not valid, please check." (th-TH "การชำระเงินไม่ถูกต้อง
กรุณาตรวจสอบ", title "เตือน") and does not close the sale. Message text is
read from the MessageBox static control (`automationid:65535`).

The first plan was a split cash payment (half + rest). The run showed the
POS refuses a second cash payment: "การชำระเงินประเภทนี้มีอยู่แล้ว
กรุณาตรวจสอบ" (Payment type is already exist in payment list). That rule
became POS-PAY-002; a real split payment needs two different methods.

`id:DlgPaymentW8 > id:btnCancel` was not found after `Control Window` on the
payment dialog - the search already starts inside that dialog, so the cancel
button is just `id:btnCancel`. Both tests pass.
