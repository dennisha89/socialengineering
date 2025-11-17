# Follower Intelligence MVP - Wireframes

## Design Philosophy

**Goal**: Get users from upload to insights in < 60 seconds
**Inspiration**: Stripe (clarity), Notion (simplicity), Linear (speed)
**Mobile**: Responsive, but desktop-first (data-heavy use case)

---

## User Journey Map

```
┌─────────────────────────────────────────────────────────────┐
│  USER JOURNEY: From Zero to First Ad (5 minutes)           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. LAND → Dashboard (empty state)                         │
│     ↓                                                        │
│  2. CLICK → "Upload Followers" CTA                         │
│     ↓                                                        │
│  3. UPLOAD → CSV file (drag & drop)                        │
│     ↓                                                        │
│  4. WAIT → 10-30 seconds (AI analyzing)                    │
│     ↓                                                        │
│  5. SEE → Insights (top interests, demographics)           │
│     ↓                                                        │
│  6. CLICK → "Generate Ad" button                           │
│     ↓                                                        │
│  7. INPUT → Product/service description                    │
│     ↓                                                        │
│  8. WAIT → 5-10 seconds (AI generating)                    │
│     ↓                                                        │
│  9. GET → Personalized ad copy                             │
│     ↓                                                        │
│  10. COPY → Use in Facebook/Instagram ads                  │
│                                                             │
│  Total Time: ~5 minutes                                    │
│  User Delight Moments: Steps 5 (insights) & 9 (ad copy)   │
└─────────────────────────────────────────────────────────────┘
```

---

## Screen 1: Dashboard (Empty State)

```
┌──────────────────────────────────────────────────────────────────┐
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  [Logo] Follower Intelligence    [Dashboard] [History]   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                                                            │ │
│  │              👥 No Followers Analyzed Yet                 │ │
│  │                                                            │ │
│  │     Get AI-powered insights about your Instagram          │ │
│  │     followers and create personalized ads                 │ │
│  │                                                            │ │
│  │     ┌──────────────────────────────────────┐             │ │
│  │     │  📤 Upload Follower CSV              │  ← PRIMARY   │ │
│  │     └──────────────────────────────────────┘     CTA      │ │
│  │                                                            │ │
│  │              or watch 60-second demo                      │ │
│  │                                                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  How It Works                                            │   │
│  │                                                          │   │
│  │  1️⃣ Upload → CSV of followers                           │   │
│  │  2️⃣ Analyze → AI finds interests & demographics         │   │
│  │  3️⃣ Generate → Personalized ad copy in seconds          │   │
│  │                                                          │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘

DESIGN NOTES:
- Big, clear CTA (can't miss it)
- Explain value prop immediately
- Show it's simple (3 steps)
- Empty state is friendly, not intimidating
```

---

## Screen 2: Dashboard (With Data)

```
┌──────────────────────────────────────────────────────────────────┐
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  [Logo] Follower Intelligence    [Dashboard] [History]   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Dashboard                                    [+ Upload More]    │
│  ────────────────────────────────────────────────────────────   │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ 📊 ANALYSES  │  │ 📢 ADS       │  │ 👥 FOLLOWERS │          │
│  │              │  │              │  │              │          │
│  │     12       │  │     34       │  │   15,420     │          │
│  │              │  │              │  │              │          │
│  │  +2 this wk  │  │  +8 this wk  │  │  analyzed    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                  │
│  Recent Analyses                                                 │
│  ────────────────────────────────────────────────────────────   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ @fitness_coach                           2 hours ago       │ │
│  │ 1,234 followers                                            │ │
│  │                                                            │ │
│  │ Top Interests: Fitness (32%), Nutrition (28%), Yoga (18%) │ │
│  │                                                            │ │
│  │ [View Details]  [Generate Ad →]                           │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ @travel_blogger                          1 day ago         │ │
│  │ 3,420 followers                                            │ │
│  │                                                            │ │
│  │ Top Interests: Travel (40%), Photography (25%), Food (15%)│ │
│  │                                                            │ │
│  │ [View Details]  [Generate Ad →]                           │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

DESIGN NOTES:
- Stats at top (quick dopamine hit)
- Recent analyses = easy access to generate more ads
- Clear CTAs on each item
- Scannable (can find what you need in 2 seconds)
```

