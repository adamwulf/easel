/// Static JSON fixtures mirroring real Canvas API response shapes. Tests
/// inject these through `StubTransport`, so nothing touches the network.
enum Fixtures {
    // MARK: - Courses

    static let coursesPage1 = """
    [
      {
        "id": 101,
        "name": "Intro to Drawing",
        "course_code": "ART-101",
        "workflow_state": "available",
        "account_id": 7,
        "enrollment_term_id": 5,
        "start_at": "2026-08-24T06:00:00Z",
        "end_at": null,
        "default_view": "wiki",
        "total_students": 18
      },
      {
        "id": 102,
        "name": "Advanced Painting",
        "course_code": "ART-401",
        "workflow_state": "unpublished",
        "account_id": 7,
        "enrollment_term_id": 5,
        "start_at": "2026-08-24T06:00:00-05:00"
      }
    ]
    """

    static let coursesPage2 = """
    [
      {
        "id": 103,
        "name": "Color Theory",
        "course_code": "ART-210",
        "workflow_state": "available"
      }
    ]
    """

    // MARK: - Pages

    static let pagesList = """
    [
      {
        "page_id": 11,
        "url": "course-syllabus",
        "title": "Course Syllabus",
        "published": true,
        "front_page": false,
        "editing_roles": "teachers",
        "locked_for_user": false,
        "created_at": "2026-08-01T12:00:00Z",
        "updated_at": "2026-08-15T09:30:00Z"
      },
      {
        "page_id": 12,
        "url": "week-1-materials",
        "title": "Week 1 Materials",
        "published": false,
        "front_page": false
      }
    ]
    """

    static let pageShow = """
    {
      "page_id": 11,
      "url": "course-syllabus",
      "title": "Course Syllabus",
      "body": "<h2>Welcome</h2><p>Bring a sketchbook to every class.</p>",
      "published": true,
      "front_page": false,
      "editing_roles": "teachers",
      "locked_for_user": false,
      "created_at": "2026-08-01T12:00:00Z",
      "updated_at": "2026-08-15T09:30:00Z"
    }
    """

    static let pageCreated = """
    {
      "page_id": 13,
      "url": "week-2-materials",
      "title": "Week 2 Materials",
      "body": "<h2>Week 2</h2><p>Read before class.</p>",
      "published": false,
      "publish_at": "2026-08-31T13:00:00Z",
      "front_page": false,
      "editing_roles": "teachers,students",
      "locked_for_user": false,
      "created_at": "2026-08-23T15:00:00Z",
      "updated_at": "2026-08-23T15:00:00Z"
    }
    """

    static let pageUpdated = """
    {
      "page_id": 11,
      "url": "course-syllabus",
      "title": "Syllabus (Fall 2026)",
      "body": "<h2>Welcome</h2><p>Updated for fall.</p>",
      "published": true,
      "front_page": false,
      "updated_at": "2026-08-20T10:00:00Z"
    }
    """

    // MARK: - Assignments

    static let assignmentsList = """
    [
      {
        "id": 501,
        "name": "Self Portrait",
        "due_at": "2026-09-05T04:59:59Z",
        "points_possible": 100.0,
        "published": true,
        "html_url": "https://example.instructure.com/courses/101/assignments/501",
        "submission_types": ["online_upload"],
        "course_id": 101,
        "assignment_group_id": 3,
        "grading_type": "points"
      },
      {
        "id": 502,
        "name": "Gesture Studies",
        "due_at": null,
        "points_possible": 50.0,
        "published": false,
        "submission_types": ["online_upload", "online_text_entry"],
        "course_id": 101
      }
    ]
    """

    static let assignmentShow = """
    {
      "id": 501,
      "name": "Self Portrait",
      "description": "<p>Draw yourself in charcoal.</p>",
      "due_at": "2026-09-05T04:59:59Z",
      "unlock_at": "2026-08-24T06:00:00Z",
      "lock_at": "2026-09-12T04:59:59Z",
      "points_possible": 100.0,
      "published": true,
      "html_url": "https://example.instructure.com/courses/101/assignments/501",
      "submission_types": ["online_upload"],
      "course_id": 101,
      "grading_type": "points",
      "rubric": [
        {
          "id": "_10",
          "description": "Likeness",
          "long_description": "How closely the portrait resembles the artist.",
          "points": 60.0,
          "criterion_use_range": false,
          "ratings": [
            { "id": "_11", "description": "Strong", "points": 60.0 },
            { "id": "_12", "description": "Developing", "points": 30.0 }
          ]
        }
      ],
      "rubric_settings": {
        "id": 9,
        "title": "Portrait Rubric",
        "points_possible": 100.0,
        "free_form_criterion_comments": false,
        "hide_score_total": false
      }
    }
    """

