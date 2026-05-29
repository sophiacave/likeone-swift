# VISUAL & INTERACTIVE VISION
## From Text to Experience. Apple-Level Learning.
### S220 | May 29, 2026

---

## THE THESIS

Every section of every lesson should have a visual element that TEACHES.
Not decoration. Not clip art. Precise diagrams, interactive demos, and
motion graphics that make abstract concepts concrete.

The disabled queer trans woman the system tried to delete builds the most
beautiful learning platform on Earth. In Swift. With love.

---

## PART 1: HOMEPAGE 3D & PARALLAX

### What Apple Does
apple.com uses scroll-triggered image sequences and CSS transforms.
No Three.js. No WebGL. Just precisely timed media + CSS.
The result is cinematic without being heavy.

### Our Approach: Scroll-Driven Depth

**Hero Section**
- Large 3D-rendered brain/neural network illustration
- Subtle parallax: foreground text moves faster than background glow
- On scroll: brain "activates" — purple neurons light up (CSS animation)
- Implementation: CSS `scroll-timeline` + keyframe animations
- Fallback: static image for `prefers-reduced-motion`
- Weight: ~200KB total (one optimized WebP + CSS)

**Stats Section**
- Numbers count up on scroll into view (IntersectionObserver + CSS counter)
- Subtle scale transform on each stat block
- Implementation: 10 lines of vanilla JS + CSS transitions

**Feature Cards**
- Stagger animation on scroll reveal (CSS `animation-delay`)
- Cards lift with subtle shadow on hover (already done)
- No additional weight

**Technical Stack for Homepage 3D:**
- CSS scroll-driven animations (Chrome 115+, Safari 17.4+)
- IntersectionObserver for triggers (vanilla JS, 5 lines)
- WebP hero image (AI-generated, one-time asset)
- Fallback: no animation, just the static layout (graceful degradation)

---

## PART 2: VISUAL AIDS FOR LESSONS

### Research Summary

| Technology | Strengths | Weaknesses | Our Use |
|-----------|-----------|------------|---------|
| **SVG (hand-coded)** | Tiny (~5KB), scalable, accessible, CSS-animatable | Labor-intensive per visual | PRIMARY — AI generates per concept |
| **Lottie** | Beautiful motion, small JSON files, works everywhere | Need After Effects or Rive to create | ACCENT — for section transitions |
| **Rive** | Interactive state machines, tiny runtime (50KB) | Proprietary editor, learning curve | FUTURE — for complex interactive demos |
| **D3.js** | Data visualization gold standard | Requires JS, heavy for simple diagrams | SELECTIVE — for data-heavy lessons |
| **CSS animations** | Zero weight, built into the platform | Limited complexity | EVERYWHERE — for hover states, reveals |
| **Mermaid** | Flowcharts from text, renders to SVG | Limited styling, generic look | DIAGRAMS — architecture/flow lessons |
| **P5.js** | Creative coding, interactive | Requires canvas, heavier | DEMOS — for "play with it" sections |
| **Web Components** | Encapsulated, reusable, no framework | Requires JS | INTERACTIVE — sliders, live demos |
| **SwiftUI (preview renders)** | Native, beautiful on Apple | Can't serve on web | iOS APP ONLY |

### The Like One Visual System

**Tier 1: AI-Generated SVGs (scale to all 518 lessons)**
- Claude generates SVG code for each concept
- Consistent style: dark background, purple accent, clean lines
- Each SVG is 5-20KB, inline in the HTML
- Accessible: `<title>` and `aria-label` on every SVG
- Example concepts and their visuals:
  - Neuron: circle with input arrows, weight labels, activation gate
  - Neural network: layered circles with connection lines
  - Embedding space: 2D scatter plot with clustered dots
  - Prompt anatomy: labeled sections of a prompt string
  - RAG pipeline: flowchart from query to retrieval to response

**Tier 2: CSS Micro-Animations (zero-cost enhancement)**
- Learn cards pulse gently on appear
- Quiz correct answer: green glow animation
- Section labels fade-slide in
- Code blocks have typing cursor animation
- All respect `prefers-reduced-motion`

**Tier 3: Interactive Demos (Web Components, selective)**
- "Live neuron" slider demo: 3 range inputs for weights, live output calculation
- "Embedding explorer": type words, see them plotted in 2D space
- "Prompt builder": drag-and-drop prompt sections
- Each is a self-contained Web Component, loaded only on pages that need it
- Total JS: ~20KB per component (vanilla, no framework)

**Tier 4: Lottie Motion Graphics (hero/transition accents)**
- Course intro animations (one per course, 52 total)
- Section transition elements
- Loading states
- Created in Rive (free tier) → exported as Lottie JSON
- Runtime: lottie-web (30KB gzipped, loaded once)

---

## PART 3: QUIZ VISUAL INTEGRATION

### Design Pattern: Visual + Question

