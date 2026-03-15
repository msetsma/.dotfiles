# Python Rules

## Architecture & Patterns

- Prefer composition over inheritance; use protocols/ABCs for interfaces
- Keep functions small and single-purpose
- Use dependency injection over hard-coded dependencies
- Prefer modules with functions over classes for stateless logic
- No god objects — split responsibilities across focused classes
- Use `__all__` in public-facing modules

## Error Handling & Logging

- No bare `except` — always catch specific exceptions
- Prefer custom exception hierarchies for domain errors (inherit from a project base exception)
- Use `raise ... from` to preserve exception chains
- Use `structlog` or stdlib `logging` — never `print()` for observability
- Log at appropriate levels: DEBUG for dev, INFO for business events, WARNING for recoverable issues, ERROR for failures
- Let exceptions propagate — don't catch-and-log-and-swallow

## Type Hints & Data Modeling

- Type-annotate all function signatures (params + return)
- Use `Pydantic BaseModel` for external data boundaries (API, config, file I/O)
- Use `dataclasses` for internal domain objects
- Use `TypedDict` only for typed dict literals (e.g., kwargs)
- Prefer `collections.abc` types (`Sequence`, `Mapping`) over concrete types in signatures
- Use `X | None` syntax (PEP 604), not `Optional[X]`
