---
trigger: always_on
---

---
description: Provide coding guidelines that AI should follow when generating Dart and Flutter code, answering questions, or reviewing changes.
paths:
  - "lib/**/*.dart"
  - "test/**/*.dart"
---

# Dart & Flutter Coding Rules

## Core Behavior

- Always focus only on the current request, current file, and surrounding relevant context.
- Do not go beyond the scope of the task.
- Do not introduce unrelated refactors, speculative improvements, or extra features unless explicitly requested.
- Do not invent requirements, APIs, classes, methods, packages, or project conventions that are not supported by the codebase or the user’s instructions.
- Prefer correctness, clarity, maintainability, and relevance over complexity or cleverness.
- Keep changes minimal and targeted to the actual problem.
- When context is incomplete, make the smallest safe assumption and state it briefly if needed.
- Do not present guesses as facts.

## Context Awareness

- Base all outputs on:
  - the user’s explicit request
  - the existing Dart/Flutter code
  - surrounding files and usage patterns
  - current architecture and folder structure
  - existing naming conventions
- Reuse existing widgets, models, services, extensions, helpers, themes, and utilities before creating new ones.
- Follow established project structure and code style.
- Avoid introducing new abstractions unless required for correctness or clearly beneficial.
- Do not change app behavior, public APIs, navigation flow, state flow, or UI semantics unless the task explicitly requires it.

## Scope Control

- Only modify the code necessary to solve the requested problem.
- Do not rename files, classes, variables, methods, routes, providers, or keys unless required.
- Do not move logic across layers unless explicitly requested.
- Do not change unrelated formatting or rewrite working code unnecessarily.
- Do not add placeholders, mock implementations, or TODO comments unless requested.

## Code Generation

- Generate valid, idiomatic, production-quality Dart and Flutter code.
- Ensure code is complete enough to be used directly with minimal adjustment.
- Do not output pseudocode unless explicitly requested.
- Match the existing codebase style and structure.
- Prefer simple, readable solutions over over-engineered patterns.
- Keep code cohesive and local when possible.
- Do not add new packages or dependencies unless necessary for the requested task.

## Correctness

- Ensure all generated code is syntactically valid Dart.
- Ensure logic is consistent with the requirement and surrounding implementation.
- Respect null safety.
- Preserve existing contracts, interfaces, model shapes, and method signatures unless change is explicitly required.
- Handle directly relevant edge cases.
- Avoid hidden side effects.
- Include error handling when it matters for correctness or runtime safety.
- If the requirement is ambiguous and affects correctness, briefly mention the ambiguity and choose the safest implementation aligned with the current codebase.

## Dart Guidelines

- Prefer strong typing.
- Avoid `dynamic` unless absolutely necessary.
- Use `final` by default for local variables and fields that do not change.
- Use `const` wherever possible for widgets and immutable values.
- Keep functions focused and small.
- Prefer explicit return types for public methods and important functions.
- Avoid unnecessarily complex generics or abstractions.
- Use extension methods only when they clearly improve readability and match project conventions.
- Prefer enums, sealed patterns, or typed constants over raw strings when the project already follows that pattern.
- Keep model classes, parsing logic, and utility logic organized and predictable.

## Null Safety

- Respect Dart null safety at all times.
- Do not force-null with `!` unless there is a clear and justified guarantee.
- Prefer safe access, guards, and explicit checks over risky assumptions.
- Avoid nullable types when a value should always exist.
- When handling nullable input, choose behavior that is safe and explicit.

## Flutter Guidelines

- Follow Flutter best practices and existing project conventions.
- Prefer `StatelessWidget` when state is not needed.
- Use `StatefulWidget` only when local mutable UI state is necessary.
- Keep widget trees readable and split large widgets when it improves clarity.
- Reuse existing widgets instead of duplicating UI patterns.
- Keep business logic out of UI widgets unless the codebase clearly uses a simple local pattern.
- Respect theming, spacing, typography, and color patterns already present in the project.
- Do not hardcode design values if the project already uses shared constants, theme extensions, or design tokens.
- Keep build methods clean and avoid mixing too much logic into UI layout code.
- Avoid unnecessary rebuild triggers.

## State Management

- Follow the state management approach already used in the project.
- Do not introduce a new state management solution unless explicitly requested.
- Respect existing patterns for:
  - Provider
  - Riverpod
  - Bloc/Cubit
  - GetX
  - ValueNotifier
  - setState
  - other established internal patterns
- Keep state responsibilities in the correct layer.
- Do not move business logic into widgets if the project separates controller/viewmodel/bloc/provider logic.
- Keep side effects explicit and predictable.