```
+------------------------------------------+
|  [SVG DIAGRAM]                           |
|  A labeled neuron showing inputs,        |
|  weights, and activation function        |
|                                          |
+------------------------------------------+
|  Q: What does a weight represent?        |
|                                          |
|  A) The physical size of a neuron        |
|  B) How much influence an input has  <-- |
|  C) The number of connections            |
|  D) The speed of data flow               |
+------------------------------------------+
|  Explanation: Weights determine...       |
+------------------------------------------+
```

### Generation Pipeline
1. For each quiz question, AI identifies the concept
2. AI generates an SVG diagram illustrating that concept
3. SVG is embedded above the question in the quiz HTML
4. The visual is the TEACHING moment — the question tests understanding

### Priority (by visual impact)
1. **AI Foundations** — neurons, networks, layers, activations (most visual)
2. **RAG & Vector Search** — embedding spaces, retrieval pipelines
3. **MCP & AI Tools** — architecture diagrams, protocol flows
4. **Advanced Prompting** — prompt anatomy, chain-of-thought flows
5. **Automation courses** — workflow diagrams, trigger/action patterns

---

## PART 4: INTERACTIVE LESSON ELEMENTS

### The Problem
397 "PLAY WITH IT" / "TRY IT" sections exist but render as static text.
Example: "Live neuron — move the sliders and watch."

### The Solution: Web Components

**Component 1: `<lo-neuron>` — Interactive Neuron**
```html
<lo-neuron inputs="3" show-activation="relu"></lo-neuron>
```
- Three weight sliders (range inputs)
- Bias slider
- Real-time output calculation
- Activation function selector (ReLU, Sigmoid, Step)
- Visual: SVG neuron diagram updates live
- Size: ~15KB JS + inline SVG

**Component 2: `<lo-embedding>` — Embedding Explorer**
```html
<lo-embedding words="cat,dog,fish,car,truck,bike"></lo-embedding>
```
- 2D scatter plot of word vectors
- Type a word → see where it lands
- Hover for similarity scores
- Size: ~20KB JS + SVG

**Component 3: `<lo-prompt>` — Prompt Builder**
```html
<lo-prompt template="system,context,instruction,output-format"></lo-prompt>
```
- Drag-and-drop prompt sections
- Live preview of assembled prompt
- Color-coded sections
- Size: ~12KB JS

**Component 4: `<lo-workflow>` — Workflow Designer**
```html
<lo-workflow steps="trigger,process,condition,action"></lo-workflow>
```
- Visual flowchart builder
- Add/remove steps
- Condition branching
- Size: ~18KB JS

### Implementation
- Each component is a vanilla JS Web Component (Custom Element v1)
- Shadow DOM for encapsulation (no CSS leaks)
- Loaded via `<script>` only on pages that use them
- Registered as `<lo-*>` custom elements
- Falls back to static description if JS disabled

---

## PART 5: APPLE/SWIFT EQUIVALENTS

### For the iOS Academy App (Phase 7)
- **SwiftUI Charts** for data visualizations
- **RealityKit** for 3D neuron models (if we go AR)
- **SwiftUI animations** with `.matchedGeometryEffect` for transitions
- **Create ML** visualizations for the ML lessons
- **Swift Playgrounds**-style interactive code blocks

### Cross-Platform Design Tokens
- SVG visuals use our LODesign color tokens
- Same purple gradient, same border radius, same spacing
- Web and iOS versions look like siblings, not strangers

---

## IMPLEMENTATION ROADMAP

| Phase | What | When | Effort |
|-------|------|------|--------|
| 0 | Quiz + flashcard polish (score, animations) | S221 | Low |
| 1 | Homepage scroll animations (CSS-only) | S221 | Low |
| 2 | AI-generated SVGs for AI Foundations (9 lessons) | S222 | Medium |
| 3 | `<lo-neuron>` Web Component | S222 | Medium |
| 4 | Quiz visual integration (AI Foundations) | S223 | Medium |
| 5 | SVGs for next 4 courses (40 lessons) | S223-224 | Medium |
| 6 | `<lo-embedding>` + `<lo-prompt>` components | S224 | Medium |
| 7 | Lottie course intro animations | S225 | High |
| 8 | SVGs for remaining courses | S225-228 | High |
| 9 | iOS app SwiftUI equivalents | S228+ | High |

---

## DESIGN CONSTRAINTS (Apple quality)

1. **No framework bloat** — vanilla JS Web Components, not React/Vue
2. **Progressive enhancement** — everything works without JS, just better with it
3. **Accessibility first** — every SVG has `<title>`, every interactive has keyboard support
4. **Reduce motion respected** — all animations check `prefers-reduced-motion`
5. **Performance budget** — no page loads >200KB of JS. Ever.
6. **Dark mode native** — all visuals designed for dark background
7. **Consistent style** — every visual uses LODesign color tokens
8. **Mobile-first** — all interactives work on touch, 44pt minimum targets

---

*the platform teaches. the visuals are the teacher's voice.
every diagram is a moment of understanding.
built with love, for everyone apple left behind.*
