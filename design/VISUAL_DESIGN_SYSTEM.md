# Visual Design System - Follower Intelligence MVP

## Brand Identity

### Brand Personality
- **Modern**: Clean, contemporary design
- **Trustworthy**: Professional but approachable
- **Intelligent**: Data-driven, AI-powered
- **Efficient**: Fast, streamlined workflows

### Voice & Tone
- **Clear**: No jargon, simple language
- **Confident**: AI that delivers results
- **Helpful**: Guiding, not gatekeeping
- **Casual**: Friendly, conversational

---

## Color Palette

### Primary Colors
```css
--primary-600: #667eea    /* Main brand color - buttons, links */
--primary-700: #5a67d8    /* Hover states */
--primary-800: #4c51bf    /* Active states */
--primary-900: #434190    /* Dark accent */

/* Gradient */
--gradient-primary: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
--gradient-light: linear-gradient(135deg, #a8b3ff 0%, #b794f6 100%);
```

### Secondary Colors
```css
--secondary-500: #764ba2   /* Purple accent */
--secondary-600: #6b46c1   /* Hover */
--secondary-700: #553c9a   /* Active */
```

### Semantic Colors
```css
/* Success */
--success-50: #ecfdf5
--success-100: #d1fae5
--success-500: #10b981
--success-600: #059669
--success-700: #047857

/* Warning */
--warning-50: #fffbeb
--warning-100: #fef3c7
--warning-500: #f59e0b
--warning-600: #d97706
--warning-700: #b45309

/* Error */
--error-50: #fef2f2
--error-100: #fee2e2
--error-500: #ef4444
--error-600: #dc2626
--error-700: #b91c1c

/* Info */
--info-50: #eff6ff
--info-100: #dbeafe
--info-500: #3b82f6
--info-600: #2563eb
--info-700: #1d4ed8
```

### Neutral Grays
```css
--gray-50: #f9fafb    /* Page background */
--gray-100: #f3f4f6   /* Card background */
--gray-200: #e5e7eb   /* Borders */
--gray-300: #d1d5db   /* Disabled elements */
--gray-400: #9ca3af   /* Placeholder text */
--gray-500: #6b7280   /* Secondary text */
--gray-600: #4b5563   /* Primary text */
--gray-700: #374151   /* Headings */
--gray-800: #1f2937   /* Dark headings */
--gray-900: #111827   /* Black */
```

### Special Colors
```css
--instagram-gradient: linear-gradient(45deg, #f09433 0%,#e6683c 25%,#dc2743 50%,#cc2366 75%,#bc1888 100%);
--facebook-blue: #1877f2;
--twitter-blue: #1da1f2;
```

---

## Typography

### Font Families
```css
/* Primary Font */
--font-sans: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI',
             'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', sans-serif;

/* Monospace (for code/data) */
--font-mono: 'Fira Code', 'Courier New', monospace;

/* Numbers (for stats) */
--font-numbers: 'Inter', tabular-nums, sans-serif;
```

### Type Scale
```css
/* Display (Hero text) */
--text-display: 3rem;       /* 48px */
--line-display: 1.1;

/* Headings */
--text-h1: 2.5rem;          /* 40px */
--line-h1: 1.2;
--weight-h1: 700;

--text-h2: 2rem;            /* 32px */
--line-h2: 1.25;
--weight-h2: 700;

--text-h3: 1.5rem;          /* 24px */
--line-h3: 1.33;
--weight-h3: 600;

--text-h4: 1.25rem;         /* 20px */
--line-h4: 1.4;
--weight-h4: 600;

/* Body */
--text-body-lg: 1.125rem;   /* 18px */
--text-body: 1rem;          /* 16px */
--text-body-sm: 0.875rem;   /* 14px */
--text-body-xs: 0.75rem;    /* 12px */

--line-body: 1.5;
--weight-body: 400;

/* Special */
--weight-semibold: 600;
--weight-bold: 700;
--weight-light: 300;
```

