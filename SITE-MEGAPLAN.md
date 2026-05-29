# SITE MEGAPLAN — What's Left to Ship

## Current State
- 52 courses, 518 lessons, all served from Swift/Vapor on Fly.io
- 40 lessons have TAILORED v3 visuals (lo-vis, lo-steps, lo-versus, lo-calc)
- 481 lessons have PLACEHOLDER v3 visuals (generic Concept/Apply/Build steps)
- Quiz + flashcard system BUILT (sequential, score, dots, study mode)
- Blog, search, auth, progress tracking all working locally
- **Live site is STALE** — needs deploy to get visuals + search + fixes live

---

## PRIORITY 1: Deploy Current Code
- [ ] Fix lesson count mismatch (DONE locally)
- [ ] Push to Fly.io — gets 40 tailored visuals + search + fixes live
- [ ] Verify all routes work on production

## PRIORITY 2: Replace Placeholder Visuals (481 lessons)
The real work. Each placeholder currently shows generic "Concept / Apply / Build" steps.
Replace with TAILORED v3 visuals that teach the specific lesson concept.

### Visual Types (v3 — all static, all CSS)
| Type | Class | Use |
|------|-------|-----|
| Steps | `lo-steps` | Process flows, numbered sequences |
| Versus | `lo-versus` | Before/after, good/bad comparisons |
| Calc | `lo-calc` | Math layouts, formula breakdowns |
| Flow | `lo-flow` | Data pipelines, architecture |
| Compare | `lo-compare` | Side-by-side feature comparison |
| Compute | `lo-compute` | Computation chains |
| Visual | `lo-vis` | General wrapper with title + caption |

### Plus: SVG Diagrams
For concepts that need actual diagrams (network architectures, node connections, activation function curves):
- Inline SVG, graph-paper grid bg
- Color system: green=input, purple=process, orange=output, blue=connections
- viewBox 480x200 (standard) or 480x280 (tall)
- Per DIAGRAM-GUIDE.md rules

### Replacement Priority
| Course | Lessons | Status | Priority |
|--------|---------|--------|----------|
| claude-agent-sdk | 10 | placeholder | P0 |
| computer-use-agents | 10 | placeholder | P0 |
| ai-for-personal-productivity | 10 | placeholder | P0 |
| prompt-writing-101 | 10 | tailored | DONE |
| ai-foundations | 9 | tailored | DONE |
| vibe-coding | 10 | tailored | DONE |
| mcp-masterclass | 9 | tailored | DONE |
| Remaining 45 courses | ~459 | placeholder | P1-P3 |

### Batch Process (per course)
1. Read all lesson HTML for course
2. For each lesson section, design appropriate v3 visual
3. Replace placeholder with tailored visual
4. Verify rendering locally
5. Push

## PRIORITY 3: Missing Pages
| Page | Route | What |
|------|-------|------|
| About | `/about` | Founder story, mission, built in public |
| Pricing | `/pricing` | Free tier, future pro features |
| Foundation | `/foundation` | 501(c)(3), giving, HIV cure mission |

## PRIORITY 4: SEO Fixes
- [ ] Add `og:image` to all pages (static default image)
- [ ] Fix canonical URLs (currently points to likeone.ai, site is at fly.dev)
- [ ] Add structured data (JSON-LD for courses)
- [ ] Submit academy pages to GSC for indexing

## PRIORITY 5: Certification System
- Learning tracks (group courses into paths)
- Completion tracking (server-side, not just localStorage)
- Certificate generation (WeasyPrint PDF)
- Share to LinkedIn / social
- Celebration page with confetti

## PRIORITY 6: Homepage Polish
- Fix count-up animation (works but shows mid-values on fast load)
- Consider Three.js hero (later sprint)
- Parallax already working

## PRIORITY 7: DNS Cutover
- Plan: likeone.ai → swift.likeone.ai (or direct)
- Cloudflare tunnel config
- SSL
- Redirects from old Vercel routes

---

## NOT DOING (keep it simple)
- Alpine.js interactive widgets (one prototype exists, that's enough)
- Lottie animations
- Rive / Spline / 3D elements (maybe later for hero only)
- React components
- AI-generated raster images
- Over-engineered diagram systems

## THE RULE
Every visual exists to TEACH, not to decorate.
Static. Beautiful. Precise. v3.
Code with love.
