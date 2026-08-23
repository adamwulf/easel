# CLAUDE.md

## What this is

`easel` is a Swift package + CLI for the Canvas LMS API, built for AI agents that manage courses: list courses, read/update wiki pages and assignments, list people, and create/update assignment rubrics. The architecture mirrors the `hunch` (Notion) and `cirqueduci` (CircleCI) CLIs: a fat reusable library, a thin executable.

## Build and test

```bash
swift build                       # build everything
swift test                        # run all tests — fully offline, no API key needed
swift test --filter RubricsTests  # one suite
swift run easel --help            # run the CLI
```

Tests never touch the network: every client test injects `StubTransport` with static JSON fixtures. Keep it that way. Keep warnings at zero — the package uses Swift 6 language mode with strict concurrency, so follow the compiler.

**Never read a real `.env` file or print `CANVAS_API_KEY`.** Tests must always pass an explicit `startingIn` directory to `DotEnv`/`CanvasConfig.resolve` (a temp dir) so the walk-up never reaches a real `.env`. Never run live commands like `swift run easel courses` from inside this repo for the same reason.

## Repository structure

```
Package.swift               swift-tools 6.0; products: EaselKit (library), easel (executable)
Sources/
  EaselKit/                 ALL business logic (reusable library)
    APIs/
      CanvasAPI.swift       low-level: auth header, retry/backoff, error mapping, decode, ONE page per call
      CanvasClient.swift    high-level facade: fetchAll pagination loop; commands only talk to this
      CanvasClient+*.swift  one file per resource (Courses, Pages, Assignments, Users, Rubrics)
    HTTP/
      HTTPTransport.swift   HTTPRequest/HTTPResponse + HTTPTransport protocol + URLSessionTransport
      LinkHeader.swift      parses rel="next" from Canvas Link headers
    Models/                 Codable models w/ explicit snake_case CodingKeys (+ *Update / RubricDraft inputs)
    Helpers/
      CanvasJSON.swift      decoder/encoder factories (tolerant ISO 8601 dates)
      OutputFormatter.swift CanvasRow protocol + json/jsonl/smalljsonl/md/id rendering
      SummaryRow.swift      JSONScalar + SummaryRow: the flat id/title/meta subset for smalljsonl
      Markdown.swift        Markdown helpers (heading/field/table/escaping) for the md format
    CanvasConfig.swift      resolves CANVAS_API_KEY + CANVAS_HOST (arg > env > .env walk-up); resolveAnonymous for EASEL_ANONYMOUS
    CanvasError.swift       the only error type EaselKit throws
    DotEnv.swift            .env parser + parent-directory walk
  easel/                    ONLY CLI concerns
    Easel.swift             @main root; bootstraps logging, parses, runs, drains logs; emit() helper
    EaselLog.swift          FellerBuncher bootstrap -> ~/Library/Logs/easel, console .none
    GlobalOptions.swift     --host, --format, --anonymous; makeClient(), isAnonymous
    FileInput.swift         file-or-stdin reading for --body-file etc.
    Commands/               one file per subcommand, all thin: parse -> client call -> emit
Tests/
  EaselKitTests/            library tests; Support/ has StubTransport (actor) + Fixtures (JSON strings)
  CLITests/                 argument-parsing tests only (@testable import easel)
```

## Architecture rules