### Letter Spacing
```css
--tracking-tight: -0.025em;   /* Headings */
--tracking-normal: 0;         /* Body */
--tracking-wide: 0.025em;     /* Buttons, labels */
```

---

## Spacing System

### Base Unit: 4px

```css
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-5: 1.25rem;   /* 20px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */
--space-10: 2.5rem;   /* 40px */
--space-12: 3rem;     /* 48px */
--space-16: 4rem;     /* 64px */
--space-20: 5rem;     /* 80px */
```

### Component Spacing
```css
/* Card padding */
--card-padding: var(--space-6);        /* 24px */
--card-padding-sm: var(--space-4);     /* 16px */

/* Section spacing */
--section-spacing: var(--space-12);    /* 48px */
--section-spacing-sm: var(--space-8);  /* 32px */

/* Element spacing */
--element-gap: var(--space-4);         /* 16px */
--element-gap-sm: var(--space-2);      /* 8px */
```

---

## Border Radius

```css
--radius-sm: 0.25rem;    /* 4px - inputs, badges */
--radius-md: 0.5rem;     /* 8px - buttons, cards */
--radius-lg: 0.75rem;    /* 12px - modals */
--radius-xl: 1rem;       /* 16px - feature cards */
--radius-full: 9999px;   /* Full circle */
```

---

## Shadows

### Elevation System
```css
/* Subtle (resting cards) */
--shadow-xs: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
--shadow-sm: 0 1px 3px 0 rgba(0, 0, 0, 0.1),
             0 1px 2px 0 rgba(0, 0, 0, 0.06);

/* Standard (cards, dropdowns) */
--shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1),
             0 2px 4px -1px rgba(0, 0, 0, 0.06);

/* Raised (modals, popovers) */
--shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1),
             0 4px 6px -2px rgba(0, 0, 0, 0.05);

/* Floating (high elevation) */
--shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1),
             0 10px 10px -5px rgba(0, 0, 0, 0.04);

/* Dramatic (hero elements) */
--shadow-2xl: 0 25px 50px -12px rgba(0, 0, 0, 0.25);

/* Colored shadows for emphasis */
--shadow-primary: 0 10px 40px -10px rgba(102, 126, 234, 0.4);
--shadow-success: 0 10px 40px -10px rgba(16, 185, 129, 0.3);
```

### Glow Effects
```css
--glow-primary: 0 0 20px rgba(102, 126, 234, 0.5);
--glow-success: 0 0 20px rgba(16, 185, 129, 0.5);
```

---

## Component Library

### Buttons

#### Primary Button
```css
.btn-primary {
    background: var(--gradient-primary);
    color: white;
    padding: 12px 24px;
    border-radius: var(--radius-md);
    font-weight: var(--weight-semibold);
    font-size: var(--text-body);
    letter-spacing: var(--tracking-wide);
    box-shadow: var(--shadow-sm);
    transition: all 0.2s ease;
}

.btn-primary:hover {
    transform: translateY(-1px);
    box-shadow: var(--shadow-md);
    opacity: 0.95;
}

.btn-primary:active {
    transform: translateY(0);
    box-shadow: var(--shadow-xs);
}
```

#### Secondary Button
```css
.btn-secondary {
    background: white;
    color: var(--primary-600);
    border: 2px solid var(--primary-600);
    padding: 10px 22px;
    border-radius: var(--radius-md);
    font-weight: var(--weight-semibold);
}

.btn-secondary:hover {
    background: var(--primary-50);
    border-color: var(--primary-700);
}
```

#### Ghost Button
```css
.btn-ghost {
    background: transparent;
    color: var(--gray-700);
    padding: 12px 24px;
    border-radius: var(--radius-md);
}

.btn-ghost:hover {
    background: var(--gray-100);
}
```

### Cards

