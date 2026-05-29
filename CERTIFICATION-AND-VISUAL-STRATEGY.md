# CERTIFICATION + VISUAL + DESIGN STRATEGY
## Like One Academy — S223 Strategic Plan

> **Sprint:** S223 | **Date:** 2026-05-29 | **Lead:** Builder + Designer + Architect

---

## EXECUTIVE SUMMARY

Four interconnected systems to build, in priority order:

| # | System | Impact | Effort | Priority |
|---|--------|--------|--------|----------|
| 1 | **Certification Engine** | 🔥 Massive user accomplishment + viral sharing | Large | P0 |
| 2 | **3D Hero + Parallax** | 🔥 First impression conversion | Medium | P1 |
| 3 | **Visual Aid System v4** | 🔥 Learning effectiveness + polish | Large (ongoing) | P1 |
| 4 | **Interactive Elements** | ✨ Engagement + retention | Medium | P2 |

---

## 1. CERTIFICATION ENGINE

### 1.1 Architecture

```
┌─────────────────────────────────────────────────────┐
│                  CERTIFICATION FLOW                  │
│                                                      │
│  Complete Course → Completion Check → Generate Cert  │
│       ↓                                    ↓         │
│  Complete Track → Track Completion → Track Cert      │
│       ↓                                    ↓         │
│  🎉 Celebration Page (confetti + badge + share)      │
│       ↓              ↓            ↓         ↓        │
│   Download PDF   LinkedIn    Social Post   Share URL │
└─────────────────────────────────────────────────────┘
```

### 1.2 Data Model

```swift
// New models to add to LOCore

struct LearningTrack: Codable {
    let id: UUID
    let slug: String
    let title: String           // "AI Foundations Path"
    let description: String
    let emoji: String
    let courses: [String]       // course slugs in order
    let estimatedHours: Int
    let difficulty: String      // beginner, intermediate, advanced
    let badgeColor: String      // hex color for cert accent
}

struct Certificate: Codable {
    let id: UUID                // credential ID
    let userId: UUID
    let type: CertType          // .course or .track
    let courseSlug: String?
    let trackSlug: String?
    let title: String           // "Prompt Writing 101" or "AI Foundations Path"
    let earnedAt: Date
    let verificationURL: String // /cert/{uuid}
}

enum CertType: String, Codable {
    case course
    case track
}

struct UserProgress: Codable {
    let userId: UUID
    let courseSlug: String
    let completedLessons: [String]  // lesson slugs
    let quizScores: [String: Int]   // lessonSlug: score
    let completedAt: Date?
}
```

### 1.3 Learning Tracks (Curated Paths)

| Track | Courses | Hours | Badge |
|-------|---------|-------|-------|
| **AI Foundations** | Prompt Writing 101, AI Foundations, Claude for Beginners | ~6h | 🧠 Purple |
| **Automation Builder** | AI-Powered Workflows, Zapier + AI, Browser Automation | ~8h | ⚡ Green |
| **Agent Architect** | Claude Agent SDK, Computer Use Agents, Multi-Agent Systems | ~10h | 🤖 Blue |
| **Full Stack AI** | All Beginner + Intermediate courses | ~20h | 🏆 Gold |
| **AI Master** | All 52 courses (the whole academy) | ~80h | 💎 Diamond |

### 1.4 PDF Certificate Generation

**TWO OPTIONS (ranked):**

**Option A — WeasyPrint (RECOMMENDED for our Fly.io stack)**
Why:
- `apt-get install weasyprint` — single line in Dockerfile (~50MB vs 300MB+ Chromium)
- HTML+CSS → PDF, no JavaScript needed (certs are static)
- Smallest output: 8-21KB PDFs vs 16-125KB from Chromium tools
- Invoke from Swift via `Foundation.Process`: `weasyprint input.html output.pdf`
- No separate container or sidecar needed — runs in same image
- Also generates PNG via `--format png` flag (for OG images)

