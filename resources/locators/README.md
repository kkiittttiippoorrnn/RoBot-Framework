# Locators

Windows UI Automation selectors (control name/AutomationId/class, as
supported by `RPA.Windows`), kept as Robot Framework variable files
separate from keywords and test cases. One file per screen.

Every value in here must come from actually inspecting the running
application (e.g. via Accessibility Insights / Inspect.exe, or an exported
UI-Automation tree) — never guessed. `login_screen.resource` is the first
one; see `docs/inspection-log.md` for the source inspection it came from.
