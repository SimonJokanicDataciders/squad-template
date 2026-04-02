---
name: "fastapi"
matches: ["fastapi", "fast-api", "fast api"]
version: "0.115.x"
updated: "2026-03-30"
status: "beta"
---

# FastAPI — Seed

## Critical Rules (LLM MUST follow these)
1. Define Pydantic models for every request body and response — never accept or return raw dicts.
2. Use `response_model` on every endpoint to enforce the response contract at the framework level.
3. Use `Depends()` for shared logic (DB sessions, auth, config) — never instantiate services manually.
4. Declare endpoints as `async def` by default; use sync `def` only for truly blocking I/O with no async driver.
5. Raise `HTTPException` for expected errors — do not catch exceptions broadly and return generic 500s.
6. Use an `APIRouter` per domain and include it in the main app — never pile all endpoints into `main.py`.

## Golden Example
```python
# app/routers/items.py
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from app.services.item_service import ItemService
from app.dependencies import get_item_service

router = APIRouter(prefix="/items", tags=["items"])


class ItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=120)
    price: float = Field(..., gt=0)


class ItemOut(BaseModel):
    id: int
    name: str
    price: float

    model_config = {"from_attributes": True}


@router.get("/", response_model=list[ItemOut])
async def list_items(service: ItemService = Depends(get_item_service)):
    return await service.list_all()


@router.get("/{item_id}", response_model=ItemOut)
async def get_item(item_id: int, service: ItemService = Depends(get_item_service)):
    item = await service.get_by_id(item_id)
    if item is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")
    return item


@router.post("/", response_model=ItemOut, status_code=status.HTTP_201_CREATED)
async def create_item(body: ItemCreate, service: ItemService = Depends(get_item_service)):
    return await service.create(body)


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_item(item_id: int, service: ItemService = Depends(get_item_service)):
    deleted = await service.delete(item_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")
```

## Common LLM Mistakes
- Omitting `response_model` — the endpoint silently returns whatever shape you give it, losing type safety.
- Using a bare `except Exception` around the whole handler — hides bugs and prevents FastAPI's built-in error handling.
- Not using `Depends()` for DB sessions or services — creates tight coupling and makes testing nearly impossible.
- Returning raw dicts like `{"id": 1, "name": "foo"}` instead of Pydantic models — bypasses validation entirely.
- Defining all routes in `main.py` instead of using `APIRouter` — turns the app into an unnavigable monolith.