---

## Screen 3: Upload Flow

```
┌──────────────────────────────────────────────────────────────────┐
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  [Logo] Follower Intelligence    [Dashboard] [History]   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Analyze Followers                                               │
│  ────────────────────────────────────────────────────────────   │
│                                                                  │
│  ┌─────────────────────────────┐  ┌────────────────────────┐    │
│  │                             │  │                        │    │
│  │  Step 1: Upload CSV         │  │  Instructions          │    │
│  │  ───────────────────────    │  │  ──────────────────    │    │
│  │                             │  │                        │    │
│  │  ┌───────────────────────┐  │  │  CSV Format:          │    │
│  │  │                       │  │  │                        │    │
│  │  │     📤                │  │  │  username,bio,         │    │
│  │  │                       │  │  │  follower_count        │    │
│  │  │  Drag & drop CSV      │  │  │                        │    │
│  │  │  or click to browse   │  │  │  Example:             │    │
│  │  │                       │  │  │  john,Fitness fan,500  │    │
│  │  │  Max 10,000 rows      │  │  │                        │    │
│  │  │                       │  │  │  [Download Sample]     │    │
│  │  └───────────────────────┘  │  │                        │    │
│  │                             │  │  How to get data:      │    │
│  │  Selected: followers.csv    │  │  • Export from Insta   │    │
│  │  (256 KB, 1,234 rows)       │  │  • Use scraper tool    │    │
│  │                             │  │  • Manual entry        │    │
│  │  ┌───────────────────────┐  │  │                        │    │
│  │  │  Analyze Followers    │  │  │  Cost: ~$0.50         │    │
│  │  └───────────────────────┘  │  │  Time: ~30 seconds    │    │
│  │         ↑ PRIMARY CTA       │  │                        │    │
│  └─────────────────────────────┘  └────────────────────────┘    │
│                                                                  │
│  ⚠️  We analyze your first 100 followers to keep costs low      │
│     Upgrade to Pro to analyze all followers                     │
└──────────────────────────────────────────────────────────────────┘

DESIGN NOTES:
- Left side = action, right side = help
- Drag & drop is primary interaction
- Show what you'll get before upload (cost, time)
- File validation feedback immediately
- Help is always visible (reduce support)
```

---

## Screen 4: Analysis Results

```
┌──────────────────────────────────────────────────────────────────┐
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  [Logo] Follower Intelligence    [Dashboard] [History]   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ← Back to Dashboard                                             │
│                                                                  │
│  Analysis: @fitness_coach                      [Generate Ad →]   │
│  ════════════════════════════════════════════════════════════   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  📊 Overview                                               │ │
│  │  ──────────────────────────────────────────────────────    │ │
│  │                                                            │ │
│  │  Analyzed: 100 of 1,234 followers                         │ │
│  │  Cost: $0.48                                               │ │
│  │                                                            │ │
│  │  Your audience is primarily fitness enthusiasts aged      │ │
│  │  25-34 who care about health, nutrition, and personal     │ │
│  │  growth. They're motivated by transformation stories      │ │
│  │  and practical tips.                                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  🎯 Top Interests                                          │ │
│  │                                                            │ │
│  │  [Fitness: 32%]  [Nutrition: 28%]  [Yoga: 18%]           │ │
│  │  [Mindfulness: 12%]  [Wellness: 10%]                      │ │
│  │                                                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌──────────────────────┐  ┌────────────────────────────────┐  │
│  │  📍 Demographics     │  │  💡 Best Ad Angles            │  │
│  │                      │  │                                │  │
│  │  Age: 25-34 (45%)   │  │  • Before/after               │  │
│  │       18-24 (30%)   │  │    transformations            │  │
│  │       35-44 (25%)   │  │                                │  │
│  │                      │  │  • Quick home workouts        │  │
│  │  Locations:          │  │                                │  │
│  │  🇺🇸 USA (60%)       │  │  • Nutrition hacks            │  │
│  │  🇬🇧 UK (20%)        │  │                                │  │
│  │  🇨🇦 Canada (12%)    │  │  • Personal coaching          │  │
│  │                      │  │                                │  │
│  └──────────────────────┘  └────────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                  [🎯 Generate Targeted Ad]                 │ │
│  │                         ↑ PRIMARY CTA                      │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

DESIGN NOTES:
- Most important info at top (summary)
- Visual interest tags (easy to scan)
- Demographics & ad angles side-by-side
- BIG "Generate Ad" button (that's why they're here)
- Can see insights instantly (no digging)
```

