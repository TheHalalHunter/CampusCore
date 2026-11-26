# CampusCore API Documentation

**Base URL:** `https://api.campuscore.ng/api/v1`  
**Dev URL:** `http://localhost:3000/api/v1`  
**Version:** 1.0 | **Auth:** Bearer JWT

> Interactive docs available at `/api/docs` (Swagger UI) when running in development.

---

## Authentication

All protected endpoints require:
```
Authorization: Bearer <access_token>
```

Access tokens expire in **7 days**. Use the refresh endpoint to get a new one.

---

## Endpoints

### Auth

| Method | Endpoint         | Auth | Description                                      |
|--------|------------------|------|--------------------------------------------------|
| POST   | `/auth/login`    | No   | Login or register via Firebase ID token          |
| POST   | `/auth/refresh`  | No   | Get a new access token using a refresh token     |

#### POST `/auth/login`
```json
// Request
{
  "idToken": "firebase_id_token_string",
  "fullName": "Adebayo Musa",          // required on first sign-up
  "departmentId": "uuid",              // optional
  "academicLevel": "200L"              // optional
}

// Response 200
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "isNewUser": false,
    "user": { "id": "uuid", "email": "...", "fullName": "...", "role": "student" }
  }
}
```

---

### Users

| Method | Endpoint              | Auth    | Description                    |
|--------|-----------------------|---------|--------------------------------|
| GET    | `/users/me`           | Student | Get current user profile       |
| PATCH  | `/users/me`           | Student | Update current user profile    |
| GET    | `/users/:id/profile`  | Student | Get public profile of any user |

#### PATCH `/users/me`
```json
// Request (all fields optional)
{
  "fullName": "Adebayo Musa",
  "avatar": "https://storage.../avatar.jpg",
  "phone": "+2348012345678",
  "academicLevel": "200L",
  "matricNumber": "LAU/2022/0042"
}
```

---

### Departments

| Method | Endpoint           | Auth  | Description                       |
|--------|--------------------|-------|-----------------------------------|
| GET    | `/departments`     | No    | List all active departments       |
| GET    | `/departments/:id` | No    | Get a department by ID            |
| POST   | `/departments`     | Admin | Create a new department           |
| PATCH  | `/departments/:id` | Admin | Update a department               |

---

### Courses

| Method | Endpoint        | Auth  | Description                                       |
|--------|-----------------|-------|---------------------------------------------------|
| GET    | `/courses`      | No    | List courses (`?departmentId=&level=`)            |
| GET    | `/courses/:id`  | No    | Get course details                                |
| POST   | `/courses`      | Admin | Create a course                                   |
| PATCH  | `/courses/:id`  | Admin | Update a course                                   |

#### GET `/courses?departmentId=uuid&level=200L`
```json
// Response 200
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "title": "Fish Nutrition",
      "courseCode": "AQU 201",
      "academicLevel": "200L",
      "semester": 1,
      "creditUnits": 2
    }
  ]
}
```

---

### Resources

| Method | Endpoint                       | Auth           | Description                            |
|--------|--------------------------------|----------------|----------------------------------------|
| GET    | `/resources?courseId=uuid`     | No             | List approved resources for a course   |
| GET    | `/resources/:id`               | No             | Get a resource by ID                   |
| POST   | `/resources`                   | Student        | Submit a resource for review           |
| POST   | `/resources/:id/download`      | Student        | Increment download count               |
| GET    | `/resources/moderation/pending`| Mod / Admin    | List pending submissions               |
| PATCH  | `/resources/:id/review`        | Mod / Admin    | Approve or reject a submission         |

#### POST `/resources` — Submit
```json
// Request
{
  "title": "AQU 201 Lecture Notes — Week 3",
  "description": "Covers protein requirements",
  "fileUrl": "https://storage.firebase.../file.pdf",
  "fileType": "pdf",
  "fileSize": 2457600,
  "type": "lecture_note",
  "courseId": "uuid",
  "academicYear": "2025/2026"
}
```

#### PATCH `/resources/:id/review`
```json
// Request
{
  "status": "approved",   // or "rejected"
  "reviewNote": "Great quality, well formatted."
}
```

---

### Community

| Method | Endpoint                                     | Auth           | Description                        |
|--------|----------------------------------------------|----------------|------------------------------------|
| GET    | `/community/questions`                        | Student        | List questions (filter by dept/level/course) |
| GET    | `/community/questions/:id`                   | Student        | Get question + answers             |
| POST   | `/community/questions`                        | Student        | Post a new question                |
| POST   | `/community/questions/:id/answers`            | Student        | Answer a question                  |
| PATCH  | `/community/questions/:id/resolve`            | Author         | Mark question as resolved          |
| PATCH  | `/community/answers/:id/verify`               | Mod / Admin    | Verify an answer as correct        |
| POST   | `/community/flag/:type/:id`                   | Student        | Flag a question or answer          |