**Option B — Gotenberg (if we need JS rendering)**
Why:
- Docker-based microservice, Chromium-powered
- HTML-to-PDF via HTTP API: POST HTML → GET PDF
- 7,500+ GitHub stars, 2M+ Docker pulls/month
- Heavier: requires separate container + 300-500MB Chromium layer
- Only needed if cert templates require JavaScript execution

Architecture (WeasyPrint):
```
Swift Server → Foundation.Process("weasyprint", [html_path, pdf_path]) → PDF file
                    (generates cert HTML via Leaf template)              (serves as download)
```

**Additional Swift Packages:**
- `swift-qrcode-generator` (fwcd/swift-qrcode-generator) — pure Swift, Linux-compatible, outputs SVG QR codes for cert PDFs
- `SwiftGD` (twostraws/SwiftGD) — Swift wrapper for libgd, Linux-compatible, generates OG images (1200x630 PNG)

Certificate Template Design:
- Dark theme matching site (or elegant light version for printing)
- Like One logo + purple accent gradient
- Recipient name in large serif/display font
- Course/track title, completion date
- QR code linking to verification URL
- Credential ID in small monospace
- Issuer line: "Like One Academy | likeone.ai"
- Digital signature line: "Sophia Cave, Founder"

### 1.5 Sharing System

**LinkedIn Add to Profile:**
```
https://www.linkedin.com/profile/add
  ?startTask=CERTIFICATION_NAME
  &name={cert_title}
  &organizationId={likeone_org_id}
  &issueYear={year}
  &issueMonth={month}
  &certUrl=https://likeone.ai/cert/{uuid}
  &certId={uuid}
```

**Social Share Options:**
1. **LinkedIn Post** — Pre-filled text + cert image as OG preview
2. **Twitter/X** — Tweet with OG image card
3. **Copy Link** — `https://likeone.ai/cert/{uuid}` (public verification page)
4. **Download PDF** — Gotenberg-generated certificate
5. **Email** — Send cert PDF to recipient's email

**OG Image for Cert Pages:**
- Dynamic OG image per certificate (1200x630px)
- Generated server-side: SVG template → PNG via Sharp/Resvg
- Shows: cert title, recipient name, Like One branding
- Cached at CDN after first generation

### 1.6 Celebration UX

When a user completes a course/track:

1. **Screen fills with confetti** (canvas-confetti, ~6KB, respects prefers-reduced-motion)
2. **Badge animation** — badge drops in with spring physics
3. **Stats reveal** — "You completed 10 lessons, scored 95% on quizzes"
4. **Certificate preview** — visual preview of the actual cert
5. **Share buttons** — LinkedIn, Twitter, Copy Link, Download PDF, Email
6. **What's next** — suggested next course or track

### 1.7 Verification Page (`/cert/{uuid}`)

Public page that verifies a certificate:
- Clean, professional layout
- Shows: recipient name, cert title, date, credential ID
- "Verified" badge with checkmark
- QR code for physical cert → digital verification
- Link back to the course/track
- OG tags for social preview when shared

### 1.8 Routes to Add

```swift
// CertificationController.swift
routes.get("cert", ":id", use: verifyCert)           // public verification
routes.get("celebrate", ":type", ":slug", use: celebrate)  // celebration page
routes.post("cert", "generate", use: generateCert)     // generate + download PDF
routes.get("tracks", use: allTracks)                   // learning tracks list
routes.get("tracks", ":slug", use: trackDetail)        // track detail page
routes.post("progress", "complete", use: markComplete) // mark lesson complete
```

---

## 2. 3D HERO + PARALLAX DESIGN

### 2.1 Hero: Three.js Neural Network

**RECOMMENDED: Three.js with custom scene**

Why Three.js:
- Full control over aesthetics and performance
- ~150KB core (lazy-loaded after hero visible)
- Matches our dark theme + purple/green accent palette
- Community examples of neural network visualizations exist
- Works with server-rendered HTML (no React needed)