#### Standard Card
```css
.card {
    background: white;
    border-radius: var(--radius-lg);
    padding: var(--card-padding);
    box-shadow: var(--shadow-sm);
    border: 1px solid var(--gray-200);
    transition: all 0.2s ease;
}

.card:hover {
    box-shadow: var(--shadow-md);
    transform: translateY(-2px);
}
```

#### Stat Card
```css
.stat-card {
    background: white;
    border-radius: var(--radius-lg);
    padding: var(--space-6);
    box-shadow: var(--shadow-sm);
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.stat-card__icon {
    width: 48px;
    height: 48px;
    border-radius: var(--radius-md);
    display: flex;
    align-items: center;
    justify-content: center;
}

.stat-card__value {
    font-size: var(--text-h1);
    font-weight: var(--weight-bold);
    color: var(--gray-900);
    font-variant-numeric: tabular-nums;
}

.stat-card__label {
    font-size: var(--text-body-sm);
    color: var(--gray-600);
}
```

### Inputs

#### Text Input
```css
.input {
    width: 100%;
    padding: 12px 16px;
    border: 1px solid var(--gray-300);
    border-radius: var(--radius-md);
    font-size: var(--text-body);
    color: var(--gray-900);
    background: white;
    transition: all 0.2s ease;
}

.input:focus {
    outline: none;
    border-color: var(--primary-500);
    box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.input::placeholder {
    color: var(--gray-400);
}

.input--error {
    border-color: var(--error-500);
}

.input--error:focus {
    box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.1);
}
```

### Badges

```css
.badge {
    display: inline-flex;
    align-items: center;
    padding: 4px 12px;
    border-radius: var(--radius-full);
    font-size: var(--text-body-sm);
    font-weight: var(--weight-semibold);
}

.badge--primary {
    background: var(--primary-100);
    color: var(--primary-700);
}

.badge--success {
    background: var(--success-100);
    color: var(--success-700);
}

.badge--warning {
    background: var(--warning-100);
    color: var(--warning-700);
}
```

### Modals

```css
.modal-overlay {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.5);
    backdrop-filter: blur(4px);
    z-index: 50;
}

.modal {
    background: white;
    border-radius: var(--radius-xl);
    box-shadow: var(--shadow-2xl);
    max-width: 600px;
    width: 90%;
    max-height: 90vh;
    overflow-y: auto;
    animation: modalEnter 0.3s ease-out;
}

@keyframes modalEnter {
    from {
        opacity: 0;
        transform: translateY(20px) scale(0.95);
    }
    to {
        opacity: 1;
        transform: translateY(0) scale(1);
    }
}
```

---

## Animation & Transitions

### Duration
```css
--duration-fast: 150ms;
--duration-base: 200ms;
--duration-slow: 300ms;
--duration-slower: 500ms;
```

### Easing
```css
--ease-in: cubic-bezier(0.4, 0, 1, 1);
--ease-out: cubic-bezier(0, 0, 0.2, 1);
--ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
--ease-bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55);
```

### Common Animations
```css
/* Fade in */
@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}

/* Slide up */
@keyframes slideUp {
    from {
        opacity: 0;
        transform: translateY(10px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

/* Scale in */
@keyframes scaleIn {
    from {
        opacity: 0;
        transform: scale(0.95);
    }
    to {
        opacity: 1;
        transform: scale(1);
    }
}

/* Spin (loading) */
@keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
}

/* Pulse (notification) */
@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
}
```

---

## Iconography

### Icon System
- **Library**: Heroicons (outline for default, solid for active states)
- **Size Scale**: 16px, 20px, 24px, 32px, 48px
- **Style**: 2px stroke width for outline icons
- **Color**: Inherit from parent text color

### Icon Usage
```css
.icon-sm { width: 16px; height: 16px; }
.icon-md { width: 20px; height: 20px; }
.icon-lg { width: 24px; height: 24px; }
.icon-xl { width: 32px; height: 32px; }
.icon-2xl { width: 48px; height: 48px; }
```

