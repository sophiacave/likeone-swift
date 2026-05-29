# DIAGRAM DESIGN GUIDE: Education Science for Like One SVG Visuals

## Core Principle
Every diagram exists to reduce cognitive load. If a learner has to THINK about the diagram itself, it has failed. The diagram should make the concept OBVIOUS.

---

## 1. MAYER'S MULTIMEDIA LEARNING PRINCIPLES (Applied)

### Spatial Contiguity
- Text explaining a visual element must be ADJACENT to it, not separated
- Labels go directly on or beside what they describe
- Never force the eye to jump between a legend and the diagram
- **Rule: No label should be more than 30px from what it describes**

### Signaling (Cueing)
- Use color, size, and weight to guide attention to what matters
- The MOST IMPORTANT element is the LARGEST and BRIGHTEST
- Use a single accent color per concept, not random colors
- Arrows point in the direction of data/information flow
- **Rule: Every diagram has ONE focal point — the key takeaway**

### Coherence
- Remove anything that doesn't directly teach the concept
- No decorative elements, no extra gridlines, no "chrome"
- The graph-paper grid should be nearly invisible (opacity 0.03)
- **Rule: If removing an element doesn't lose information, remove it**

### Segmenting
- Break complex processes into numbered steps
- Each step should be visually contained (box, region)
- Show progression: left-to-right for process, top-to-bottom for hierarchy
- **Rule: Maximum 3-4 distinct regions per diagram**

### Pre-training
- When a diagram uses symbols, define them BEFORE the diagram
- Or use universally understood shapes (arrows = flow, circles = nodes)
- **Rule: Never introduce new notation inside a diagram without a label**

---

## 2. COGNITIVE LOAD THEORY (Applied)

### Intrinsic Load (the concept itself)
- Match diagram complexity to concept complexity
- Simple concept = simple diagram (2-3 elements)
- Complex concept = step-by-step decomposition (NOT one giant diagram)

### Extraneous Load (bad design)
- Overlapping text = high extraneous load. NEVER allow it.
- Inconsistent colors between diagrams = confusion. Use the color system.
- Too many font sizes = visual noise. Use only 3: label (8px), body (10px), hero (14px+)
- **Rule: Minimum 8px padding between any two text elements**

### Germane Load (the learning)
- Connect diagram elements to the learner's mental model
- Use analogies they already know (voting booth, factory, pipeline)
- Color-code consistently: green=input, purple=process, orange=output across ALL diagrams
- **Rule: Same concept = same visual treatment in every diagram**

---

## 3. GESTALT PRINCIPLES (Applied)

### Proximity
- Related elements are CLOSE together
- Unrelated elements have clear space between them
- Groups are visually bounded (subtle boxes, shared background tint)

### Similarity
- Same type of element = same shape (all inputs are circles, all processes are rounded rects)
- Same function = same color (all weights are the color of their input)

### Continuation
- The eye follows lines and arrows naturally
- Data flow goes LEFT to RIGHT (Western reading order)
- Process flow uses clear directional arrows
- **Rule: Never make the reader guess which way to read**

