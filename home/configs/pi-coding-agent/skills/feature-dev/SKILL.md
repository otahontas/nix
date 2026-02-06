---
name: feature-dev
description: |
  Guided feature development with structured phases: discovery, codebase exploration,
  clarifying questions, architecture design, implementation, quality review, and summary.
  Use when implementing a new feature, especially one that requires understanding existing
  code patterns, making architectural decisions, or coordinating changes across multiple files.
---

# Feature development

Systematic approach to implementing features: understand the codebase deeply, ask about all underspecified details, design the architecture, then implement.

## Core principles

- **Ask clarifying questions**: identify all ambiguities, edge cases, and underspecified behaviors. Ask specific, concrete questions rather than making assumptions. Wait for answers before proceeding.
- **Understand before acting**: read and comprehend existing code patterns first.
- **Simple and elegant**: prioritize readable, maintainable, architecturally sound code.
- **Track progress**: use a checklist or markdown file for multi-step work.

---

## Phase 1: Discovery

**Goal**: understand what needs to be built.

1. Create a checklist with all phases
2. If the feature is unclear, ask the user:
   - What problem are they solving?
   - What should the feature do?
   - Any constraints or requirements?
3. Summarize understanding and confirm with user

---

## Phase 2: Codebase exploration

**Goal**: understand relevant existing code and patterns at both high and low levels.

1. Explore the codebase from multiple angles:
   - Find features similar to the one being built — trace their implementation
   - Map the architecture and abstractions for the relevant area
   - Identify UI patterns, testing approaches, or extension points
2. For each angle, identify 5-10 key files to read
3. Read all key files to build deep understanding
4. Present comprehensive summary of findings and patterns discovered

**What to capture**:

- Entry points with file:line references
- Execution flow with data transformations
- Key components and their responsibilities
- Architecture insights: patterns, layers, design decisions
- Dependencies (external and internal)

---

## Phase 3: Clarifying questions

**Goal**: fill in gaps and resolve all ambiguities before designing.

**This is one of the most important phases. Do not skip.**

1. Review codebase findings and original feature request
2. Identify underspecified aspects:
   - Edge cases and error handling
   - Integration points
   - Scope boundaries
   - Design preferences
   - Backward compatibility
   - Performance needs
3. **Present all questions to the user in a clear, organized list**
4. **Wait for answers before proceeding**

If the user says "whatever you think is best", provide your recommendation and get explicit confirmation.

---

## Phase 4: Architecture design

**Goal**: design the implementation approach with clear trade-offs.

Explore 2-3 different approaches with different focuses:

- **Minimal changes**: smallest change, maximum reuse of existing code
- **Clean architecture**: maintainability, elegant abstractions
- **Pragmatic balance**: speed + quality

For each approach, document:

- Patterns and conventions found (with file:line references)
- Architecture decision with rationale
- Component design: file path, responsibilities, dependencies, interfaces
- Implementation map: specific files to create/modify
- Data flow from entry points through transformations to outputs
- Build sequence as a phased checklist

Present to user:

- Brief summary of each approach
- Trade-offs comparison
- **Your recommendation with reasoning**
- **Ask which approach they prefer**

---

## Phase 5: Implementation

**Goal**: build the feature.

**Do not start without user approval of the architecture.**

1. Read all relevant files identified in previous phases
2. Implement following chosen architecture
3. Follow codebase conventions strictly (check AGENTS.md)
4. Write clean, well-documented code
5. Update progress tracking as you go

---

## Phase 6: Quality review

**Goal**: ensure code is simple, correct, and follows conventions.

Review the implementation from three angles:

### Simplicity and elegance

- Is the code DRY? Any unnecessary duplication?
- Are abstractions appropriate — not too many, not too few?
- Is it easy to read and understand?

### Bugs and correctness

- Logic errors, null/undefined handling, race conditions?
- Edge cases covered?
- Error handling appropriate?

### Project conventions

- AGENTS.md compliance?
- Follows established patterns in the codebase?
- Naming, imports, structure match existing code?

Present findings and **ask the user what they want to do** (fix now, fix later, or proceed as-is).

---

## Phase 7: Summary

**Goal**: document what was accomplished.

1. Mark all checklist items complete
2. Summarize:
   - What was built
   - Key decisions made
   - Files modified/created
   - Suggested next steps
