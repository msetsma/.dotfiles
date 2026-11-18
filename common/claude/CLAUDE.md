# Python Rules

Every Python edit and commit passes a gate (`~/.dotfiles-agents/bin/clean-python`:
ruff plus extra checks). It already enforces typed signatures, no `print()`, no
bare or blind `except`, `raise ... from`, `X | None`, function size and argument
counts, frozen dataclasses, files of 800 lines or fewer, no code only tests use,
and type correctness (ty). `# noqa` does not silence it: fix the code. Write code
that passes it the first time; the rules below are the ones no tool can check.

## Architecture & Patterns

- Prefer composition over inheritance; use protocols/ABCs for interfaces
- Keep functions small and single-purpose
- Use dependency injection over hard-coded dependencies
- Prefer modules with functions over classes for stateless logic
- No god objects — split responsibilities across focused classes
- Use `__all__` in public-facing modules

## Error Handling & Logging

- Prefer custom exception hierarchies for domain errors (inherit from a project base exception)
- Use `structlog` or stdlib `logging` for observability
- Log at appropriate levels: DEBUG for dev, INFO for business events, WARNING for recoverable issues, ERROR for failures
- Let exceptions propagate — don't catch-and-log-and-swallow

## Data Modeling

- Use `Pydantic BaseModel` for external data boundaries (API, config, file I/O)
- Use frozen `dataclasses` for internal domain objects
- Use `TypedDict` only for typed dict literals (e.g., kwargs)
- Prefer `collections.abc` types (`Sequence`, `Mapping`) over concrete types in signatures

Use the `python-review` skill before a refactor, when deleting or splitting code,
and when reviewing a Python diff.
