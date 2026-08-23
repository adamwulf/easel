# easel

A Swift package and CLI tool for the [Canvas LMS API](https://developerdocs.instructure.com/services/canvas), built so AI agents (and humans) can read and update course content from the terminal: list courses, read and edit wiki pages and assignments, list people, and manage assignment rubrics.

An easel is the thing that holds a canvas.

## Install

Install with [Mint](https://github.com/yonaskolb/Mint):

```bash
mint install adamwulf/easel@main --force
```

Or build from a checkout:

```bash
swift build -c release
```

## Setup

`easel` needs two values:

| Key | Value |
| --- | --- |
| `CANVAS_API_KEY` | A Canvas access token. In Canvas: Account → Settings → Approved Integrations → **+ New Access Token**. |
| `CANVAS_HOST` | Your Canvas instance, like `school.instructure.com`. |

Put them in a `.env` file (in your project directory or any parent directory — `easel` walks up until it finds one), or export them as environment variables. Environment variables win over `.env` values, and `--host` wins over both.

```bash
# .env
CANVAS_API_KEY=1234~abcdefg...
CANVAS_HOST=school.instructure.com
```

One optional setting controls **anonymous mode**:

| Key | Value |
| --- | --- |
| `EASEL_ANONYMOUS` | Set it (`1`, `true`, `yes`, `on`) to redact student identities from output. Off by default; `0`, `false`, `no`, or `off` also mean off. |

It resolves like the others (`--anonymous`/`--no-anonymous` flag wins, then the environment, then `.env`). See [Anonymous mode](#anonymous-mode).

## Usage

All commands print JSON to stdout by default. Choose the shape with `--format`:

- `json` (default) — pretty-printed JSON: one object, or an array for a list.
- `jsonl` — one full JSON object per line.
- `smalljsonl` — one slim JSON object per line: just id/title plus a few key meta fields, for fetching ids and titles without the full-record bloat.
- `md` — human-readable Markdown: an `## Title (id)` heading and a labeled field list per record, with page/assignment bodies and rubric, enrollment, and criteria tables.
- `id` — just the ids, one per line (page url slugs for pages).

JSON field names match the Canvas API docs. Logs go to `~/Library/Logs/easel/`, never to stdout.

### Courses

```bash
easel courses                             # all your courses
easel courses --enrollment-type teacher   # only courses you teach
easel courses --state available           # only published courses
easel courses --format id                 # just the ids
```

### Pages

```bash
easel pages 101                           # list pages in course 101 (no bodies)
easel pages 101 --search syllabus         # filter by title
easel page 101 course-syllabus            # one page, with its HTML body
easel page 101 page_id:11                 # look up by id instead of slug

easel update-page 101 course-syllabus --title "Syllabus (Fall 2026)"
easel update-page 101 course-syllabus --body-file syllabus.html
cat syllabus.html | easel update-page 101 course-syllabus --body-file -
easel update-page 101 week-1-materials --published true       # publish / unpublish
easel update-page 101 week-1-materials --publish-at "2026-08-24T08:00:00-05:00"
```

`--publish-at` schedules a future publication date; it only takes effect when the Canvas account has the Scheduled Page Publication feature enabled. Pages have no unlock/lock availability dates in the Canvas API — those exist on assignments.

### Assignments

```bash
easel assignments 101                     # list assignments
easel assignments 101 --search portrait   # filter by title
easel assignment 101 501                  # one assignment, with description + rubric

easel update-assignment 101 501 --name "Self Portrait (Revised)"
easel update-assignment 101 501 --description-file brief.html
easel update-assignment 101 501 --points 120 --due-at "2026-09-12T23:59:00-05:00"
easel update-assignment 101 501 --published true              # publish / unpublish

# availability window: unlocks Aug 24, locks Sep 13
easel update-assignment 101 501 \
  --unlock-at "2026-08-24T00:00:00-05:00" \
  --lock-at "2026-09-13T23:59:00-05:00"
```

### Dates and time zones

Every date flag (`--due-at`, `--unlock-at`, `--lock-at`, `--publish-at`) takes a full ISO 8601 date-time **with an explicit time zone** — either an offset or `Z`:

```
2026-09-05T23:59:00-05:00     11:59 PM US Central (CDT)
2026-09-06T04:59:00Z          the same moment, in UTC
```

easel rejects values without a time zone before sending anything, because Canvas silently treats zone-less dates as UTC — which shifts the wall-clock time by hours. Canvas stores dates in UTC and returns them with a `Z` suffix, so a date you write with `-05:00` reads back as the equivalent `Z` time.

### People

```bash
easel users 101                           # everyone in the course
easel users 101 --enrollment-type student # students only
easel users 101 --search rivera           # search by name or login
easel users 101 --anonymous               # redact last names, emails, login ids
```

### Anonymous mode

When you need course data without exposing who's who — sharing output, feeding it
to another tool, filing a bug — turn on anonymous mode. Set `EASEL_ANONYMOUS`
(in the environment or `.env`) or pass `--anonymous` on any command; pass
`--no-anonymous` to force it off for a single run. It's **off by default**, so
normal output never changes.

With it on, every format (`json`, `jsonl`, `smalljsonl`, `md`; `id` is a numeric
id and is never a name) redacts the person fields on each user:

| Field | Redacted to |
| --- | --- |
| `name`, `short_name` | first 3 letters of the given name + surname initial — `Adam Wulf` → `Ada W` |
| `sortable_name` | surname initial + first 3 letters of the given name — `Wulf, Adam` → `W, Ada` |
| `email` | dropped (`null`, or absent from `smalljsonl`) |
| `login_id` | dropped (`null`, or absent from `smalljsonl`) |

Short and single-word names degrade gracefully: a given name under three letters
contributes only what it has (`Jo Smith` → `Jo S`), middle names are dropped
(`Mary Jane Watson` → `Mar W`), and a lone name keeps just its first three
letters (`Prince` → `Pri`). The numeric `id`, `sis_user_id`, `pronouns`, and
enrollments carry no name and pass through unchanged, so an agent can still
cross-reference a person by id. Only the `users` command emits personal data
today, so it's the only output anonymous mode affects.

### Rubrics

```bash
easel rubrics 101                         # list rubrics in course 101
easel rubric 101 9                        # one rubric, with criteria + ratings

easel create-rubric 101 --assignment 501 --file rubric.json
easel update-rubric 101 9 --file rubric.json
easel update-rubric 101 9 --file rubric.json --assignment 502
```

The rubric JSON file uses plain arrays (easel converts to the indexed-hash form Canvas expects):

```json
{
  "title": "Essay Rubric",
  "free_form_criterion_comments": false,
  "criteria": [
    {
      "description": "Thesis",
      "long_description": "A clear, arguable thesis.",
      "points": 5,
      "ratings": [
        { "description": "Excellent", "points": 5 },
        { "description": "Adequate", "points": 3 },
        { "description": "Missing", "points": 0 }
      ]
    }
  ]
}
```

By default a created rubric is used for grading; pass `--no-use-for-grading` to attach it as a reference only.

## The EaselKit library

All logic lives in the `EaselKit` library product, so other tools can depend on it directly:

```swift
.package(url: "https://github.com/adamwulf/easel.git", branch: "main")
// product: "EaselKit"
```

```swift
import EaselKit

let config = try CanvasConfig.resolve()
let client = CanvasClient(config: config)
let courses = try await client.courses(enrollmentType: "teacher")
```

The network layer sits behind the `HTTPTransport` protocol, so tests (yours too) can inject static JSON responses and run offline — see `Tests/EaselKitTests/Support/StubTransport.swift`.

## Development

```bash
swift build          # build
swift test           # run all tests (offline; no API key needed)
```

See `CLAUDE.md` for the architecture and how to add new endpoints.

## References

- [Canvas LMS API documentation](https://developerdocs.instructure.com/services/canvas)
- Logging via [FellerBuncher](https://github.com/adamwulf/FellerBuncher)