- **All logic in EaselKit; the executable stays thin.** A command parses flags, calls one `CanvasClient` method, and hands the result to `Easel.emit`. If a command needs more than that, the logic belongs in the library.
- **Two client layers.** `CanvasAPI` handles one request: Bearer auth, retry (3 attempts on 429/5xx and transport errors, linear backoff, injectable delay), status→`CanvasError` mapping, decode. `CanvasClient` composes requests: pagination lives ONLY in `CanvasClient.fetchAll`, which follows `Link: rel="next"` headers.
- **The transport is the only network seam.** `HTTPTransport` is a protocol; `URLSessionTransport` is production, `StubTransport` (an actor, in test support) is tests. Nothing else may touch URLSession.
- **Explicit CodingKeys, no key-conversion strategy.** Model fields keep Canvas's snake_case names in JSON so CLI output matches the Canvas docs. Optionals everywhere except true invariants (ids, page url) so decoding tolerates instance differences.
- **Write bodies omit nil fields** (synthesized Encodable uses encodeIfPresent), so partial updates leave other fields untouched.
- **Rubric bodies use indexed hashes.** Canvas's Rails controllers expect `rubric[criteria]` (and each criterion's `ratings`) keyed `"0", "1", ...` — `RubricBody` converts the array-based `RubricDraft` into that shape. Don't "fix" this to plain JSON arrays; Canvas ignores them.
- **Logging:** EaselKit only uses swift-log (`Logger(label: "easel.api")`) and never imports FellerBuncher; the executable bootstraps FellerBuncher once in `main()` (console `.none`) and drains before exit. stdout is reserved for command output. Never log the token.

## Adding a new endpoint

1. Check the [Canvas API docs](https://developerdocs.instructure.com/services/canvas) for the path, params, and response shape.
2. Add/extend a model in `Sources/EaselKit/Models/` (explicit snake_case CodingKeys, optional fields, conform to `CanvasRow` if it will be listed). `CanvasRow` requires `rowID`, `summaryRow` (a `SummaryRow` of the flat id/title/meta subset for `smalljsonl`), and `markdownRow` (the `md` rendering, built with the `Markdown` helpers).
3. Add a method in the matching `CanvasClient+<Resource>.swift` — `fetchAll` for lists, `api.get/put/post` for single objects.
4. Add a fixture (static JSON string, realistic Canvas shape) in `Tests/EaselKitTests/Support/Fixtures.swift` and a test that stubs the route, asserts decoded fields, and (for writes) asserts the recorded request method/body.
5. Add a thin command file in `Sources/easel/Commands/`, register it in `Easel.configuration.subcommands`, and update the count + add a parse test in `Tests/CLITests/ParsingTests.swift`.
6. Document it in `README.md`.

## Conventions

- Config resolution order: explicit flag → process environment → nearest `.env` walking up parent directories (closest wins). Keys: `CANVAS_API_KEY`, `CANVAS_HOST`, `EASEL_ANONYMOUS`.
- Every command takes `--format json|jsonl|smalljsonl|md|id` (default `json`) via `GlobalOptions` and prints via `Easel.emit`. Each `CanvasRow` model supplies its own `summaryRow` (the flat id/title/meta subset for `smalljsonl`) and `markdownRow` (the `md` rendering); `json`/`jsonl` use `Codable` directly.
- **Anonymous mode** (`EASEL_ANONYMOUS` / `--anonymous`/`--no-anonymous`, resolved via `CanvasConfig.resolveAnonymous`; off by default) redacts user-identifying data. Redaction is a model transform in EaselKit — `CourseUser.anonymized()`: names become the first 3 letters of the given name + surname initial (`Adam Wulf` → `Ada W`, graceful for short/single-word names), and `email`/`login_id` are set to `nil`. It's applied in the command before `emit`, so it covers every format at once. `CanvasConfig` itself stays the pure token+host value the network layer needs; anonymous is a presentation concern resolved separately with the same `.env` machinery. If a future model gains names/emails, give it an `anonymized()` and apply it in its command.
- Commands that change things validate that at least one change flag was given (`validate()`), and `--x` / `--x-file` pairs are mutually exclusive; `-` means stdin.
- Date flags (`--due-at`, `--unlock-at`, `--lock-at`, `--publish-at`) require full ISO 8601 with an explicit time zone; `ISODateFlag.validate` rejects zone-less values in `validate()` because Canvas silently treats them as UTC. Dates in write bodies stay `String` (passed through verbatim), never `Date`.
- Commit style: plain descriptive messages; don't squash history.