Scene Description:
```
Background: Dark (#09090b) with subtle radial gradient

Floating neural mesh:
  - 40-60 glowing nodes (small spheres, purple #c084fc)
  - Thin connection lines between nearby nodes (blue #38bdf8, low opacity)
  - Occasional green pulses (#34d399) traveling along connections
  - Gentle rotation (0.001 rad/frame on Y axis)
  - Depth blur on distant nodes (natural depth of field feel)
  - Mouse parallax: subtle movement tracking cursor

Particle system:
  - 100-200 tiny floating dots (white, very low opacity)
  - Random drift + gentle float upward
  - Creates "data flowing" feeling

Text overlays:
  - Hero text sits ABOVE the canvas (z-index)
  - Slight glass-morphism blur on text background area
```

Performance:
- Lazy-load Three.js via IntersectionObserver
- `requestAnimationFrame` pauses when tab hidden
- `prefers-reduced-motion`: show static background (CSS gradient)
- Target: <3s LCP, no jank
- Mobile: reduce node count to 20, disable mouse tracking

Files:
```
Public/js/hero-3d.js     — Scene setup + animation loop (~100 lines)
Public/js/three.min.js   — Three.js core (lazy-loaded)
index.leaf               — Canvas element + IntersectionObserver trigger
style.css                — .hero-canvas positioning
```

### 2.2 Section Parallax (Below Hero)

Use CSS-only parallax for section transitions:
```css
.parallax-section {
    perspective: 1000px;
    overflow-x: hidden;
}
.parallax-bg {
    transform: translateZ(-2px) scale(3);
    /* creates depth without JS */
}
```

Sections with parallax depth:
1. Stats bar — count-up numbers (already exists, fix animation)
2. "Built in Public" section — subtle floating gradient orbs
3. Featured courses grid — cards with hover 3D tilt (CSS `transform: perspective(1000px) rotateY(2deg)`)
4. Blog preview — gentle slide-in on scroll

### 2.3 GSAP ScrollTrigger (Optional Enhancement)

For more dramatic scroll effects:
- ~50KB library, lazy-loaded
- Pin sections, animate elements on scroll
- Parallax text movement
- Stagger animations for card grids
- Only load if NOT `prefers-reduced-motion`

### 2.4 Design Accents

Small touches that add depth:
- **Glass morphism** on nav bar (backdrop-filter: blur(12px))
- **Gradient orbs** — 2-3 large, blurred gradient circles positioned behind content
- **Glow effects** — Purple glow behind hero text, green glow on CTA button hover
- **Micro-interactions** — Buttons scale on hover, links underline with slide animation
- **Card depth** — Subtle box-shadow + border that shifts on hover

---

## 3. VISUAL AID SYSTEM v4

### 3.1 Current State (v3)

| Metric | Count |
|--------|-------|
| Total lessons | 521 |
| Tailored visuals | 40 (4 courses) |
| Placeholder visuals | 481 |
| Visual types | lo-vis, lo-steps, lo-versus, lo-calc |
| CSS classes | ~90 visual-related |

### 3.2 v4 Upgrade: What Changes

**A. Upgrade Visual Quality**
The current tailored visuals (like the Vague vs Specific comparison in prompt-writing-101) are good but can be MORE stunning. v4 targets Apple WWDC-level polish:

- **Gradient borders** instead of solid borders on visual cards
- **Subtle inner glow** on active elements
- **Better typography hierarchy** — use CSS `clamp()` for responsive sizing
- **Refined color palette** — add gradients (purple→blue for process flows)
- **Rounded corners increased** to 16px for softer feel
- **Background texture** — subtle noise texture (CSS `background-image: url(data:...)`)

**B. New Diagram Types**