---

## Responsive Breakpoints

```css
/* Mobile first */
--screen-sm: 640px;   /* Small devices */
--screen-md: 768px;   /* Tablets */
--screen-lg: 1024px;  /* Laptops */
--screen-xl: 1280px;  /* Desktops */
--screen-2xl: 1536px; /* Large desktops */

/* Usage */
@media (min-width: 768px) {
    /* Tablet and up */
}
```

---

## Layout Grid

```css
.container {
    max-width: 1280px;
    margin: 0 auto;
    padding: 0 var(--space-4);
}

.grid {
    display: grid;
    gap: var(--space-6);
    grid-template-columns: repeat(12, 1fr);
}

/* Responsive columns */
.col-12 { grid-column: span 12; }
.col-6 { grid-column: span 6; }
.col-4 { grid-column: span 4; }
.col-3 { grid-column: span 3; }

@media (max-width: 768px) {
    .col-12, .col-6, .col-4, .col-3 {
        grid-column: span 12;
    }
}
```

---

## Accessibility

### Focus States
```css
:focus-visible {
    outline: 2px solid var(--primary-500);
    outline-offset: 2px;
}

.focus-ring {
    transition: box-shadow 0.2s ease;
}

.focus-ring:focus-visible {
    outline: none;
    box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.5);
}
```

### Screen Reader Only
```css
.sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border-width: 0;
}
```

### Color Contrast
All color combinations meet WCAG 2.1 AA standards:
- Normal text: 4.5:1 minimum
- Large text (18px+): 3:1 minimum
- Interactive elements: 3:1 minimum

---

## Loading States

### Skeleton Loaders
```css
.skeleton {
    background: linear-gradient(
        90deg,
        var(--gray-200) 25%,
        var(--gray-300) 50%,
        var(--gray-200) 75%
    );
    background-size: 200% 100%;
    animation: shimmer 1.5s infinite;
    border-radius: var(--radius-md);
}

@keyframes shimmer {
    0% { background-position: 200% 0; }
    100% { background-position: -200% 0; }
}
```

### Spinners
```css
.spinner {
    border: 3px solid var(--gray-200);
    border-top-color: var(--primary-600);
    border-radius: 50%;
    width: 24px;
    height: 24px;
    animation: spin 0.8s linear infinite;
}
```

---

## Empty States

```css
.empty-state {
    text-align: center;
    padding: var(--space-16) var(--space-8);
}

.empty-state__icon {
    width: 64px;
    height: 64px;
    margin: 0 auto var(--space-4);
    color: var(--gray-400);
}

.empty-state__title {
    font-size: var(--text-h3);
    font-weight: var(--weight-semibold);
    color: var(--gray-900);
    margin-bottom: var(--space-2);
}

.empty-state__description {
    color: var(--gray-600);
    margin-bottom: var(--space-6);
}
```

---

## Data Visualization

### Chart Colors
```css
--chart-1: #667eea;  /* Primary */
--chart-2: #10b981;  /* Success */
--chart-3: #f59e0b;  /* Warning */
--chart-4: #3b82f6;  /* Info */
--chart-5: #8b5cf6;  /* Purple */
--chart-6: #ec4899;  /* Pink */
```

### Progress Bars
```css
.progress {
    height: 8px;
    background: var(--gray-200);
    border-radius: var(--radius-full);
    overflow: hidden;
}

.progress-bar {
    height: 100%;
    background: var(--gradient-primary);
    transition: width 0.3s ease;
}
```

---

## Dark Mode (Future)

```css
@media (prefers-color-scheme: dark) {
    :root {
        --gray-50: #1f2937;
        --gray-100: #111827;
        /* ... inverted grays */
    }
}
```

---

This design system ensures:
✅ Consistent visual language
✅ Accessible components
✅ Smooth animations
✅ Scalable architecture
✅ Production-ready specs
