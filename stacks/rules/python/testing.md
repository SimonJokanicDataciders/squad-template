---
paths:
  - "**/*.py"
  - "**/tests/**"
description: Python testing conventions with pytest, fixtures, and TestClient
---

# Python Testing Conventions

Extends [common/testing.md](../common/testing.md) with Python-specific patterns.

## Stack

- **Framework:** pytest
- **HTTP testing:** httpx.AsyncClient or FastAPI TestClient
- **Data generation:** factory_boy or custom fixtures
- **Mocking:** unittest.mock or pytest-mock

## Test Structure

```
tests/
├── conftest.py              # Shared fixtures (db, client, factories)
├── unit/
│   ├── test_item_service.py
│   └── factories.py         # Test data factories
└── integration/
    └── test_items_api.py
```

## Unit Test Pattern

```python
import pytest
from uuid import uuid4

class TestItemService:
    @pytest.fixture
    def service(self, db_session):
        return ItemService(db_session)

    async def test_get_by_id_with_valid_id_returns_item(self, service, sample_item):
        result = await service.get_by_id(sample_item.id)

        assert result is not None
        assert result.id == sample_item.id
        assert result.title == sample_item.title

    async def test_get_by_id_with_invalid_id_returns_none(self, service):
        result = await service.get_by_id(uuid4())

        assert result is None

    async def test_create_with_valid_data_returns_created(self, service):
        data = CreateItemRequest(title="Test Item", priority=Priority.HIGH)

        result = await service.create(data)

        assert result.title == "Test Item"
        assert result.priority == Priority.HIGH
        assert result.id is not None
```

## Integration Test Pattern

```python
import pytest
from httpx import AsyncClient

class TestItemsAPI:
    async def test_create_and_retrieve(self, client: AsyncClient):
        # Create
        response = await client.post("/api/items", json={
            "title": "Integration Test Item",
            "priority": "high",
        })
        assert response.status_code == 201
        created = response.json()

        # Retrieve
        response = await client.get(f"/api/items/{created['id']}")
        assert response.status_code == 200
        assert response.json()["title"] == "Integration Test Item"

    async def test_get_nonexistent_returns_404(self, client: AsyncClient):
        response = await client.get(f"/api/items/{uuid4()}")
        assert response.status_code == 404
```

## Fixtures (conftest.py)

```python
import pytest
from httpx import ASGITransport, AsyncClient

@pytest.fixture
async def client(app):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c

@pytest.fixture
async def sample_item(db_session):
    item = Item(title="Test", description="A test item")
    db_session.add(item)
    await db_session.commit()
    await db_session.refresh(item)
    return item
```

## Rules

- Naming: `test_method_condition_expected` (snake_case)
- Use `pytest.fixture` for setup, not setUp/tearDown
- Use `@pytest.mark.parametrize` for data-driven tests
- Prefer real database over mocking for integration tests
- Use `async def test_...` with `pytest-asyncio` for async code
- Test error paths: 404, 400, 422, 401, 403