## UI and Widget Composition

- Make UI changes only when requested or required for correctness.
- Preserve current layout intent unless the task explicitly asks for redesign.
- Use smaller private widgets or helper builders only when they improve clarity.
- Avoid deeply nested widget trees when a small extraction helps readability.
- Keep widget naming descriptive and consistent with the project.
- Use `const` constructors where possible.
- Respect accessibility-related semantics if already present.
- Do not remove keys, semantics, or test hooks without reason.

## Navigation and Routing

- Follow the existing navigation system used in the project.
- Do not change route names, parameters, or navigation flow unless requested.
- Preserve expected back navigation behavior.
- Pass arguments in the same style already used by the codebase.
- Be careful not to break deep links, nested navigation, or route guards if they exist.

## Async and Concurrency

- Use `async` and `await` correctly.
- Handle async errors when relevant.
- Do not ignore futures unless intentionally fire-and-forget and safe in the current pattern.
- Avoid race conditions and repeated async calls from widget rebuilds.
- Do not trigger side effects directly in `build()` unless the codebase explicitly follows such a pattern and it is safe.
- Prefer lifecycle-safe patterns for loading data and subscriptions.

## Data Models and Serialization

- Follow existing model patterns in the project.
- Do not change field names or JSON keys unless explicitly required.
- Preserve compatibility with current API contracts.
- Be careful with nullable and default values during parsing and mapping.
- If the project uses generated serialization or immutable model tooling, follow that pattern instead of manual alternatives.

## Services, Repositories, and Business Logic

- Keep service and repository responsibilities clear.
- Do not place API, database, or persistence logic inside UI widgets unless the codebase already uses a very local/simple approach.
- Reuse existing clients, repositories, and abstractions.
- Keep business rules centralized where the project expects them.
- Avoid duplicating existing logic across layers.

## Error Handling

- Handle errors at the appropriate layer.
- Do not swallow exceptions silently unless the codebase explicitly expects it and it is safe.
- Provide user-facing fallback behavior only when appropriate to the task.
- Keep logs, exceptions, and error messages consistent with the project style.
- Prefer predictable failure behavior over hidden failure.

## Performance and Efficiency

- Avoid unnecessary widget rebuilds.
- Avoid unnecessary allocations inside build methods when easy to prevent.
- Use `const` where possible.
- Avoid expensive work in `build()`.
- Do not prematurely optimize, but do avoid obvious inefficiencies.
- Respect existing memoization, caching, or pagination patterns where present.

## Testing

- When writing or updating tests:
  - follow the existing test style
  - keep tests focused on behavior
  - avoid brittle implementation-detail assertions unless the project already relies on them
  - use meaningful test names
- Do not change unrelated tests.
- If production code changes should impact tests, update only the relevant tests.
- Prefer deterministic tests.

## Reviews and Code Feedback

- When reviewing code, prioritize:
  - correctness
  - regressions
  - null safety
  - state handling
  - UI behavior impact
  - architectural consistency
  - readability
- Point out concrete issues, not vague preferences.
- Distinguish clearly between:
  - bugs
  - risks
  - maintainability concerns
  - optional improvements
- Do not recommend broad refactors unless they are necessary to solve a real issue.

## Explaining Code

- Keep explanations concise, practical, and tied to the current code.
- Explain why a change is needed when relevant.
- Do not over-explain obvious Flutter or Dart concepts unless asked.
- When fixing a bug, briefly state:
  - what was wrong
  - why it failed
  - what changed

## Safe Defaults

- Prefer minimal changes over broad rewrites.
- Prefer existing project patterns over generic best practices when both are reasonable.
- Prefer explicitness over hidden magic.
- Prefer stable and maintainable solutions over clever shortcuts.
- Prefer code that integrates cleanly with the current codebase.

## Things to Avoid

- Do not hallucinate package APIs.
- Do not assume a library is installed unless shown in the codebase or requested.
- Do not add imports that are unused.
- Do not leave broken references, incomplete branches, or placeholder code.
- Do not use deprecated Flutter/Dart APIs when a standard current pattern is already present in the codebase.
- Do not rewrite unrelated files for style reasons.
- Do not mix architectural patterns carelessly.
- Do not break null safety, typing, widget lifecycle, or state flow.

## Output Expectations

Before finalizing any answer or code, ensure:

- the response stays within the current context
- the solution directly addresses the user’s request
- the Dart code is valid and null-safe
- the Flutter code follows the existing app structure
- no unrelated changes were introduced
- no assumptions were presented as facts
- the result is as simple as possible while remaining correct