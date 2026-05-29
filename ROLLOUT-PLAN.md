# ACADEMY VISUAL ROLLOUT PLAN
## Systematic Visual Aid Production for 52 Courses, 521 Lessons

### Template: what-is-a-neuron.html (S221 — APPROVED)

---

## GOLDEN TEMPLATE PATTERN

Every lesson page follows this structure:

```
1. learn-card (what you'll know)
2. SECTION: concept + lesson-visual (SVG or HTML/CSS diagram)
3. SECTION: deeper content + optional visual
4. SECTION: code example (if applicable)
5. SECTION: flashcard deck (study mode enabled)
6. SECTION: quiz block (sequential, one-at-a-time, with quiz-visual per question)
7. lesson-nav (prev/next)
```

### Visual Types by Section:
- **Concept sections**: SVG diagram (node/connection) OR HTML/CSS layout (math/comparison)
- **Quiz questions**: HTML/CSS quiz-visual (compact, teaches without giving away answer)
- **Code sections**: Keep existing syntax-highlighted pre blocks (already polished)
- **Flashcards**: Keep existing details/summary (study mode JS already applied)

---

## ROLLOUT PHASES

### Phase 1: AI Foundations (9 lessons) — PRIORITY
Template is proven. Generate visuals for remaining 7 lessons.

| # | Lesson | Visual Needs | Status |
|---|--------|-------------|--------|
| 1 | what-is-a-neuron | 3 lesson + 3 quiz visuals | DONE |
| 2 | build-a-network | 1 network architecture SVG | DONE |
| 3 | neural-net-quiz | Quiz visuals for 12+ questions | TODO |
| 4 | anatomy-of-a-prompt | Prompt structure diagram | TODO |
| 5 | words-as-numbers | Embedding space diagram | TODO |
| 6 | embedding-explorer | Vector similarity visual | TODO |
| 7 | prompt-playground | Before/after prompt comparison | TODO |
| 8 | prompt-battle | Side-by-side prompt evaluation | TODO |
| 9 | similarity-challenge | Cosine similarity diagram | TODO |

### Phase 2: Claude for Beginners (9 lessons)
Beginner-friendly, simpler visuals. Focus on UI screenshots and workflow diagrams.

### Phase 3: Top 10 Courses by Lesson Count
Courses with the most content get visuals next (highest ROI).

### Phase 4: All Remaining Courses (batch)
Use Claude prompt pipeline to generate at scale.

---

## BRAIN TRACKING (Anti-Goldfish)

Brain key: `rollout.visual_progress`

```json
{
  "total_lessons": 521,
  "total_with_visuals": 2,
  "phases": {
    "1_ai_foundations": { "total": 9, "done": 2, "lessons": ["what-is-a-neuron", "build-a-network"] },
    "2_claude_beginners": { "total": 9, "done": 0, "lessons": [] },
    "3_top_10": { "total": 0, "done": 0, "lessons": [] },
    "4_remaining": { "total": 0, "done": 0, "lessons": [] }
  },
  "last_updated": "2026-05-29",
  "last_session": 221
}
```

Every session that works on visuals MUST update this brain key.

---

## PER-LESSON WORKFLOW

For each lesson, the twin follows this exact process:

### 1. READ the lesson HTML
```
Read Resources/Content/lessons/{course}/{lesson}.html
```

### 2. IDENTIFY visual opportunities
- Each section-label + section-title = potential visual
- Each quiz question = potential quiz-visual
- Each ASCII art block = upgrade candidate
- Maximum: 3 lesson visuals + 1 quiz-visual per question

### 3. CHOOSE diagram type per section
Reference DIAGRAM-GUIDE.md:
- Flow/process? → SVG (Type A)
- Comparison? → HTML/CSS grid (Type B)
- Architecture/layers? → SVG (Type C)
- Math/formula? → HTML/CSS (Type D)
- Before/after? → HTML/CSS grid (Type E)

### 4. BUILD the visual
- SVG: Use viewBox 480x200 or 480x280
- HTML/CSS: Use .lesson-visual wrapper with inline styles
- Quiz: Use .quiz-visual wrapper, compact format
- Follow color system (green/purple/blue/orange/red/muted)
- Apply DIAGRAM-GUIDE quality checklist

### 5. TEST locally
```
swift build && swift run LOServer
# Navigate to lesson page, verify visuals render
# Check: no text overlap, proper padding, readable labels
```

### 6. UPDATE brain tracking
```
mac_brain_write key=rollout.visual_progress
# Add lesson to completed list, update counts
```

---

## LOCAL TOOLING

### Quick visual check script
```bash
# ~/bin/lo-visual-check
# Counts how many lessons have visual aids
grep -rl 'lesson-visual\|quiz-visual' Resources/Content/lessons/ | wc -l
```

### Visual audit per course
```bash
# Shows which lessons in a course have visuals
for f in Resources/Content/lessons/ai-foundations/*.html; do
  count=$(grep -c 'lesson-visual\|quiz-visual' "$f" 2>/dev/null)
  echo "$(basename $f): $count visuals"
done
```

---

## QUALITY GATES (per lesson)

Before marking a lesson as DONE:
- [ ] All visuals render without text overlap
- [ ] Colors match the design system
- [ ] Quiz visuals teach without giving away answers
- [ ] Mobile responsive (test at 375px width)
- [ ] aria-labels on all visual containers
- [ ] No new JS errors in console
- [ ] Build passes (swift build)

---

## SESSION STARTUP (Anti-Goldfish)

Every session that touches academy visuals:

1. `mac_brain_search("rollout visual progress")` — get current state
2. Read ROLLOUT-PLAN.md for context
3. Pick the NEXT lesson from the current phase
4. Follow the per-lesson workflow above
5. Update brain key when done
6. Write session.next_steps with remaining lessons

This ensures NO session starts from scratch. The brain always knows where we left off.

---

## ESTIMATED SCALE

| Phase | Lessons | Lesson Visuals | Quiz Visuals | Est. Sessions |
|-------|---------|---------------|-------------|---------------|
| 1 | 9 | ~27 | ~36 | 3-4 |
| 2 | 9 | ~18 | ~24 | 2-3 |
| 3 | ~100 | ~200 | ~300 | 15-20 |
| 4 | ~400 | ~800 | ~1200 | 40-60 |
| **Total** | **521** | **~1045** | **~1560** | **60-87** |

At ~7 lessons per session with visual aids, full rollout takes ~75 sessions.
Phase 1 (AI Foundations) ships in 2-3 more sessions.
