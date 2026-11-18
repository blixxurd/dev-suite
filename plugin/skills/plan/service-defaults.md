# Defaults for a long-running service

Each row is a principle that holds for every project and, beside it, the default that meets it when the project is a service that stays running.

- **A service:** use the right-hand column. Leaving a default is a decision, so it goes in the plan's Decisions with its reason.
- **Any other kind of project:** the left-hand column still holds. Work out what meets each principle for this kind and put the answers in the plan's Assumptions, as a table with one row for each row here. "No equivalent", with why, is an answer. They are then approved with the plan.

The plan is how these reach the rest of the build. The stack table, the walking skeleton's "done when", the Makefile targets and the ship checklist are written from this file, and the other skills read only the plan.

| Principle | Default for a service |
|---|---|
| It builds from a fresh clone into a portable artifact | A Docker image, built in stages on a slim base image, that runs as a non-root user and declares its health check. A compose file runs it locally |
| Anyone can tell whether it is up | A health-check endpoint that answers without calling anything slow or external |
| Configuration lives outside the code and is read in one place | Twelve-factor config: environment variables, read and validated once in a config module that stops the process at startup on a missing or bad value. No other code reads the environment, and `.env.example` lists every variable |
| What it did can be followed afterwards | JSON logs: one object per line on stdout, written through one log function |
| Every failure leaves by one path and looks the same from outside | One error handler at the edge, where requests arrive. Code throws typed errors and never catches in order to respond. Every error has one shape, and an unexpected one is logged with its stack and answered without its message |
| Stages are split by concern, with I/O at the edges | Controller, service, repository. Controllers turn requests into values and results into responses, services hold the logic, and repositories are the only code that touches storage |
| A unit is small enough to read in one go | Functions of about 40 lines and files of about 200, counted by the linter |
| The process holds nothing it can't lose | State lives in a backing store named in the config. The process binds the port it is given and shuts down cleanly when told to stop |
| One command for each thing people do with the repo | Two Makefile targets beyond the standard ones: `dev` runs it with reload, and `docker-up` builds the image and runs it |
| The first code commit already runs end to end | The walking skeleton starts from its validated config, logs JSON, has the one error path and the health check, runs in Docker, and passes `make check` with one real test |
| Slow checks run at review and ship, not on every commit | From a fresh clone, the image builds, the container starts as a non-root user, and its health check answers |
