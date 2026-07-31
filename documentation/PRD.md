# CampusCore — Product Requirements Document (PRD)

**Version:** 1.0  
**Date:** July 2026  
**Status:** Active

---

## 1. Overview

CampusCore is an academic platform that helps university students learn, collaborate, and succeed. The initial launch targets LAUTECH's Fisheries & Aquaculture Department, with a roadmap to expand across all Nigerian universities.

**Tagline:** *Learn. Connect. Achieve.*

---

## 2. Goals

- Provide a centralized hub for course materials, past questions, and lecture notes.
- Enable peer-to-peer academic collaboration through Q&A and discussion forums.
- Offer AI-powered study tools to supplement learning.
- Support GPA/CGPA tracking and study progress monitoring.
- Build a safe, integrity-focused academic environment.

---

## 3. User Roles & Permissions

### 3.1 Student
- Register and log in (email, Google, phone)
- Browse and download course materials
- Upload resources (pending moderator approval)
- Ask and answer questions in Q&A
- Join and participate in discussion forums
- Use the AI Study Assistant
- Track study progress and course completion
- Calculate GPA and CGPA
- Build a personal library (bookmarks, saved materials)
- Connect with other students
- Earn reputation points and badges

### 3.2 Class Representative / Moderator
- All student permissions
- Approve or reject uploaded resources
- Pin important materials
- Moderate Q&A and discussions
- Verify best answers

### 3.3 Lecturer (Optional)
- Upload official lecture notes and slides
- Post announcements
- Answer student questions

### 3.4 Administrator
- Full platform management
- Manage users (create, suspend, delete)
- Manage departments and courses
- Verify resources
- Handle reports and flags
- Monitor platform activity
- Configure exam restriction periods

---

## 4. Core Features

### 4.1 Authentication
| Feature               | Details                                              |
|-----------------------|------------------------------------------------------|
| Email/Password login  | Standard registration with email verification        |
| Google Sign-In        | OAuth2 via Firebase                                  |
| Phone login           | OTP via Firebase                                     |
| Password reset        | Email-based reset flow                               |
| Academic integrity    | Users accept policy on first login                   |

### 4.2 Home Dashboard
Displays personalized content:
- Continue studying (last accessed course/topic)
- Recommended study tasks
- Latest uploaded resources
- Recent discussions
- Notifications preview
- Quick-action buttons (Search, AI, Upload, GPA)

### 4.3 Course Module
Each course contains:
- Course overview and description
- Lecture notes (PDFs, slides)
- Past questions (with year filters)
- AI Tutor (context-aware per course)
- Progress tracker (per topic)
- Course-level discussion thread
- Practice quizzes

### 4.4 Resource Library
Supported formats: PDF, DOCX, PPTX, images  
Resource types: Lecture notes, slides, practical manuals, past questions, assignments

Features:
- Search and filter by course, type, year, level
- Download for offline reading
- Bookmark resources
- Version history
- Verification badges (official vs community-uploaded)

Upload workflow:
1. Student submits resource with metadata
2. Moderator reviews and approves/rejects
3. Approved resource appears in library with contributor credit

### 4.5 Community

**Q&A:**
- Students post academic questions
- Other students answer; moderators verify best answers
- Questions appear immediately
- Upvote/downvote answers

**Discussions:**
- Organized by academic level (100L, 200L, etc.) not individual course
- Threaded replies
- Report/flag inappropriate content

### 4.6 AI Study Assistant
Capabilities:
- Explain academic concepts
- Summarize chapters or passages
- Generate topic-based quizzes
- Create flashcards
- Predict likely exam topics
- Simplify complex English
- Generate CBT (multiple-choice) practice
- Generate written/essay practice

Restrictions:
- AI refuses requests that appear to be live exam questions
- AI and discussions can be locked during official exam periods by admin
- AI is embedded within study flows — not the entry screen

### 4.7 Progress Tracker
- Mark topics as complete
- View percentage progress per course
- View overall semester progress
- Visual progress indicators (progress bars, charts)

### 4.8 GPA / CGPA Calculator
- Input courses with credit units and grades
- System calculates GPA per semester
- Save multiple semesters
- Auto-calculate cumulative CGPA
- Nigerian university grading scale (5-point system)

### 4.9 Personal Library
- Saved notes and bookmarks
- Downloaded resources (offline access)
- Organized by course or custom folders

### 4.10 Search
Global search covers:
- Courses
- Resources (notes, past questions)
- Q&A posts
- Discussions
- AI-generated explanations

### 4.11 Notifications
Triggers:
- New resources uploaded to a subscribed course
- Answer received on your question
- Moderator approves your upload
- New discussion in your level
- Study reminders (user-configured)
- Platform announcements

### 4.12 Gamification

**Reputation Points** earned by:
- Uploading an approved resource
- Having an answer marked as helpful
- Answering questions
- Participating in discussions

**Badges:**
| Badge            | Trigger                                  |
|------------------|------------------------------------------|
| Fresh Scholar    | Complete registration                    |
| Bookworm         | Download 10+ resources                   |
| Top Contributor  | Upload 5+ approved resources             |
| Community Helper | Have 10+ answers marked helpful          |
| AI Explorer      | Use AI assistant 20+ times               |

### 4.13 Connections
- Students connect with peers (mutual connection, not follow/follow)
- Profile shows: reputation score, badges, uploaded resources, helpful answers
- Study streak is private (not shown publicly)

---

## 5. Examination Integrity

- AI detects and refuses apparent live exam question patterns
- Admin can enable "exam lock" to restrict AI and discussions during exam periods
- Academic integrity policy accepted at registration
- Report mechanism for suspected misconduct
- Moderator alerts for flagged suspicious activity

---

## 6. Content Ownership

- Students retain ownership of original uploaded content
- By uploading, users grant CampusCore a licence to display and distribute within the platform
- Users can edit or delete their content
- Widely used verified resources may be archived by moderators for platform continuity

---

## 7. Non-Functional Requirements

| Requirement     | Target                                              |
|-----------------|-----------------------------------------------------|
| Performance     | API responses < 300ms for standard queries          |
| Availability    | 99.5% uptime target                                 |
| Scalability     | Stateless backend, horizontal scaling ready         |
| Security        | JWT + Firebase Auth, input validation, HTTPS only   |
| Offline Access  | Downloaded resources available without internet     |
| Accessibility   | Readable fonts, sufficient contrast, screen-reader friendly |

---

## 8. Out of Scope (v1.0)

- iOS App (post-launch)
- Live video lectures
- Real-time chat/messaging
- Payment/subscription features
- Certificate generation

---

## 9. Success Metrics

- 500+ registered students in Phase 1
- 200+ resources uploaded in first month
- 70%+ of users return within 7 days
- Average session duration > 10 minutes
- < 5% resource rejection rate (quality of uploads)