| Type | Use Case | Tech |
|------|----------|------|
| **Interactive Slider** | "Move to see before/after" | Alpine.js + CSS |
| **Animated Step-Through** | "Click Next to see each step" | Alpine.js + CSS transitions |
| **Live Neuron** | "Move sliders, watch output" | Alpine.js + inline SVG |
| **Code Playground** | "Edit the prompt, see the result" | Alpine.js + `contenteditable` |
| **Decision Tree** | "Click choices, see outcomes" | Alpine.js + SVG |
| **Comparison Carousel** | "Swipe to compare approaches" | Alpine.js + CSS scroll-snap |

**C. Per-Lesson Visual Strategy**
Each lesson gets:
1. **1 Hero Visual** — the main concept diagram (static SVG or HTML/CSS)
2. **1-2 Section Visuals** — supporting diagrams for key sections
3. **1 Interactive Element** — the "Play With It" component (Alpine.js)
4. **Quiz Visuals** — paired with quiz questions (static, compact SVG)
5. **Flashcard Visuals** (optional) — diagram on front, explanation on back

### 3.3 Interactive Element System

**Tech Stack: Alpine.js (14KB gzipped)**

Why Alpine.js:
- Pairs perfectly with HTMX (our existing stack)
- Declarative, HTML-attribute-based
- No build step, no bundler
- Handles local state: sliders, toggles, step-throughs
- Already used in HTMX ecosystem

**Interactive Element Types:**

