---
paths:
  - "**/*.py"
description: Python design patterns for FastAPI, SQLAlchemy, and service architecture
---

# Python Design Patterns

Extends [common/patterns.md](../common/patterns.md) with Python-specific implementations.

## FastAPI Router Pattern

```python
from fastapi import APIRouter, Depends, HTTPException, status
from uuid import UUID

router = APIRouter(prefix="/api/items", tags=["items"])

@router.get("/", response_model=list[ItemOut])
async def list_items(
    service: ItemService = Depends(get_item_service),
    skip: int = 0,
    limit: int = 100,
) -> list[ItemOut]:
    return await service.get_all(skip=skip, limit=limit)

@router.get("/{item_id}", response_model=ItemOut)
async def get_item(
    item_id: UUID,
    service: ItemService = Depends(get_item_service),
) -> ItemOut:
    item = await service.get_by_id(item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return item

@router.post("/", response_model=ItemOut, status_code=status.HTTP_201_CREATED)
async def create_item(
    body: CreateItemRequest,
    service: ItemService = Depends(get_item_service),
) -> ItemOut:
    return await service.create(body)
```

## Service Pattern

```python
class ItemService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def get_all(self, skip: int = 0, limit: int = 100) -> list[ItemOut]:
        result = await self._db.execute(
            select(Item).offset(skip).limit(limit)
        )
        return [ItemOut.model_validate(r) for r in result.scalars().all()]

    async def get_by_id(self, item_id: UUID) -> ItemOut | None:
        result = await self._db.get(Item, item_id)
        return ItemOut.model_validate(result) if result else None

    async def create(self, data: CreateItemRequest) -> ItemOut:
        item = Item(**data.model_dump())
        self._db.add(item)
        await self._db.commit()
        await self._db.refresh(item)
        return ItemOut.model_validate(item)
```

## Dependency Injection

```python
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_maker() as session:
        yield session

async def get_item_service(
    db: AsyncSession = Depends(get_db),
) -> ItemService:
    return ItemService(db)
```

## SQLAlchemy 2.0 Model

```python
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import String, DateTime, func
from uuid import UUID, uuid4

class Item(Base):
    __tablename__ = "items"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
```

## Rules

- `response_model=` on EVERY endpoint decorator
- `Depends()` for all shared dependencies (DB, services, auth)
- Pydantic models for all request/response contracts
- Never return SQLAlchemy models directly — map to Pydantic DTOs
- Use `async with` for database sessions
