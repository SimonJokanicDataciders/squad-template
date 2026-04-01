---
paths:
  - "**/*.py"
description: Python coding conventions for AI agent development
---

# Python Coding Style

Extends [common/coding-style.md](../common/coding-style.md) with Python-specific rules.

## Type Hints

Type hints on ALL functions — no exceptions:

```python
# WRONG
def get_user(user_id):
    return db.query(User).get(user_id)

# CORRECT
async def get_user(user_id: UUID) -> UserOut | None:
    return await db.query(User).get(user_id)
```

## Data Models

Use Pydantic for external data, dataclasses for internal:

```python
# API request/response — Pydantic
class CreateItemRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: str | None = None
    priority: Priority = Priority.MEDIUM

# Internal data — dataclass
@dataclass(frozen=True)
class ProcessingResult:
    item_id: UUID
    status: str
    processed_at: datetime
```

## Async/Await

Use `async def` by default for all I/O operations:

```python
# WRONG — blocks the event loop
def get_items(db: Session) -> list[Item]:
    return db.query(Item).all()

# CORRECT
async def get_items(db: AsyncSession) -> list[Item]:
    result = await db.execute(select(Item))
    return list(result.scalars().all())
```

## Error Handling

```python
# WRONG — bare except
try:
    item = await service.get(item_id)
except:
    return None

# CORRECT — specific exceptions
try:
    item = await service.get(item_id)
except ItemNotFoundError:
    raise HTTPException(status_code=404, detail=f"Item {item_id} not found")
except ValidationError as e:
    raise HTTPException(status_code=400, detail=str(e))
```

## Rules

- f-strings for formatting (never `.format()` or `%`)
- Context managers for all resources (`async with`, `with`)
- `from __future__ import annotations` for forward references
- Prefer `list[T]`, `dict[K, V]`, `T | None` over `List`, `Dict`, `Optional`
- No mutable default arguments (`def f(items: list = None)` → `def f(items: list | None = None)`)