    static let assignmentUpdated = """
    {
      "id": 501,
      "name": "Self Portrait (Revised)",
      "description": "<p>Draw yourself in charcoal or ink.</p>",
      "due_at": "2026-09-12T04:59:59Z",
      "points_possible": 120.0,
      "published": true,
      "course_id": 101
    }
    """

    // MARK: - Users

    static let usersList = """
    [
      {
        "id": 9001,
        "name": "Alex Rivera",
        "sortable_name": "Rivera, Alex",
        "short_name": "Alex",
        "sis_user_id": "S0001",
        "login_id": "arivera",
        "email": "arivera@example.edu",
        "pronouns": "they/them",
        "enrollments": [
          {
            "type": "StudentEnrollment",
            "role": "StudentEnrollment",
            "enrollment_state": "active",
            "course_section_id": 42
          }
        ]
      },
      {
        "id": 9002,
        "name": "Sam Chen",
        "sortable_name": "Chen, Sam",
        "login_id": "schen",
        "enrollments": [
          {
            "type": "TeacherEnrollment",
            "role": "TeacherEnrollment",
            "enrollment_state": "active"
          }
        ]
      }
    ]
    """

    // MARK: - Rubrics

    static let rubricsList = """
    [
      {
        "id": 9,
        "title": "Portrait Rubric",
        "context_id": 101,
        "context_type": "Course",
        "points_possible": 100.0,
        "free_form_criterion_comments": false,
        "read_only": false,
        "reusable": false
      }
    ]
    """

    static let rubricShow = """
    {
      "id": 9,
      "title": "Portrait Rubric",
      "context_id": 101,
      "context_type": "Course",
      "points_possible": 100.0,
      "free_form_criterion_comments": false,
      "data": [
        {
          "id": "_10",
          "description": "Likeness",
          "points": 60.0,
          "criterion_use_range": false,
          "ratings": [
            { "id": "_11", "description": "Strong", "points": 60.0 },
            { "id": "_12", "description": "Developing", "points": 30.0 }
          ]
        },
        {
          "id": "_20",
          "description": "Craft",
          "points": 40.0,
          "ratings": [
            { "id": "_21", "description": "Clean", "points": 40.0 },
            { "id": "_22", "description": "Rough", "points": 15.0 }
          ]
        }
      ]
    }
    """

    static let rubricCreateResponse = """
    {
      "rubric": {
        "id": 10,
        "title": "Essay Rubric",
        "context_id": 101,
        "context_type": "Course",
        "points_possible": 5.0,
        "free_form_criterion_comments": false,
        "data": [
          {
            "id": "_1",
            "description": "Thesis",
            "long_description": "A clear, arguable thesis.",
            "points": 5.0,
            "ratings": [
              { "id": "_2", "description": "Excellent", "points": 5.0 },
              { "id": "_3", "description": "Adequate", "points": 3.0 },
              { "id": "_4", "description": "Missing", "points": 0.0 }
            ]
          }
        ]
      },
      "rubric_association": {
        "id": 77,
        "rubric_id": 10,
        "association_id": 501,
        "association_type": "Assignment",
        "use_for_grading": true,
        "purpose": "grading",
        "hide_score_total": false
      }
    }
    """

    static let rubricBareResponse = """
    {
      "id": 10,
      "title": "Essay Rubric",
      "context_id": 101,
      "context_type": "Course",
      "points_possible": 5.0
    }
    """

    // MARK: - Errors

    static let error401 = """
    { "errors": [ { "message": "Invalid access token." } ] }
    """

    static let error404 = """
    { "errors": [ { "message": "The specified resource does not exist." } ] }
    """

    static let error500 = """
    { "errors": [ { "message": "An error occurred." } ] }
    """

    // MARK: - Rubric draft input (the shape agents author)

    static let rubricDraftJSON = """
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
        },
        {
          "description": "Evidence",
          "points": 10,
          "ratings": [
            { "description": "Strong", "points": 10 },
            { "description": "Weak", "points": 4 }
          ]
        }
      ]
    }
    """
}
