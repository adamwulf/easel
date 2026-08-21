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

## Usage

All commands print JSON to stdout by default. `--format jsonl` prints one object per line; `--format id` prints only ids (page url slugs for pages). Field names match the Canvas API docs. Logs go to `~/Library/Logs/easel/`, never to stdout.

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
easel update-page 101 week-1-materials --published true
```

### Assignments

```bash
easel assignments 101                     # list assignments
easel assignments 101 --search portrait   # filter by title
easel assignment 101 501                  # one assignment, with description + rubric

easel update-assignment 101 501 --name "Self Portrait (Revised)"
easel update-assignment 101 501 --description-file brief.html
easel update-assignment 101 501 --points 120 --due-at "2026-09-12T23:59:00-05:00"
easel update-assignment 101 501 --published true
```

### People

```bash
easel users 101                           # everyone in the course
easel users 101 --enrollment-type student # students only
easel users 101 --search rivera           # search by name or login
```

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
