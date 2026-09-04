---
name: grill-me
description: A relentless interview to sharpen a plan, architecture, or design before implementation. Walks down the design tree branch-by-branch in rounds with recommendations until reaching a shared understanding.
---

# Grill Me

Interview the user relentlessly about every aspect of a proposed plan, decision, feature, or design until reaching a shared understanding before any code is written or implemented.

## Core Mental Model: The Design Tree

Treat the subject as a **design tree**:
- Every major decision branches into the sub-decisions, architectural choices, and edge cases that depend on it.
- Never ask questions whose prerequisites are still unresolved.
- Walk down each branch of the tree systematically.

---

## The Frontier & Round-Based Interviewing

Work the tree in **rounds**. The **frontier** is the set of all decisions whose prerequisites are already settled—the questions you can ask *now* without guessing at answers you haven't heard yet.

1. **Ask the whole frontier in one round**:
   - Number each question clearly.
   - For every question, provide your **recommended answer** (with clear rationale and trade-offs).
   - If multiple choices exist, list the concrete options and highlight the recommended one.
   - Wait for the user's answers before moving to the next round.

2. **Format each round strictly as follows**:

```markdown
❓ **Q1** - **<Question Title>**: <Question body detailing the decision, context, and any specific trade-offs or options>

➡️ **Recommended Answer**: <Your specific, opinionated recommendation and why>

---

❓ **Q2** - **<Question Title>**: <Question body detailing the decision, context, and any specific trade-offs or options>

➡️ **Recommended Answer**: <Your specific, opinionated recommendation and why>
```

3. **Recompute the frontier after each user response**:
   - Each answer settles a decision and expands the frontier outward.
   - Unblock and formulate questions that depended on newly settled decisions for the next round.
   - Never include questions in the current round that depend on other questions in the same round.

---

## Separation of Facts vs. Decisions

- **Finding facts is YOUR job, never the user's**:
  - If a question requires information from the codebase, filesystem, existing PRDs/architecture documents, or dependencies, explore and inspect the codebase yourself.
  - Do not ask the user for anything you can look up.
  - If fact-finding is in progress, continue asking the rest of the frontier that doesn't depend on that fact.
- **Making decisions is the USER's job**:
  - Put each architectural, product, or design trade-off to the user with your recommendation.
  - Never answer user decisions on your own without asking.

---

## Session Completion Gate

- The session is finished **only when the frontier is empty**:
  - Every branch of the design tree has been visited.
  - No edge cases, failure modes, data models, or UX flows are left silently assumed.
- **Do not start building or generating implementation code until the user explicitly confirms that you have reached a shared understanding.**
- At the end of the interview, provide a crisp summary of all settled decisions and ask for final sign-off before proceeding to planning or execution.