**Type 1: LIVE NEURON** (Faye's example)
```html
<div class="lo-interactive" x-data="{ w1: 0.5, w2: 0.3, bias: -0.2 }">
  <div class="lo-interactive__title">Live Neuron — Move the sliders</div>
  <div class="lo-interactive__body">
    <label>Weight 1: <input type="range" min="-1" max="1" step="0.1" x-model="w1"></label>
    <label>Weight 2: <input type="range" min="-1" max="1" step="0.1" x-model="w2"></label>
    <label>Bias: <input type="range" min="-1" max="1" step="0.1" x-model="bias"></label>
    <div class="lo-interactive__result">
      Output: <span x-text="Math.max(0, w1 * 0.8 + w2 * 0.6 + bias).toFixed(2)"></span>
      <span x-show="w1 * 0.8 + w2 * 0.6 + bias > 0">🟢 FIRES</span>
      <span x-show="w1 * 0.8 + w2 * 0.6 + bias <= 0">🔴 SILENT</span>
    </div>
  </div>
</div>
```

**Type 2: STEP-THROUGH**
```html
<div class="lo-interactive" x-data="{ step: 1, max: 4 }">
  <div class="lo-interactive__title">Step-by-Step: How a Neural Network Learns</div>
  <div class="lo-steps-interactive">
    <template x-if="step === 1">
      <div class="lo-step-content"><!-- Step 1 SVG + text --></div>
    </template>
    <!-- ... more steps ... -->
  </div>
  <div class="lo-interactive__nav">
    <button @click="step = Math.max(1, step - 1)" :disabled="step === 1">← Back</button>
    <span x-text="step + '/' + max"></span>
    <button @click="step = Math.min(max, step + 1)" :disabled="step === max">Next →</button>
  </div>
</div>
```

**Type 3: BEFORE/AFTER SLIDER**
```html
<div class="lo-interactive" x-data="{ pos: 50 }">
  <div class="lo-interactive__title">Slide to Compare</div>
  <div class="lo-compare" style="position:relative;overflow:hidden;">
    <div class="lo-compare__before" :style="'width:' + pos + '%'">
      <!-- Before content -->
    </div>
    <div class="lo-compare__after">
      <!-- After content -->
    </div>
    <input type="range" min="0" max="100" x-model="pos" class="lo-compare__slider">
  </div>
</div>
```

### 3.4 Visual Generation Pipeline (Scalable to 521+ lessons)

**Phase 1: Template Library** (build once)
- 8 SVG diagram type templates (flow, comparison, architecture, formula, etc.)
- 6 interactive element templates (slider, step-through, before/after, etc.)
- CSS design tokens for all visual styling
- Alpine.js component library for interactivity

**Phase 2: AI-Assisted Generation** (per course)
- Claude reads lesson HTML → identifies each section's core concept
- Selects appropriate diagram type per section
- Generates inline SVG or HTML/CSS visual
- Generates 1 interactive element per lesson
- Generates quiz-paired visuals
- Human review per course before deploy

**Phase 3: Quality Gate**
- Run DIAGRAM-GUIDE.md checklist on every visual
- Test accessibility (aria-labels, contrast)
- Test mobile responsiveness
- Test prefers-reduced-motion
- Screenshot comparison before/after

### 3.5 Visual Style Evolution (v3 → v4)

```
v3 (current):                    v4 (target):
┌──────────────────┐             ┌──────────────────────────┐
│ Solid border     │             │ Gradient border (subtle) │
│ #0a0a0f bg       │             │ #0a0a0f bg + noise       │
│ Static SVG only  │             │ SVG + Alpine.js interact │
│ Basic colors     │             │ Gradient accents         │
│ 12px radius      │             │ 16px radius              │
│ No motion        │             │ CSS transitions on hover │
└──────────────────┘             └──────────────────────────┘
```

---

## 4. QUIZ + FLASHCARD VISUAL INTEGRATION

### 4.1 Quiz Visual Pairing Strategy

Every quiz question that tests a **visual concept** gets a paired diagram.

| Question Type | Visual Treatment |
|--------------|-----------------|
| Concept identification | Show the component/concept diagram |
| Process ordering | Show the process flow with one step highlighted |
| Comparison | Show side-by-side options |
| Architecture | Show the system diagram |
| Pure recall | Text only (no visual needed) |

### 4.2 Quiz System Upgrade

Current: Quiz questions are inline HTML in lesson content.
Upgrade: Move to a structured quiz system with:
- Question bank per lesson (JSON or Swift struct)
- Sequential flow (one question at a time)
- Progress dots
- Score tracking
- Visual aid per question
- Explanation reveal on answer

### 4.3 Flashcard Upgrade

Current: `<details>` elements with flip.
Upgrade:
- Proper flip animation (CSS 3D transform)
- Swipe gestures (Alpine.js touch events)
- Spaced repetition marking (Know / Don't Know)
- Visual on front, explanation on back (where applicable)

---

## 5. IMPLEMENTATION PHASES

### Phase A: Foundation (Sprint S223-224)
- [ ] Add Alpine.js to layout.leaf (14KB CDN, defer)
- [ ] Create `lo-interactive` CSS component system
- [ ] Build 3 interactive element prototypes (neuron, step-through, slider)
- [ ] Create certification data model (LearningTrack, Certificate, UserProgress)
- [ ] Set up Gotenberg on Fly.io (separate machine or sidecar)
- [ ] Design certificate HTML template
- [ ] Build `/cert/{uuid}` verification page
- [ ] Build `/tracks` learning tracks page

### Phase B: Celebration (Sprint S225)
- [ ] Build celebration page with confetti (canvas-confetti)
- [ ] Implement LinkedIn Add to Profile URL
- [ ] Implement social sharing (Twitter, copy link)
- [ ] Build PDF generation endpoint (Swift → Gotenberg)
- [ ] Dynamic OG image generation for cert pages
- [ ] Email cert to user (Resend API)
- [ ] Progress tracking system (mark lessons complete)

### Phase C: 3D Hero (Sprint S225-226)
- [ ] Build Three.js neural network scene
- [ ] Lazy-load with IntersectionObserver
- [ ] Mobile optimization (reduced nodes)
- [ ] prefers-reduced-motion fallback
- [ ] CSS parallax on section transitions
- [ ] Glass morphism nav + gradient orbs
- [ ] Fix count-up animation bug on homepage

### Phase D: Visual Pass (Sprint S226+)
- [ ] Build template library (8 SVG types + 6 interactive types)
- [ ] AI Foundations course: full visual pass (9 lessons, ~45 visuals)
- [ ] Prompt Writing 101: interactive elements + visual upgrade
- [ ] Claude Agent SDK: visual pass (priority per brain key)
- [ ] Scale to all 52 courses (batch generation)

---

## 6. TECH DECISIONS

| Decision | Choice | Why |
|----------|--------|-----|
| PDF generation | **WeasyPrint** (apt-get) | 50MB install, smallest PDFs, no Chromium needed, `Process` invocation |
| QR codes | **swift-qrcode-generator** | Pure Swift, Linux-compatible, SVG output, zero deps |
| OG images | **SwiftGD** (libgd) | Swift wrapper, Linux, generates 1200x630 PNG |
| Interactivity | **Alpine.js** (14KB) | Pairs with HTMX, declarative, no build step |
| 3D Hero | **Three.js** (150KB lazy) | Full control, custom neural network, dark theme |
| Confetti | **canvas-confetti** (6KB) | Lightweight, respects reduced-motion |
| Celebration | **canvas-confetti + HTMX HX-Trigger** | 6KB, server-driven, accessible |
| Parallax | **CSS-only** (sections) + Three.js (hero) | Zero JS for scroll parallax |
| Credential ID | **`LO-{YEAR}-{ALNUM}`** format | Human-readable, e.g. `LO-2026-K7M3`, goes on PDF + LinkedIn |
| Cert verification | **UUID URLs** (`/verify/{credentialID}`) | Simple, shareable, no blockchain needed |
| LinkedIn sharing | **Add to Profile URL scheme** | Pre-filled form, industry standard |
| Visual diagrams | **Inline SVG + HTML/CSS** (Claude-generated) | Zero dependencies, pixel-perfect, scalable |

---

## 7. REJECTED ALTERNATIVES

| Alternative | Why Rejected |
|-------------|-------------|
| Spline for 3D | 500KB+ runtime, iframe embed, less control |
| Rive for animations | 200KB WASM, overkill for our use case |
| React components | No React in stack, would add framework dependency |
| Lottie for lesson visuals | 60KB runtime, needs After Effects for authoring |
| wkhtmltopdf for certs | Deprecated since 2023, critical CVEs |
| Puppeteer for PDFs | Heavier than Gotenberg, more setup |
| Blockchain for verification | Overly complex, UUID URLs are sufficient |
| D3.js for diagrams | 80KB, data viz focus not educational diagrams |
| Mermaid.js for diagrams | Ugly default theme, hard to customize to our design |

---

## 8. SUCCESS METRICS

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Cert generation | <3s per cert | Gotenberg response time |
| LinkedIn shares | 50+ in first month | Track share button clicks |
| Course completions | 2x increase | UserProgress database |
| Time on lesson | +30% | Analytics |
| Interactive engagement | 60%+ interact with sliders | Alpine.js event tracking |
| LCP (homepage) | <3s with 3D hero | Lighthouse |
| Visual coverage | 100% lessons with visuals | Automated check |

---

## APPENDIX: Research Sources

- [LinkedIn Add to Profile](https://addtoprofile.linkedin.com/)
- [LinkedIn Profile Edit API - Certifications](https://learn.microsoft.com/en-us/linkedin/shared/integrations/people/profile-edit-api/certifications)
- [Gotenberg PDF API](https://gotenberg.dev/)
- [canvas-confetti](https://github.com/catdad/canvas-confetti)
- [Three.js Neural Network Forum Discussion](https://discourse.threejs.org/t/how-to-create-a-3d-animation-neural-network-using-three-js/70909)
- [OG Image Generation (Vercel)](https://vercel.com/docs/og-image-generation)
- [Alpine.js + HTMX Tutorial](https://noqta.tn/en/tutorials/htmx-alpinejs-interactive-web-apps-tutorial-2026)
- [Lottie Animation Community](https://lottie.github.io/)
- [Spline 3D Guide 2026](https://medium.com/@abhinav.dobhal/spline-design-in-2026-the-complete-guide-to-building-immersive-3d-web-experiences-without-code-097f475b3951)
