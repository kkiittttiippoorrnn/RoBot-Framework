# Test Data

Static, non-secret test data used by the flows (e.g. item names/SKUs,
discount codes, expected price lists) kept separate from automation logic.
Anything environment-specific or secret (URLs, credentials, DB connection
strings) belongs in environment variables / `.env`, not here — see
`resources/variables/environment.py`.

`menu.py` holds the menu items / menu paths and guest count the sales,
end-to-end and dine-in suites use (imported with `Variables`).
