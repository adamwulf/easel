# easel

A Swift package and CLI tool for the [Canvas LMS API](https://developerdocs.instructure.com/services/canvas), built so AI agents (and humans) can manage course content from the terminal: list courses, create/read/update/delete wiki pages and assignments, list people, list assignment submissions, and create/read/update/delete assignment rubrics.

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

It's one-way: anonymous mode is on when `EASEL_ANONYMOUS` is truthy in the environment or `.env` **or** when `--anonymous` is passed. A truthy env value can't be turned off — there is no override flag — so it's a hard privacy guarantee. See [Anonymous mode](#anonymous-mode).

## Usage

All commands print JSON to stdout by default. Choose the shape with `--format`:

- `json` (default) — pretty-printed JSON: one object, or an array for a list.
- `jsonl` — one full JSON object per line.
- `smalljsonl` — one slim JSON object per line: just id/title plus a few key meta fields, for fetching ids and titles without the full-record bloat.
- `md` — human-readable Markdown: an `## Title (id)` heading and a labeled field list per record, with page/assignment bodies and rubric, enrollment, and criteria tables.
- `id` — just the ids, one per line (page url slugs for pages, student user ids for submissions).

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

easel create-page 101 --title "Week 2 Materials" --body-file week-2.html
easel create-page 101 --title "Course Home" --published true --front-page true
cat week-2.html | easel create-page 101 --title "Week 2 Materials" --body-file -

easel update-page 101 course-syllabus --title "Syllabus (Fall 2026)"
easel update-page 101 course-syllabus --body-file syllabus.html
cat syllabus.html | easel update-page 101 course-syllabus --body-file -
easel update-page 101 week-1-materials --published true       # publish / unpublish
easel update-page 101 week-1-materials --publish-at "2026-08-24T08:00:00-05:00"

easel delete-page 101 obsolete-page
easel delete-page 101 page_id:11
```

`--publish-at` schedules a future publication date; it only takes effect when the Canvas account has the Scheduled Page Publication feature enabled. Pages have no unlock/lock availability dates in the Canvas API — those exist on assignments.

### Assignments

```bash
easel assignments 101                     # list assignments
easel assignments 101 --search portrait   # filter by title
easel assignment 101 501                  # one assignment, with description + rubric

easel create-assignment 101 --name "Value Study" --description-file brief.html
easel create-assignment 101 --name "Value Study" --points 75 --due-at "2026-09-19T23:59:59-05:00"

easel update-assignment 101 501 --name "Self Portrait (Revised)"
easel update-assignment 101 501 --description-file brief.html
easel update-assignment 101 501 --points 120 --due-at "2026-09-12T23:59:00-05:00"
easel update-assignment 101 501 --published true              # publish / unpublish

# availability window: unlocks Aug 24, locks Sep 13
easel update-assignment 101 501 \
  --unlock-at "2026-08-24T00:00:00-05:00" \
  --lock-at "2026-09-13T23:59:00-05:00"

easel delete-assignment 101 502
```

### Dates and time zones

Every date flag (`--due-at`, `--unlock-at`, `--lock-at`, `--publish-at`) takes a full ISO 8601 date-time **with an explicit time zone** — either an offset or `Z`:

```
2026-09-05T23:59:00-05:00     11:59 PM US Central (CDT)
2026-09-06T04:59:00Z          the same moment, in UTC
```

easel rejects values without a time zone before sending anything, because Canvas silently treats zone-less dates as UTC — which shifts the wall-clock time by hours. Canvas stores dates in UTC and returns them with a `Z` suffix, so a date you write with `-05:00` reads back as the equivalent `Z` time.

### Submissions

```bash
easel submissions 101                                        # every published assignment, every status
easel submissions 101 --assignment 501 --state not-submitted # who has not turned in 501
easel submissions 101 --state needs-grading --format smalljsonl  # ungraded work; group by assignment_id
easel submissions 101 --assignment 501 --assignment 502      # repeat --assignment for more
easel submissions 101 --assignment 501 --state not-submitted --format id  # just their user ids
```

Each row is one active student's submission for one published assignment; students with concluded or inactive enrollments are left out. Canvas keeps a submission row for every student an assignment is assigned to, turned in or not. Unpublished assignments have no student submissions, and Canvas answers `--assignment` with an unpublished id with a 403 ("invalid assignment ids requested").

`--state` filters by easel's own status, not Canvas's `workflow_state`, because no `workflow_state` answers "who hasn't turned it in": Canvas marks missing work `graded` once a teacher enters a 0 or the late policy grades it automatically, and it marks excused students `graded` too. Every submission has exactly one status, checked in this order:

| `--state` | Meaning (Canvas fields) |
| --- | --- |
| `excused` | `excused` is true, whatever else is set. |
| `not-submitted` | `submitted_at` is null — nothing turned in, even if the missing work has a grade. |
| `needs-grading` | Canvas's own rule, the one behind its "needs grading" count: `submission_type` is set, and `workflow_state` is `pending_review`, or is `submitted`/`graded` with a null `score` or `"grade_matches_current_submission": false`. That covers a new submission, a resubmission after grading (old score, grade no longer matches), and a grade the teacher cleared. |
| `graded` | Turned in and graded for the current attempt. |

Omit `--state` for every status. Canvas has no filter for these statuses, so easel always asks Canvas for every submission and filters them itself. On-paper and no-submission assignments have nothing turned in online, so every student who isn't excused is `not-submitted` there.

`--format id` prints one student user id per row, so give it a single `--assignment`; across several assignments the ids repeat with no assignment to tell them apart — use `smalljsonl`, which includes `assignment_id`.

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
(in the environment or `.env`) or pass `--anonymous` on any command. It's
**off by default**, so normal output never changes.

Anonymous mode is **one-way**: `anonymous = --anonymous OR EASEL_ANONYMOUS-truthy`.
The flag can only turn it on, and there is no `--no-anonymous`. Once a truthy
`EASEL_ANONYMOUS` is in the environment or `.env`, nothing on the command line
can bypass redaction — so an agent running the CLI can't leak identities past a
policy the env var sets.

With it on, every format (`json`, `jsonl`, `smalljsonl`, `md`; `id` is a numeric
id and is never a name) redacts the person fields on each user — the people
from `users` and the student embedded in each `submissions` row:

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
cross-reference a person by id. Only the `users` and `submissions` commands emit
personal data today, so they're the only output anonymous mode affects.

### Rubrics

```bash
easel rubrics 101                         # list rubrics in course 101
easel rubric 101 9                        # one rubric, with criteria + ratings

easel create-rubric 101 --assignment 501 --file rubric.json
easel update-rubric 101 9 --file rubric.json
easel update-rubric 101 9 --file rubric.json --assignment 502
easel delete-rubric 101 9
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
