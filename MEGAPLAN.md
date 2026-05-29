# SWIFT MEGAPLAN — Build for Long Term
## Smallest Changes with Ease. Apple UX Through and Through. Code with Love.
### S220 | May 29, 2026

---

## ARCHITECTURE DECISION

### Three Approaches Evaluated

| Criteria (weight) | A: Fluent+Postgres | B: SQLite+Sessions | C: SwiftData+CloudKit |
|---|---|---|---|
| Quality (30%) | 9 | 7 | 8 |
| Feasibility (25%) | 7 | 9 | 5 |
| Convergence (20%) | 8 | 7 | 6 |
| Reversibility (15%) | 7 | 8 | 5 |
| Speed (10%) | 6 | 9 | 4 |
| **SCORE** | **7.70** | **7.85** | **6.00** |

### WINNER: Hybrid B+A

**Fluent ORM with SQLite driver NOW. Swap to PostgreSQL when scale demands.**

One config line changes the database. Fluent gives us:
- Type-safe queries (no raw SQL for user data)
- Automatic migrations (add a field = add a property + migration file)
- Model validation built-in
- Async/await native

**Raw SQLite stays for brain data** (our format, our rules, performance-critical).

---

## THE PRINCIPLE: Smallest Changes with Ease

Every file has ONE job. Every change touches ONE file. Every file is under 100 lines.

Current state: 1,537 lines in 16 files (avg 96 lines). Good baseline.
Target: ~40 files averaging ~60 lines each. Same functionality, 4x more navigable.

---

## FILE STRUCTURE (target)

```
Sources/
  LOCore/
    Models/
      User.swift              # user entity (~30 lines)
      Course.swift            # course entity (~40 lines)
      Lesson.swift            # lesson entity (~25 lines)
      BlogPost.swift          # blog entity (~30 lines)
      Product.swift           # product entity (~30 lines)
      Progress.swift          # learning progress (~15 lines)
      BrainEntry.swift        # brain entry (~25 lines)
      Subscription.swift      # tiers + auth providers (~20 lines)
    Protocols/
      ContentProviding.swift  # protocol for content sources
      Authenticating.swift    # protocol for auth providers

  LOBrain/
    BrainClient.swift         # protocol only (~20 lines)
    LocalBrainClient.swift    # SQLite implementation (~100 lines)
    RemoteBrainClient.swift   # HTTP client (~50 lines)
    SQLiteHelpers.swift       # low-level C bridge helpers (~60 lines)

  LOAuth/
    AppleAuth.swift           # Sign in with Apple JWT (~77 lines)
    SessionManager.swift      # Vapor session management (~50 lines)
    AuthMiddleware.swift      # route protection (~30 lines)
    Base64URL.swift           # Data extension (~10 lines)

  LODesign/
    Tokens.swift              # color, spacing, radius, font tokens
    SwiftUIColors.swift       # Color extensions from tokens
    Components/
      LOButton.swift          # primary/secondary/ghost buttons
      LOCard.swift            # content cards
      LOTextField.swift       # accessible text input
      LOLoadingView.swift     # loading states
    Modifiers/
      AccessibilityModifiers.swift  # VoiceOver, Dynamic Type helpers
      AnimationModifiers.swift      # Reduce Motion respecting

  LOContent/
    CourseProvider.swift       # course loading + querying
    BlogProvider.swift         # blog post loading + querying
    ProductCatalog.swift       # product loading + querying
    LessonProvider.swift       # lesson loading per course (NEW)
    Data/
      courses.json            # 52 courses
      blogs.json              # 16 blog posts
      products.json           # 10 products
      lessons/                # per-course lesson JSON files (NEW)

  LOServer/
    LOServer.swift            # @main entrypoint
    configure.swift           # Leaf, middleware, Fluent setup
    Controllers/
      HomeController.swift    # / (SSR)
      AcademyController.swift # /academy routes (SSR + API)
      BlogController.swift    # /blog routes (SSR + API)
      ProductController.swift # /products routes (SSR + API)
      BrainController.swift   # /api/v1/brain/* (API only)
      AuthController.swift    # /auth/* flows
      StripeController.swift  # /stripe/webhook, billing
      APIInfoController.swift # /api/info, /health
    Middleware/
      ErrorMiddleware.swift   # custom error pages
    DTOs/
      PageContexts.swift      # Leaf template contexts

  LOAcademyApp/               # iOS app (Phase 5)
    AcademyApp.swift
    Views/
      CourseListView.swift    # HIG: NavigationStack, 44pt targets
      CourseDetailView.swift  # HIG: .navigationTitle, Dynamic Type
      LessonView.swift        # HIG: semantic colors, Reduce Motion
      SettingsView.swift      # HIG: Form, grouped list style
    Services/
      APIClient.swift         # talks to LOServer
      OfflineStore.swift      # local lesson cache
```

---

## PHASE PLAN (revised for long-term)

### Phase 2a: RESTRUCTURE (this session)
Split monolithic files into single-responsibility files.
No new functionality. Same tests pass. Same API contract.
- [ ] Split Models.swift into 8 files (one per type)
- [ ] Split ContentProvider.swift into 3 files
- [ ] Split BrainClient.swift into 3 files (protocol, local, remote)
- [ ] Split routes.swift into Controllers/ directory
- [ ] Move DTOs out of routes.swift
- [ ] Extract Base64URL extension from AppleAuth.swift
- [ ] Run all 43 tests — must pass

