# Evidence

Run output goes here: Robot Framework's `log.html` / `report.html` /
`output.xml`, screenshots captured on failure, and any captured transaction
identifiers or DB query results useful for diagnosing a failing run.

Contents are generated per run and are git-ignored (this README is the only
tracked file in this folder). Run with, e.g.:

```
robot --outputdir evidence tests/flow-a
```
