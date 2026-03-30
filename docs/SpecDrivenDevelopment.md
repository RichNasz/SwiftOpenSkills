# Spec-Driven Development with SwiftOpenSkills

## What Is Spec-Driven Development?

Spec-driven development (SDD) is a workflow where you write specifications before code. You describe what your application should do (WHAT spec) and how to implement it with SwiftOpenSkills (HOW spec), then hand the specs to an AI coding agent to generate the implementation.

SDD is entirely optional. You can use SwiftOpenSkills without writing any specs. But if you use an AI coding agent, specs reduce back-and-forth and produce more accurate results on the first pass.

## The Three Tools

### WHAT Specs — Define the Product

A WHAT spec describes what the application does from the user's perspective. It lists the capabilities needed, interaction requirements, and acceptance criteria.

A WHAT spec does not prescribe implementation. It answers: *what should exist when this is done?*

Write a WHAT spec when you are building a new feature or changing requirements for an existing one.

### HOW Specs — Guide the Implementation

A HOW spec translates WHAT requirements into technical decisions. It specifies which types and patterns to use, how to wire components, and error handling strategy.

A HOW spec gives the AI agent enough detail to generate code without ambiguity. It answers: *how should this be built using SwiftOpenSkills?*

Write a HOW spec after the WHAT spec is settled, before asking an agent to generate code.

### Agent Skills — Provide Package Knowledge

Agent Skills give the AI coding agent domain-specific knowledge about a package. Skills will be added to `skills/` as features are defined.

## How They Work Together

Each tool covers a different layer. Together they form a complete pipeline from requirements to working code:

1. **You write a WHAT spec** — describe the feature, its inputs/outputs, and acceptance criteria
2. **You write a HOW spec** — translate the WHAT into SwiftOpenSkills-specific implementation guidance
3. **The agent reads the HOW spec and has the Skills loaded** — it knows both *your* requirements and *the package's* API
4. **You review and run `swift build && swift test`** — verify the output matches the WHAT spec's acceptance criteria

## Getting Started

1. **Write a WHAT spec** — describe the feature and its acceptance criteria in `Spec/`
2. **Write a HOW spec** — translate the WHAT into type-level implementation guidance
3. **Ask your agent to implement** — point the agent at the HOW spec
4. **Verify** — run `swift build && swift test`
