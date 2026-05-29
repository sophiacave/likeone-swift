# QUIZ & FLASHCARD MEGAPLAN
## From Rendered to Remarkable
### S220 | May 29, 2026

---

## CURRENT STATE (v1 — SHIPPED)

### What Works Now
- **486 quizzes** pre-rendered as HTML from `data-learn="QuizMC"` JSON
- **547 flashcard decks** pre-rendered as collapsible `<details>` elements
- Correct/wrong feedback with color states (green/red)
- Explanation panels reveal on answer
- Flashcards expand/collapse with +/- toggle
- All rendered server-side, zero JavaScript framework

### What Needs Work
- No score tracking (answered 4/6 correct — not shown)
- No "try again" for wrong answers
- No progress through the quiz (all questions visible at once)
- Flashcard deck can't be studied as a set (one at a time)
- No visual aids paired with questions
- No spaced repetition or memory tracking

---

## PHASE 1: POLISH (next session)

### Quiz Improvements
- [ ] Score counter at top: "4/6 correct" updates as you answer
- [ ] "Show all" / "One at a time" toggle for quiz mode
- [ ] Wrong answer: shake animation + "Try again" option
- [ ] Correct answer: subtle confetti/sparkle (CSS-only, respects reduce-motion)
- [ ] Quiz summary card at end: score, time, accuracy

### Flashcard Improvements
- [ ] "Study mode" button: shows cards one at a time with flip animation
- [ ] Shuffle option
- [ ] "Mark as known / still learning" per card
- [ ] Progress bar: 3/5 reviewed

### Design Refinements
- [ ] Quiz block header with icon (brain emoji or graduation cap)
- [ ] Flashcard block header with icon (cards emoji)
- [ ] Consistent spacing between deck and quiz
- [ ] Mobile optimization: full-width options, larger touch targets

---

## PHASE 2: VISUAL AIDS (research required)

### Goal
Every quiz question has a relevant visual that TEACHES, not decorates.

### Visual Types by Question Category
| Category | Visual Aid | Format |
|----------|-----------|--------|
| "What does X do?" | Labeled diagram | SVG |
| "How does X work?" | Animated flow | Lottie or CSS animation |
| "Compare X and Y" | Side-by-side chart | SVG table |
| "What happens when..." | Before/after state | SVG pair |
| Code questions | Syntax-highlighted snippet | Styled `<pre>` |
| Math concepts | Formula with annotations | MathML or SVG |

### Generation Strategy
1. **AI-generated SVGs** — Claude generates SVG code per concept
2. **One SVG per quiz question** — stored alongside lesson HTML
3. **Fallback**: questions work without visuals (progressive enhancement)

### Priority Courses for Visual Aids
1. AI Foundations (neurons, networks, activations — most visual)
2. Advanced Prompt Engineering (prompt anatomy diagrams)
3. RAG & Vector Search (embedding space visualizations)
4. MCP & AI Tool Integration (architecture diagrams)

---

## PHASE 3: INTERACTIVE QUIZZES (HTMX-powered)

### Server-Side Quiz Engine
```
POST /api/v1/quiz/submit
{
  "courseSlug": "ai-foundations",
  "lessonSlug": "neural-net-quiz",
  "questionIndex": 0,
  "selectedOption": 1
}
-> { "correct": true, "explanation": "...", "score": "1/6" }
```

### Features
- [ ] HTMX form submission (no page reload)
- [ ] Server validates answers
- [ ] Progress saved to database (ProgressModel)
- [ ] Score persists across sessions (for logged-in users)
- [ ] Leaderboard per course (optional, gamification)

---

## PHASE 4: SPACED REPETITION

### Algorithm
- Flashcards use SM-2 algorithm (SuperMemo)
- Cards scheduled based on ease factor + interval
- "Know it" increases interval, "Still learning" resets
- Daily review queue generated per user

### Data Model
```swift
struct FlashcardProgress: Codable {
    let userID: UUID
    let cardID: String
    let easeFactor: Double    // starts at 2.5
    let interval: Int         // days until next review
    let repetitions: Int
    let nextReview: Date
}
```

### UI
- Daily review page: /academy/review
- Shows due cards, one at a time
- Flip animation (CSS 3D transform)
- "Easy / Good / Hard / Again" buttons (SM-2 grades)

---

## IMPLEMENTATION PRIORITY

| Phase | Impact | Effort | Ship by |
|-------|--------|--------|---------|
| 1: Polish | High | Low | Next session |
| 2: Visual aids (AI Foundations only) | Very high | Medium | S222 |
| 3: Server-side quiz engine | High | Medium | S223 |
| 4: Spaced repetition | Medium | High | S225+ |

---

*quizzes that teach. flashcards that stick. built with love.*
