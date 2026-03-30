---
name: "pytest"
matches: ["pytest", "py.test"]
version: "8.3"
updated: "2026-03-30"
status: "beta"
---

# pytest — Seed

## Critical Rules (LLM MUST follow these)
1. Write test functions, not test classes. Use plain `def test_*` functions — avoid `unittest.TestCase` subclasses.
2. Use fixtures (`@pytest.fixture`) for setup and teardown; yield fixtures for cleanup. Never use `setUp`/`tearDown`.
3. Use `@pytest.mark.parametrize` to cover multiple input/output variants instead of duplicating test functions.
4. Place shared fixtures in `conftest.py` at the appropriate directory level — pytest discovers them automatically.
5. Use plain `assert` statements, not `self.assertEqual` or similar — pytest rewrites assertions to give rich diffs.
6. For FastAPI/Starlette, use `httpx.AsyncClient` or `TestClient` from `starlette.testclient` for API tests.
7. Mark slow or integration tests with `@pytest.mark.slow` and exclude them in fast CI runs via `-m "not slow"`.
8. Never catch broad exceptions in tests — let them propagate so pytest reports the real failure.

## Golden Example
```python
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.models import User
from app.db import get_session

@pytest.fixture
def sample_user():
    return User(id=1, name="Alice", email="alice@example.com")

@pytest.fixture
async def async_client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client

class FakeSession:
    def __init__(self, users):
        self._users = {u.id: u for u in users}

    def get(self, model, id_):
        return self._users.get(id_)

@pytest.mark.parametrize("name,email,valid", [
    ("Alice", "alice@example.com", True),
    ("", "alice@example.com", False),
    ("Bob", "", False),
])
def test_user_validation(name, email, valid):
    if valid:
        user = User(id=1, name=name, email=email)
        assert user.name == name
    else:
        with pytest.raises(ValueError):
            User(id=1, name=name, email=email)

@pytest.mark.asyncio
async def test_get_user_returns_200(async_client, sample_user):
    app.dependency_overrides[get_session] = lambda: FakeSession([sample_user])

    response = await async_client.get("/users/1")

    assert response.status_code == 200
    assert response.json()["name"] == "Alice"

    app.dependency_overrides.clear()

def test_user_not_found_returns_404(sample_user):
    from starlette.testclient import TestClient
    app.dependency_overrides[get_session] = lambda: FakeSession([])
    client = TestClient(app)

    response = client.get("/users/999")

    assert response.status_code == 404
    app.dependency_overrides.clear()
```

## Common LLM Mistakes
- **Using `unittest.TestCase` style.** Subclassing TestCase disables pytest's assertion rewriting and fixture injection. Use plain functions.
- **Not using fixtures.** Repeating setup code inside every test instead of extracting a `@pytest.fixture` leads to duplication and fragile tests.
- **Broad `except Exception` in tests.** Catching exceptions to assert on them manually hides real failures. Use `pytest.raises` as a context manager.
- **Copy-pasting tests instead of `parametrize`.** Multiple test functions that differ only in input/output should be a single `@pytest.mark.parametrize` test.
- **Forgetting `@pytest.mark.asyncio` on async tests.** Without the marker, the test coroutine is never awaited and silently passes.