---

## Screen 5: Ad Generation Modal

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │                                                          │  │
│   │  Generate Ad                                      [X]    │  │
│   │  ════════════════════════════════════════════════════    │  │
│   │                                                          │  │
│   │  Based on: @fitness_coach analysis                      │  │
│   │  ────────────────────────────────────────────────────    │  │
│   │                                                          │  │
│   │  What are you promoting?                                │  │
│   │  ┌────────────────────────────────────────────────────┐ │  │
│   │  │ Online fitness coaching for busy professionals    │ │  │
│   │  └────────────────────────────────────────────────────┘ │  │
│   │                                                          │  │
│   │  Ad Tone                                                │  │
│   │  ┌────────────────────────────────────────────────────┐ │  │
│   │  │ [Casual ▼] [Professional] [Enthusiastic]          │ │  │
│   │  └────────────────────────────────────────────────────┘ │  │
│   │                                                          │  │
│   │  Optional: Additional context                           │  │
│   │  ┌────────────────────────────────────────────────────┐ │  │
│   │  │ 12-week program, $199, includes meal plans        │ │  │
│   │  └────────────────────────────────────────────────────┘ │  │
│   │                                                          │  │
│   │  ┌────────────────────────────────────────────────────┐ │  │
│   │  │           Generate Ad Copy (5 seconds)             │ │  │
│   │  └────────────────────────────────────────────────────┘ │  │
│   │                                                          │  │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