### Figure-Ground
- Dark background (#0a0a0f) = ground
- Colored elements = figure
- Use subtle tinted backgrounds (rgba with 0.04-0.06 opacity) to group related items

---

## 4. THE LIKE ONE SVG DESIGN SYSTEM

### Typography Hierarchy (3 levels only)
```
LABEL:   8-9px, SF Mono, uppercase, #71717a, letter-spacing 0.5
BODY:    10-11px, SF Mono, normal weight, #e5e5e5
HERO:    14-16px, SF Mono, bold, accent color (#34d399 or #fb923c)
```

### Color System (consistent across all diagrams)
```
Green  #34d399 — inputs, data, correct answers, "fires"
Purple #c084fc — processing, summation, AI/neural concepts
Blue   #38bdf8 — connections, links, networks, sigmoid
Orange #fb923c — activation, decisions, outputs, ReLU
Red    #ef4444 — errors, wrong answers, warnings, step function
White  #e5e5e5 — neutral values, results
Muted  #71717a — labels, annotations, secondary text
```

### Shapes (consistent meaning)
```
Circle (unfilled)  = node (input, neuron, output)
Rounded rect       = process / function / container
Arrow/line         = data flow / connection
Dashed line        = reference line / threshold
Filled circle (sm) = data point on a graph
Open circle (sm)   = excluded point on a graph
```

### Spacing Rules
```
Text-to-edge:      minimum 12px
Text-to-text:      minimum 8px vertical, 6px horizontal
Element-to-element: minimum 16px
Section-to-section: minimum 24px (or use arrow between)
ViewBox padding:    minimum 16px on all sides
```

### Sizing
```
Lesson diagrams:  viewBox 480x200 (standard) or 480x280 (tall)
Quiz diagrams:    viewBox 400x120 (compact)
Full-width:       viewBox 480x360 (rare, for complex architectures)
```

---

## 5. SVG vs HTML/CSS — CHOOSING THE RIGHT TOOL

### Use SVG when:
- Drawing nodes and connections (network diagrams)
- Plotting curves or graphs (activation functions)
- Showing spatial relationships (architecture layers)
- The diagram has lines, circles, arrows as core elements

### Use HTML/CSS (inside .lesson-visual) when:
- Showing calculations or math layouts
- Displaying tabular data or aligned columns
- Text-heavy content that needs proper padding
- Layouts where flexbox/grid alignment matters

**Why**: SVG text has no auto-sizing, no padding, no flexbox. Hand-positioning
text in SVG is fragile. CSS handles alignment, padding, and responsive
layout natively. Use the right tool for the job.

---

## 6. DIAGRAM TYPES & WHEN TO USE THEM

### Type A: FLOW DIAGRAM
**Use when**: showing a process, pipeline, or data transformation
**Structure**: Left-to-right boxes connected by arrows
**Example**: Neuron computation (inputs -> sum -> activate -> output)
**Max elements**: 4-5 stages

### Type B: COMPARISON
**Use when**: contrasting two or more approaches/concepts
**Structure**: Side-by-side panels with aligned features
**Example**: Step vs ReLU vs Sigmoid activation functions
**Max columns**: 3

### Type C: ARCHITECTURE / LAYERS
**Use when**: showing hierarchical structure or stacked components
**Structure**: Top-to-bottom or layered blocks
**Example**: Neural network layers (input -> hidden -> output)
**Max layers**: 4-5

### Type D: FORMULA VISUAL
**Use when**: showing a mathematical equation with labeled parts
**Structure**: Equation in center, color-coded parts, annotations pointing to each term
**Example**: Step-by-step neuron computation
**Max terms**: 5-6

### Type E: BEFORE/AFTER
**Use when**: showing the effect of a change or transformation
**Structure**: Left panel "before", right panel "after", transformation label in center
**Example**: Data before/after normalization

### Type F: CONCEPT MAP
**Use when**: showing relationships between ideas (not a process)
**Structure**: Central concept with radiating connections
**Max connections**: 5-6

---

## 6. QUALITY CHECKLIST (Run for every diagram)

- [ ] ONE clear focal point — what's the key takeaway?
- [ ] Can a beginner understand it in 5 seconds?
- [ ] No text overlaps or visual collisions
- [ ] Minimum 8px between all text elements
- [ ] Colors match the system (green=input, purple=process, orange=output)
- [ ] Labels are adjacent to what they describe (spatial contiguity)
- [ ] Flow direction is obvious (arrows, left-to-right)
- [ ] Maximum 3-4 visual regions/groups
- [ ] Typography uses only 3 sizes (label, body, hero)
- [ ] Accessible: has aria-label describing the diagram's teaching point
- [ ] Dark mode: all colors readable on #0a0a0f background
- [ ] No decorative elements that don't teach

---

## 7. PRODUCTION PROMPT TEMPLATE

When generating SVG diagrams, use this prompt structure:

```
Create an SVG educational diagram for the Like One Academy.

CONCEPT: [what the diagram teaches]
TYPE: [flow / comparison / architecture / formula / before-after / concept-map]
KEY TAKEAWAY: [the one thing the learner should understand]

STYLE:
- viewBox: 480x[200|280]
- Background: graph-paper grid (rgba(255,255,255,.03), 20px spacing)
- Colors: green #34d399 (inputs), purple #c084fc (processing),
  orange #fb923c (outputs), blue #38bdf8 (connections),
  red #ef4444 (errors), muted #71717a (labels), white #e5e5e5 (values)
- Font: SF Mono, monospace. Labels 8-9px uppercase. Body 10-11px. Hero 14px+ bold.
- Shapes: unfilled circles for nodes, rounded rects for processes
- Spacing: 8px min between text, 12px from edges
- ONE focal point highlighted (largest + brightest element)

ACCESSIBILITY: Include aria-label that describes the teaching point.
```