#### POST `/community/questions`
```json
// Request
{
  "title": "What is the optimal feeding frequency for Clarias gariepinus?",
  "body": "I feed twice daily but some papers suggest 3 times...",
  "courseId": "uuid",
  "departmentId": "uuid",
  "academicLevel": "200L",
  "tags": ["fish nutrition", "feeding"]
}
```

---

### AI Study Assistant

| Method | Endpoint              | Auth    | Description                          |
|--------|-----------------------|---------|--------------------------------------|
| POST   | `/ai/explain`         | Student | Explain a concept                    |
| POST   | `/ai/quiz`            | Student | Generate MCQ quiz on a topic         |
| POST   | `/ai/summarize`       | Student | Summarize a passage                  |
| POST   | `/ai/flashcards`      | Student | Generate flashcards for a topic      |
| POST   | `/ai/predict-topics`  | Student | Predict likely exam topics           |

#### POST `/ai/explain`
```json
// Request
{ "concept": "nitrogen cycle in aquaculture", "courseContext": "Aquatic Ecology" }

// Response 200
{ "success": true, "data": "The nitrogen cycle in aquaculture refers to..." }
```

#### POST `/ai/quiz`
```json
// Request
{ "topic": "protein requirements in fish feed", "count": 5 }

// Response 200
{
  "success": true,
  "data": [
    {
      "question": "What is the recommended crude protein level for tilapia grow-out?",
      "options": ["20–25%", "28–32%", "35–40%", "45–50%"],
      "correctAnswer": 1,
      "explanation": "Tilapia require 28–32% crude protein during grow-out..."
    }
  ]
}
```

---

### Progress

| Method | Endpoint                                           | Auth    | Description                         |
|--------|----------------------------------------------------|---------|-------------------------------------|
| GET    | `/progress/courses/:courseId`                      | Student | Get course progress                 |
| POST   | `/progress/courses/:courseId/topics/:topicId/complete` | Student | Mark topic complete             |
| DELETE | `/progress/courses/:courseId/topics/:topicId/complete` | Student | Unmark topic                   |
| GET    | `/progress/semester?courseIds=id1,id2`             | Student | Overall semester progress           |

#### GET `/progress/courses/:courseId` — Response
```json
{
  "success": true,
  "data": {
    "completedCount": 5,
    "totalCount": 12,
    "percentage": 42,
    "topics": [
      { "topicId": "t1", "topicTitle": "Introduction", "isCompleted": true, "completedAt": "2026-07-10T..." }
    ]
  }
}
```

---

### Notifications

| Method | Endpoint                    | Auth    | Description                    |
|--------|-----------------------------|---------|--------------------------------|
| GET    | `/notifications`            | Student | Get user notifications (last 50)|
| GET    | `/notifications/unread-count`| Student | Get unread count               |
| PATCH  | `/notifications/:id/read`   | Student | Mark one as read               |
| PATCH  | `/notifications/read-all`   | Student | Mark all as read               |

---

### Gamification

| Method | Endpoint                      | Auth    | Description                 |
|--------|-------------------------------|---------|-----------------------------|
| GET    | `/gamification/badges/me`     | Student | Get my earned badges        |
| GET    | `/gamification/badges/:userId`| Student | Get any user's badges       |

---

### Admin

All admin endpoints require role: `admin`.

| Method | Endpoint                     | Auth  | Description                    |
|--------|------------------------------|-------|--------------------------------|
| GET    | `/admin/stats`               | Admin | Platform-wide statistics       |
| GET    | `/admin/users`               | Admin | List all users (paginated)     |
| PATCH  | `/admin/users/:id/suspend`   | Admin | Suspend a user account         |
| PATCH  | `/admin/users/:id/activate`  | Admin | Re-activate a user account     |
| PATCH  | `/admin/users/:id/role`      | Admin | Change a user's role           |

#### GET `/admin/users?page=1&limit=20` — Response
```json
{
  "success": true,
  "data": [
    { "id": "uuid", "fullName": "...", "email": "...", "role": "student", "isActive": true }
  ],
  "message": null
}
```

---

## Standard Response Envelope

Every response follows this shape:

```json
// Success
{ "success": true, "data": { ... }, "message": null }

// Error
{
  "success": false,
  "statusCode": 400,
  "message": "Validation error message",
  "timestamp": "2026-07-31T10:00:00.000Z",
  "path": "/api/v1/auth/login"
}
```

---

## Error Codes

| Status | Meaning                                               |
|--------|-------------------------------------------------------|
| 400    | Bad request — validation failed                       |
| 401    | Unauthorized — missing or invalid token               |
| 403    | Forbidden — insufficient role                         |
| 404    | Not found                                             |
| 409    | Conflict — e.g. email already registered             |
| 429    | Too many requests — rate limit exceeded               |
| 500    | Internal server error                                 |

---

## Rate Limiting

- Default: **100 requests per 60 seconds** per IP
- Configurable via `THROTTLE_TTL` and `THROTTLE_LIMIT` environment variables