DESIGN NOTES:
- Modal keeps context (don't lose analysis)
- Minimal fields (don't overthink it)
- Optional fields are actually optional
- Clear what happens next (5 seconds)
```

---

## Screen 6: Generated Ad Result

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │                                                          │  │
│   │  Your Ad Is Ready! 🎉                             [X]    │  │
│   │  ════════════════════════════════════════════════════    │  │
│   │                                                          │  │
│   │  ┌────────────────────────────────────────────────────┐ │  │
│   │  │                                                    │ │  │
│   │  │  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │ │  │
│   │  │  ┃  AD PREVIEW (Instagram/Facebook)          ┃ │ │  │
│   │  │  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │ │  │
│   │  │                                                    │ │  │
│   │  │  HEADLINE:                                         │ │  │
│   │  │  ──────────                                        │ │  │
│   │  │  Transform Your Body in Just 12 Minutes a Day     │ │  │
│   │  │                                                    │ │  │
│   │  │  PRIMARY TEXT:                                     │ │  │
│   │  │  ────────────                                      │ │  │
│   │  │  Busy professional? No time for the gym?          │ │  │
│   │  │                                                    │ │  │
│   │  │  Our 12-week coaching program is designed for     │ │  │
│   │  │  people like you - quick home workouts, meal      │ │  │
│   │  │  plans that fit your schedule, and personal       │ │  │
│   │  │  support when you need it.                        │ │  │
│   │  │                                                    │ │  │
│   │  │  Join 1,000+ professionals who've transformed     │ │  │
│   │  │  their health without sacrificing their career.   │ │  │
│   │  │                                                    │ │  │
│   │  │  [ Start Your Transformation → ]                  │ │  │
│   │  │                                                    │ │  │
│   │  └────────────────────────────────────────────────────┘ │  │
│   │                                                          │  │
│   │  💡 Why this works:                                     │  │
│   │  ──────────────────                                     │  │
│   │  Speaks to your audience's #1 pain point (no time)     │  │
│   │  and offers a realistic solution with social proof.    │  │
│   │                                                          │  │
│   │  ┌───────────────┐  ┌──────────────┐  ┌─────────────┐  │  │
│   │  │ Copy to       │  │ Regenerate   │  │ Save        │  │  │
│   │  │ Clipboard     │  │              │  │             │  │  │
│   │  └───────────────┘  └──────────────┘  └─────────────┘  │  │
│   │                                                          │  │
│   │  Want to generate another angle? [Generate Variant]     │  │
│   │                                                          │  │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

DESIGN NOTES:
- Ad shown in realistic preview (looks like real ad)
- Explanation of WHY it works (educate user)
- Multiple actions (copy, regenerate, save)
- Encourage experimentation (variants)
- Success state (🎉 celebration)
```

---

## Screen 7: History View

```
┌──────────────────────────────────────────────────────────────────┐
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  [Logo] Follower Intelligence    [Dashboard] [History]   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  History                                       [Upload More →]   │
│  ────────────────────────────────────────────────────────────   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ @fitness_coach                     📊 Analysis  2 hrs ago  │ │
│  │ ──────────────────────────────────────────────────────────│ │
│  │                                                            │ │
│  │ 1,234 followers analyzed                                  │ │
│  │ Top interests: Fitness, Nutrition, Yoga                   │ │
│  │                                                            │ │
│  │ Generated Ads (3):                                         │ │
│  │ • "Transform Your Body in 12 Minutes"  [View] [Copy]     │ │
│  │ • "Meal Plans for Busy Professionals" [View] [Copy]      │ │
│  │ • "Get Fit Without a Gym Membership"  [View] [Copy]      │ │
│  │                                                            │ │
│  │ [View Full Analysis]  [Generate Another Ad →]            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ @travel_blogger                    📊 Analysis  1 day ago  │ │
│  │ ──────────────────────────────────────────────────────────│ │
│  │                                                            │ │
│  │ 3,420 followers analyzed                                  │ │
│  │ Top interests: Travel, Photography, Food                  │ │
│  │                                                            │ │
│  │ Generated Ads (1):                                         │ │
│  │ • "Capture Memories That Last Forever" [View] [Copy]     │ │
│  │                                                            │ │
│  │ [View Full Analysis]  [Generate Another Ad →]            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ @eco_products                      📊 Analysis  3 days ago │ │
│  │ ──────────────────────────────────────────────────────────│ │
│  │                                                            │ │
│  │ 892 followers analyzed                                    │ │
│  │ Top interests: Sustainability, Lifestyle, Wellness        │ │
│  │                                                            │ │
│  │ No ads generated yet                                       │ │
│  │                                                            │ │
│  │ [View Full Analysis]  [Generate Your First Ad →]         │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

DESIGN NOTES:
- Reverse chronological (most recent first)
- See all ads for each analysis (no clicking around)
- Quick actions (View, Copy) directly accessible
- Clear which analyses have ads
- Encourage generating more ads
```

---

## Mobile Wireframes

### Mobile Dashboard
```
┌─────────────────────┐
│  ☰  Follower Intel  │
├─────────────────────┤
│                     │
│  ┌───────────────┐  │
│  │ 📊 Analyses   │  │
│  │     12        │  │
│  └───────────────┘  │
│                     │
│  ┌───────────────┐  │
│  │ 📢 Ads        │  │
│  │     34        │  │
│  └───────────────┘  │
│                     │
│  ┌───────────────┐  │
│  │ 👥 Followers  │  │
│  │   15,420      │  │
│  └───────────────┘  │
│                     │
│  Recent             │
│  ─────              │
│  @fitness_coach     │
│  1,234 followers    │
│  [View] [Gen Ad]    │
│                     │
│  @travel_blogger    │
│  3,420 followers    │
│  [View] [Gen Ad]    │
│                     │
│  [+ Upload More]    │
│                     │
└─────────────────────┘

DESIGN NOTES:
- Stack cards vertically
- Touch-friendly buttons
- Collapsible menu (hamburger)
- Priority on stats & recent
```

---

## Design System Specs

### Colors
```
Primary:    #667eea (Purple-blue)
Secondary:  #764ba2 (Purple)
Success:    #10b981 (Green)
Warning:    #f59e0b (Orange)
Error:      #ef4444 (Red)
Gray:       #6b7280 (Neutral)

Background: #f9fafb (Light gray)
Surface:    #ffffff (White)
Border:     #e5e7eb (Light border)
```

### Typography
```
Headings:   Inter / SF Pro (system font)
Body:       Inter / SF Pro
Monospace:  Fira Code (for code samples)

H1: 2.5rem (40px), Bold
H2: 2rem (32px), Bold
H3: 1.5rem (24px), Semibold
Body: 1rem (16px), Regular
Small: 0.875rem (14px), Regular
```

### Spacing
```
Unit: 4px base

xs: 4px
sm: 8px
md: 16px
lg: 24px
xl: 32px
2xl: 48px
```

### Components
```
Border Radius: 8px (cards), 4px (buttons)
Shadow: 0 1px 3px rgba(0,0,0,0.1)
Button Height: 44px (touch-friendly)
Input Height: 44px
Card Padding: 24px
```

---

## Interaction States

### Buttons
```
Default:  Gradient background, white text
Hover:    Slightly darker, lift up 1px
Active:   Pressed down, darker
Disabled: Gray, 50% opacity
Loading:  Spinner, disabled
```

### Cards
```
Default:  White, subtle shadow
Hover:    Lift shadow, border highlight
Active:   Clicked effect
Selected: Blue border, blue tint
```

### Inputs
```
Default:  Gray border
Focus:    Blue border, blue ring
Error:    Red border, red text
Success:  Green border
Disabled: Gray background
```

---

## Animation Principles

**Speed**: Fast (200ms) for micro-interactions
**Easing**: ease-out for entry, ease-in for exit
**Purpose**: Only animate meaningful changes

Examples:
- Modal enter: fade + slide up (300ms)
- Button hover: lift (150ms)
- Loading: spin (infinite, 1s)
- Success: scale + fade (400ms)

---

## Accessibility

- ✅ WCAG 2.1 AA contrast ratios
- ✅ Keyboard navigation (Tab, Enter, Esc)
- ✅ Screen reader labels (aria-labels)
- ✅ Focus indicators visible
- ✅ Error messages announced
- ✅ Touch targets minimum 44x44px

---

## Key UX Decisions & Rationale

### 1. Dashboard-First, Not Upload-First
**Why**: Show value immediately (stats) before asking for work

### 2. Inline Ad Generation
**Why**: Don't make users navigate away from insights

### 3. Show Cost Upfront
**Why**: Transparency builds trust, no surprises

### 4. Preview Before Generate
**Why**: Users want to know what they're getting

### 5. Multiple CTAs for Same Action
**Why**: Different mental models = different entry points

### 6. "Why This Works" Explanations
**Why**: Educate users, build trust in AI

### 7. Copy to Clipboard, Not Download
**Why**: Faster workflow, paste directly into ad manager

### 8. Empty States Are Inviting
**Why**: Don't make users feel lost, guide them

---

## Design References

**Inspiration Sources:**
1. **Stripe Dashboard**: Clean data visualization
2. **Notion**: Friendly empty states
3. **Linear**: Fast, responsive feel
4. **Superhuman**: Keyboard shortcuts
5. **Framer**: Smooth animations

**What I Borrowed:**
- Stripe: Card-based layout for stats
- Notion: Friendly, conversational copy
- Linear: Minimalist navigation
- Superhuman: Speed as a feature
- Framer: Gradient buttons

---

## Next: Visual Mockups

After you approve these wireframes, I'll create:

1. **High-fidelity mockups** (Figma-style visual designs)
2. **Component library** (reusable UI elements)
3. **Responsive breakpoints** (mobile, tablet, desktop)
4. **User flow diagrams** (detailed click-through)

---

**Questions for You:**

1. Do these flows make sense?
2. Any screens missing?
3. Does the mobile-first vs desktop-first decision work?
4. Should we add any features to MVP?
5. Ready for visual mockups, or revise wireframes?
