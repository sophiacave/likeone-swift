# CONTENT PAGES MEGAPLAN
## Apple-Level Reading Experience. Every Page Impresses.
### S220+ | May 29, 2026

---

## CURRENT STATE

### Course Detail (/academy/:slug)
- Hero wastes viewport — lessons below the fold
- Lesson rows aren't clickable (no lesson pages exist)
- No progress indicator
- Too much whitespace

### Blog Post (/blog/:slug)
- Content renders as RAW MARKDOWN (not parsed)
- No heading hierarchy, no paragraph breaks
- Wall of text

### Lesson Page (/academy/:course/:lesson)
- DOESN'T EXIST YET
- 518 lesson files sitting in lyra-app unused

---

## DESIGN PRINCIPLES (Apple Developer Docs + Apple Books)

1. **Reading column**: 680px max-width. 65 characters per line. Optimal readability.
2. **Typography scale**: Title 2.5rem, H2 1.5rem, H3 1.25rem, Body 1.05rem, Code 0.9rem.
3. **Vertical rhythm**: 1.75 line-height on body. Headings have 2em top margin, 0.75em bottom.
4. **Code blocks**: Dark background (#161622), SF Mono, 0.9rem, 16px padding, 8px radius.
5. **Content above the fold**: The FIRST content paragraph is always visible without scrolling.
6. **Navigation is contextual**: Show where you are in the course. Previous/Next lesson.
7. **Progressive disclosure**: Course overview is compact. Tap to expand lesson details.

---

## THREE PAGES TO BUILD

### 1. COURSE DETAIL (redesign)

**Layout: Split hero + inline lesson list**

```
+------------------------------------------+
| <- Back to Academy                       |
|                                          |
| [emoji] AI Foundations                   |
| Beginner · 9 lessons · Free             |
|                                          |
| Understand how AI actually works —       |
| neurons, prompts, embeddings — through   |
| hands-on exploration.                    |
|                                          |
| [Start Learning]                         |
+------------------------------------------+
|                                          |
| LESSONS                     3 free / 6 pro|
|                                          |
| 1  What Is a Neuron?           FREE  ->  |
| 2  Build a Network             FREE  ->  |
| 3  Neural Net Quiz             FREE  ->  |
| ─────────────────────────────────────     |
| 4  Anatomy of a Prompt         PRO   🔒  |
| 5  Prompt Playground           PRO   🔒  |
| ...                                      |
+------------------------------------------+
```

**Key changes:**
- Compact hero (emoji + title + meta on fewer lines)
- Lessons visible above the fold
- Each lesson row is a LINK to /academy/:course/:lesson
- "Start Learning" CTA goes to lesson 1
- Free/Pro divider line
- Arrow affordance on free lessons, lock on pro

### 2. LESSON PAGE (new)

**Layout: Reading column with contextual nav**

```
+------------------------------------------+
| <- AI Foundations        Lesson 1 of 9   |
+------------------------------------------+
|                                          |
|  What Is a Neuron?                       |
|                                          |
|  Your brain has 86 billion neurons.      |
|  Each one does something embarrassingly  |
|  simple. AI neurons do the exact same    |
|  thing — and that simplicity is why      |
|  they're so powerful.                    |
|                                          |
|  ## After This Lesson                    |
|                                          |
|  - What a neuron computes                |
|  - Weights, biases, activations          |
|  - Why stacking neurons = intelligence   |
|                                          |
|  [lesson content continues...]           |
|                                          |
+------------------------------------------+
| <- Previous    [2/9]    Next ->          |
+------------------------------------------+
```

**Key features:**
- Breadcrumb: course name + lesson position
- Clean reading column (680px)
- Lesson content rendered as HTML
- Previous/Next navigation at bottom
- No sidebar (mobile-first, content-focused)

### 3. BLOG POST (fix + redesign)

**Layout: Article with proper markdown rendering**

```
+------------------------------------------+
| <- Back to Blog                          |
|                                          |
| May 28, 2026 · Sophie Cave · 8 min read |
|                                          |
| MCP Server Security: The Checklist       |
| Nobody Wrote Yet                         |
|                                          |
| Everyone's shipping MCP servers.         |
| Almost nobody's securing them.           |
|                                          |
| [mcp] [security] [ai agents]            |
|                                          |
| ─────────────────────────────────────    |
|                                          |
| ## Why MCP Security Is Different         |
|                                          |
| Traditional API security assumes a       |
| human is making requests...              |
|                                          |
+------------------------------------------+
```

**Key fixes:**
- RENDER MARKDOWN TO HTML (pre-process or swift-markdown)
- Reading time estimate
- Separator between meta and content
- Proper heading hierarchy (H2, H3)
- Code blocks styled
- Lists, bold, links all rendered

---

## IMPLEMENTATION PLAN

### Step 1: Markdown Rendering (blog fix)
- Pre-process blog markdown to HTML in the JSON generation script
- Update blogs.json with HTML content
- Blog posts immediately look correct

### Step 2: Course Detail Redesign
- Compact hero (inline emoji + title)
- Lessons visible above fold
- Each lesson row links to /academy/:course/:lesson
- "Start Learning" CTA

### Step 3: Lesson Content Pipeline
- Copy 518 lesson HTML files to Resources/Content/lessons/
- Or embed lesson content in lessons-index.json
- LessonContentProvider reads HTML per lesson
- Route: /academy/:course/:lesson renders lesson HTML

### Step 4: Lesson Page Template
- Clean reading column template
- Previous/Next navigation
- Breadcrumb (course name + position)
- Styled content (headings, code, lists, links)

### Step 5: Content CSS
- Shared `.reading-column` styles
- `.article-content` typography (headings, lists, code, links)
- `.lesson-nav` previous/next bar
- `.course-header` compact course info

---

## CSS: THE READING COLUMN

```css
.reading-column {
    max-width: 680px;
    margin: 0 auto;
    padding: 0 24px;
}

.article-content {
    font-size: 1.05rem;
    line-height: 1.75;
    color: #d4d4dc;
    letter-spacing: -0.003em;
}

.article-content h2 {
    font-size: 1.5rem;
    font-weight: 600;
    margin: 2.5rem 0 0.75rem;
    color: var(--text-primary);
    letter-spacing: -0.02em;
}

.article-content pre {
    background: #161622;
    border-radius: 8px;
    padding: 20px;
    overflow-x: auto;
    font-family: 'SF Mono', monospace;
    font-size: 0.875rem;
    line-height: 1.6;
    margin: 1.5rem 0;
    border: 1px solid var(--border);
}
```

---

*every page is a reading experience. every reading experience is beautiful.*