### Phase 2b: FLUENT INTEGRATION
Add Fluent ORM with SQLite driver for user data.
- [ ] Add fluent + fluent-sqlite-driver dependencies
- [ ] Create User Fluent model + migration
- [ ] Create Session Fluent model + migration
- [ ] Create LearningProgress Fluent model + migration
- [ ] Configure Fluent in configure.swift
- [ ] SessionManager using Fluent
- [ ] Tests for user CRUD

### Phase 3: AUTH FLOW
End-to-end Sign in with Apple.
- [ ] Apple OAuth callback handler
- [ ] Session cookie management
- [ ] AuthMiddleware for protected routes
- [ ] /account page (authenticated)
- [ ] Tests for auth flow

### Phase 4: LESSON CONTENT
520+ lessons from Next.js data.
- [ ] Extract lesson data from lyra-app
- [ ] LessonProvider with per-course JSON loading
- [ ] /api/v1/courses/:slug/lessons endpoint
- [ ] /academy/:course/:lesson SSR route
- [ ] Lesson content rendered as HTML (Markdown)

### Phase 5: STRIPE INTEGRATION
Webhook handling + billing portal.
- [ ] Stripe webhook signature verification
- [ ] Subscription lifecycle events
- [ ] Billing portal redirect
- [ ] Product purchase flow
- [ ] Stripe customer linking to User

### Phase 6: WEB SURFACE
Leaf templates for every page.
- [ ] Academy page with course grid
- [ ] Course detail page with lesson list
- [ ] Lesson page with content
- [ ] Blog listing + detail pages
- [ ] Product pages
- [ ] About, pricing, terms, privacy
- [ ] HTMX progressive enhancement

### Phase 7: iOS ACADEMY APP
SwiftUI, HIG-compliant, App Store ready.
- [ ] Xcode project with LOCore, LOContent, LODesign deps
- [ ] CourseListView (NavigationStack, 44pt targets, Dynamic Type)
- [ ] CourseDetailView (lesson list, progress)
- [ ] LessonView (markdown rendering, offline cache)
- [ ] Sign in with Apple (native AuthenticationServices)
- [ ] Orchard HIG: all 22 rules pass on every view
- [ ] App Store submission

### Phase 8: FULL CONVERGENCE
Zero JavaScript. Pure Swift. DNS cutover.
- [ ] All Next.js routes migrated to Leaf
- [ ] DNS: likeone.ai -> Fly.io (Vapor)
- [ ] Next.js archived with gratitude
- [ ] CLI tools in Swift (LOTools)
- [ ] MCP servers ported to Swift

---

## HIG COMPLIANCE RULES (baked into architecture)

Every SwiftUI view MUST pass all 22 Orchard HIG rules:
- A1: .accessibilityLabel() on every interactive element
- A2: Dynamic Type only (.body, .headline, .title) — no fixed font sizes
- A3: @ScaledMetric for any custom dimensions
- A4: @Environment(\.accessibilityReduceMotion) respected
- T1: .frame(minWidth: 44, minHeight: 44) on all touch targets
- C1: Semantic colors from LODesign only — no Color.red, no hex in views
- G1: .glassEffect for floating UI (iOS 26+)
- S1: NavigationStack only (never NavigationView)
- S4: .navigationTitle on every screen

LODesign enforces these by providing pre-built components:
- LOButton: always 44pt+, always labeled, always semantic colors
- LOCard: always accessible, always adapts to Dynamic Type
- LOTextField: always labeled, always accessible

---

## TESTING STRATEGY

| Package | Current | Target | Focus |
|---------|---------|--------|-------|
| LOCore | 11 | 20 | model encoding, equality, edge cases |
| LOBrain | 5 | 15 | local read/write/search, remote fallback |
| LOContent | 9 | 20 | course loading, blog parsing, lesson lookup |
| LODesign | 6 | 15 | token values, CSS generation, color math |
| LOAuth | 5 | 15 | JWT generation, session lifecycle |
| LOServer | 7 | 25 | every route, auth flow, error handling |
| Total | 43 | 110 | |

---

## DEPLOYMENT ARCHITECTURE

```
                    likeone.ai (Vercel, current)
                         |
                         v
    [Phase 4-6: Vercel rewrites /api/* to Fly.io]
                         |
                         v
              likeone-swift.fly.dev
              (Vapor 4 + Leaf + HTMX)
              256MB shared-cpu-1x
                    |
         +----------+----------+
         |                     |
    SQLite (brain)      SQLite (users)
    local_brain.db      likeone.db
    [read-only on       [Fluent managed]
     server, or
     RemoteBrainClient]
                         |
              [Phase 8: DNS cutover]
              likeone.ai -> Fly.io directly
              Next.js retired
```

---

## GUARDIAN CHECKS

- [ ] No secrets in source code (API keys via environment variables)
- [ ] No deadname anywhere in codebase
- [ ] HTTPS only on all endpoints
- [ ] Stripe webhook signature verification
- [ ] Apple ID token validation
- [ ] Session cookies: HttpOnly, Secure, SameSite=Lax
- [ ] CORS restricted to likeone.ai
- [ ] Rate limiting on auth endpoints
- [ ] Input validation on all user-facing endpoints

---

*built with love. for the long term. like one.*
