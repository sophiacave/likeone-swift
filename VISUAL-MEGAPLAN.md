# VISUAL-MEGAPLAN: Like One Academy Visual System

## Vision
Every lesson section gets a beautiful, precise SVG visual aid that genuinely helps learning.
Quiz questions get paired SVG diagrams. Homepage gets a stunning 3D hero.
Apple-level polish. Dark theme. No clutter.

## Design Principles
1. **Visual aids TEACH, not decorate** — every SVG must explain a concept, not fill space
2. **Static over interactive** for lesson sections — quizzes/flashcards are the ONLY interactive elements
3. **Consistent style system** — graph-paper grid, vector silhouettes, muted color palette
4. **Scalable pipeline** — Claude generates SVG code per lesson, not hand-crafted
5. **Performance first** — inline SVG, no external loads, zero JS for visuals

---

## LAYER 1: Homepage 3D Hero

### Tech: Three.js (lazy-loaded)
- **What**: Floating neural network mesh — nodes + connections, subtle rotation, particles
- **Aesthetic**: Dark bg, purple (#c084fc) nodes, green (#34d399) pulses along connections
- **Size**: ~150KB Three.js core (lazy-loaded on scroll), ~50 lines of scene code
- **Performance**: requestAnimationFrame, pauses when off-screen, respects prefers-reduced-motion
- **Fallback**: CSS gradient hero (current) for browsers without WebGL

### Implementation
```
Public/js/hero-3d.js — Three.js scene (lazy-loaded)
layout.leaf — IntersectionObserver triggers load
style.css — .hero-canvas { position: absolute; top: 0; z-index: 0; }
```

### Why Three.js over alternatives:
- Spline: Beautiful but 500KB+ runtime, iframe = no control
- CSS 3D: Can't do particle systems or glowing connections
- Rive: Great for UI micro-interactions, overkill for hero bg
- GSAP: Good for scroll, but not 3D scenes

---

## LAYER 2: Lesson Visual Aid System (THE CORE)

### Tech: Inline SVG, Claude-generated, graph-paper aesthetic

### Visual Style
- **Background**: Subtle graph-paper grid (rgba(255,255,255,.03) lines, 20px spacing)
- **Shapes**: Clean vector silhouettes, rounded corners, no fills — outlines only
- **Colors**: Course-specific accent from existing palette:
  - Green (#34d399) = data flow, inputs, correct
  - Purple (#c084fc) = processing, AI concepts, neural
  - Blue (#38bdf8) = connections, links, networks
  - Orange (#fb923c) = outputs, decisions, results
  - Red (#ef4444) = warnings, errors, wrong
  - Muted (#71717a) = labels, annotations, grid
- **Typography**: "SF Mono" / monospace for labels. 9-11px. Uppercase section labels.
- **Frame**: Dark card background (#0a0a0f), subtle border, 16px radius
- **Motion**: NONE. Static SVGs only. Learning requires focus, not distraction.

### Diagram Types (template library)
1. **Flow diagram** — boxes connected by arrows (data pipelines, process steps)
2. **Comparison table** — side-by-side columns with icons (already in ASCII, upgrade to SVG)
3. **Architecture diagram** — layered blocks (neural networks, system architecture)
4. **Concept map** — central node with radiating connections
5. **Timeline** — horizontal progression with milestones
6. **Formula visual** — equation with labeled parts, color-coded
7. **Before/After** — split view showing transformation
8. **Hierarchy** — tree structure (classification, decision trees)

### SVG Generation Pipeline
1. **Per lesson**: Claude reads lesson HTML, identifies each section's core concept
2. **Per section**: Generate ONE SVG diagram (viewBox 480x200 or 480x280)
3. **Template**: Use diagram type templates for consistency
4. **Embed**: Inline in lesson HTML inside `.lesson-visual` wrapper
5. **Review**: Visual QA per course before deploy

### HTML Structure
```html
<div class="lesson-section">
  <span class="section-label">The Concept</span>
  <h2 class="section-title">A voting booth in your brain.</h2>
  <div class="lesson-visual" aria-label="Diagram showing a neuron as a voting booth">
    <svg viewBox="0 0 480 200"><!-- generated SVG --></svg>
  </div>
  <p class="section-text">Think of it like a voting booth...</p>
</div>
```

### CSS for lesson-visual
```css
.lesson-visual {
  margin: 16px 0;
  background: #0a0a0f;
  border: 1px solid rgba(255,255,255,.06);
  border-radius: 12px;
  padding: 16px;
  overflow: hidden;
}
.lesson-visual svg {
  width: 100%;
  height: auto;
  display: block;
}
```

### Scale: 521 lessons x ~5 visual sections = ~2,600 SVGs needed
- Phase 1: AI Foundations course (9 lessons, ~45 diagrams) — PROTOTYPE
- Phase 2: Claude for Beginners + top 5 courses (~60 lessons, ~300 diagrams)
- Phase 3: All remaining courses (batch generation)

---

## LAYER 3: Quiz Visual Integration

### Approach: Pair each quiz question with a small inline SVG

### When to add a visual:
- Concept identification ("What does this component do?") -> show the component
- Process questions ("What happens during training?") -> show the process flow
- Comparison questions ("What's the difference between ReLU and Sigmoid?") -> show both side by side
- Architecture questions ("What are the three types of layers?") -> show layer diagram

### When NOT to add a visual:
- Pure recall questions ("What is overfitting?") — text is sufficient
- Opinion/judgment questions — no diagram helps
- Questions where the visual would give away the answer

### HTML Structure
```html
<div class="quiz-question">
  <div class="quiz-visual" aria-label="Diagram of neuron computation">
    <svg viewBox="0 0 400 120"><!-- compact quiz SVG --></svg>
  </div>
  <p class="quiz-q"><span class="quiz-num">1</span>What does a weight control?</p>
  <div class="quiz-options">...</div>
</div>
```

### Sizing: Quiz SVGs are SMALLER than lesson SVGs
- viewBox: 400x120 (compact, horizontal)
- Simpler than lesson diagrams — highlight ONE concept
- Can use the same template library, just scaled down

---

## LAYER 4: Existing ASCII Art -> SVG Upgrade

Many lessons already have ASCII art diagrams in `<pre>` blocks.
These should be systematically upgraded to proper SVG.

### Example (current):
```
  DATA FLOW THROUGH A NEURAL NETWORK
  Raw Data → Pattern Detection → Decision
```

### Example (upgraded):
Proper SVG with colored boxes, labeled arrows, graph-paper grid background.
Same information, 10x more polished, still accessible via aria-label.

### Priority: Upgrade ASCII art in the top 10 most-visited lessons first.

---

## PHASE PLAN

### Phase 1: Foundation (this sprint)
- [x] Quiz score counter + shake animation
- [x] Flashcard study mode
- [x] Homepage parallax + count-up stats
- [x] Fly.io persistent volume
- [ ] Add `.lesson-visual` CSS to style.css
- [ ] Create 3 prototype SVG diagrams for what-is-a-neuron.html
- [ ] Validate the visual style with Faye

### Phase 2: Homepage 3D (next sprint)
- [ ] Three.js neural network hero animation
- [ ] Lazy-load + performance optimization
- [ ] Fallback for no-WebGL browsers
- [ ] Mobile-responsive canvas sizing

### Phase 3: AI Foundations Visual Pass (following sprint)
- [ ] Generate SVGs for all 9 AI Foundations lessons (~45 diagrams)
- [ ] Pair quiz questions with visual aids (~30 quiz SVGs)
- [ ] Upgrade ASCII art to SVG (5 existing diagrams)
- [ ] Deploy and verify

### Phase 4: Scale to All Courses
- [ ] Build SVG generation prompt templates per diagram type
- [ ] Batch generate for top 10 courses
- [ ] Quality review pipeline
- [ ] Full 52-course visual pass

---

## REJECTED APPROACHES (and why)

| Approach | Why Rejected |
|----------|-------------|
| Lottie animations | 60KB runtime, needs After Effects, overkill for static diagrams |
| Rive | 200KB WASM runtime, interactive focus we don't need for lessons |
| React components | No React in stack, adds framework dependency |
| AI image generation (raster) | Not vector, can't style with CSS, large file sizes |
| D3.js | 80KB library, designed for data viz not educational diagrams |
| Mermaid.js | Good for flowcharts but ugly default theme, hard to customize |
| External SVG files | Extra HTTP requests, can't inline-style, harder to manage |

## THE RIGHT TOOL: Claude-generated inline SVG
- Zero dependencies
- Pixel-perfect dark theme integration
- Accessible (aria-label)
- Infinitely scalable via prompt pipeline
- Each SVG is ~2-5KB inline (negligible vs lesson HTML)
- Can be styled with existing CSS variables
