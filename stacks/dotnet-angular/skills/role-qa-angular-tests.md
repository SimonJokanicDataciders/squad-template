---
name: "cap-template-role-qa-angular-tests"
description: "Angular component test patterns for Hockney — load on demand"
domain: "testing"
confidence: "high"
source: "manual"
---

Load this module when writing or reviewing Angular component tests.

---

## Angular Component Test Patterns

### Overview

Angular tests in this project use **Jest** with **jest-preset-angular**. The setup file is `src/Paso.Cap.Angular/setup-jest.ts`. Tests live alongside source files as `*.spec.ts` or in a sibling `__tests__/` directory.

### TestBed Configuration for Standalone Components

```typescript
// File: src/Paso.Cap.Angular/src/app/weather-forecasts/weather-forecast.component.spec.ts
import { TestBed, ComponentFixture } from '@angular/core/testing';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { WeatherForecastComponent } from './weather-forecast.component';

describe('WeatherForecastComponent', () => {
  let fixture: ComponentFixture<WeatherForecastComponent>;
  let component: WeatherForecastComponent;
  let httpMock: HttpTestingController;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [WeatherForecastComponent],          // standalone component — import directly
      providers: [provideHttpClientTesting()]       // swap real HTTP for test controller
    }).compileComponents();

    fixture   = TestBed.createComponent(WeatherForecastComponent);
    component = fixture.componentInstance;
    httpMock  = TestBed.inject(HttpTestingController);
  });

  afterEach(() => httpMock.verify()); // assert no unexpected requests
});
```

### Testing with Signals

Signals are synchronous — access them directly via `component.mySignal()` after triggering change detection.

```typescript
it('WeatherForecastComponent_WhenDataLoaded_RendersTable', async () => {
  // Arrange: flush pending HTTP requests with mock data
  fixture.detectChanges();
  const req = httpMock.expectOne('/api/weatherforecast');
  req.flush([{ id: '1', temperatureC: 20, summary: 'Sunny', date: '2024-01-01' }]);
  fixture.detectChanges();

  // Assert via signal
  expect(component.forecasts()).toHaveLength(1);
  expect(component.forecasts()[0].summary).toBe('Sunny');

  // Assert DOM
  const rows = fixture.nativeElement.querySelectorAll('tr[data-testid="forecast-row"]');
  expect(rows.length).toBe(1);
});
```

### Testing rxResource Loading States

`rxResource` (Angular 19+) exposes `.isLoading()`, `.value()`, and `.error()` signals. Test each state:

```typescript
it('WeatherForecastComponent_WhenLoading_ShowsSpinner', () => {
  fixture.detectChanges(); // triggers the resource fetch

  expect(component.forecastResource.isLoading()).toBe(true);
  const spinner = fixture.nativeElement.querySelector('[data-testid="loading-spinner"]');
  expect(spinner).not.toBeNull();
});

it('WeatherForecastComponent_WhenError_ShowsErrorMessage', async () => {
  fixture.detectChanges();
  const req = httpMock.expectOne('/api/weatherforecast');
  req.flush('Server error', { status: 500, statusText: 'Internal Server Error' });
  fixture.detectChanges();

  expect(component.forecastResource.error()).toBeTruthy();
  const errorEl = fixture.nativeElement.querySelector('[data-testid="error-message"]');
  expect(errorEl).not.toBeNull();
  expect(errorEl.textContent).toContain('error');
});
```

### Testing Angular Material Components (Harnesses)

Use Angular Material test harnesses for reliable interaction — they do not depend on CSS class names or DOM structure.

```typescript
import { HarnessLoader } from '@angular/cdk/testing';
import { TestbedHarnessEnvironment } from '@angular/cdk/testing/testbed';
import { MatTableHarness } from '@angular/material/table/testing';
import { MatButtonHarness } from '@angular/material/button/testing';

let loader: HarnessLoader;

beforeEach(async () => {
  await TestBed.configureTestingModule({
    imports: [WeatherForecastComponent, MatTableModule, MatButtonModule],
    providers: [provideHttpClientTesting()]
  }).compileComponents();
  fixture = TestBed.createComponent(WeatherForecastComponent);
  loader  = TestbedHarnessEnvironment.loader(fixture);
});

it('WeatherForecastComponent_WhenDataLoaded_RendersTable', async () => {
  fixture.detectChanges();
  httpMock.expectOne('/api/weatherforecast').flush([
    { id: '1', temperatureC: 20, summary: 'Sunny', date: '2024-01-01' }
  ]);
  fixture.detectChanges();

  const table = await loader.getHarness(MatTableHarness);
  const rows  = await table.getRows();
  expect(rows.length).toBe(1);
});
```

### Form Validation Test

```typescript
// Pattern: FormComponent_WhenSubmittedWithInvalidData_ShowsValidationErrors
it('CreateForecastForm_WhenSubmittedWithInvalidData_ShowsValidationErrors', async () => {
  fixture.detectChanges();

  // Submit without filling in required fields
  const submitBtn = await loader.getHarness(MatButtonHarness.with({ text: /submit/i }));
  await submitBtn.click();
  fixture.detectChanges();

  // Assert validation error messages are visible
  const errorEl = fixture.nativeElement.querySelector('mat-error');
  expect(errorEl).not.toBeNull();
  expect(errorEl.textContent).toContain('required');
});
```

### Angular Test Commands

```bash
# Run all Angular tests
cd src/Paso.Cap.Angular && npx nx test

# Run tests for a specific library/app
npx nx test weather-forecasts

# Watch mode during development
npx nx test --watch

# Coverage report
npx nx test --coverage
```

### Angular Test Checklist

- [ ] `TestBed.configureTestingModule` uses `imports: [ComponentUnderTest]` (not `declarations`) — standalone components only
- [ ] `provideHttpClientTesting()` replaces `HttpClientModule` in test providers
- [ ] `httpMock.verify()` called in `afterEach` to catch unexpected requests
- [ ] Signal values accessed via `component.mySignal()` — not via async unwrapping
- [ ] Material harnesses used instead of raw DOM queries for Material components
- [ ] `fixture.detectChanges()` called after each state transition
- [ ] No `any` type in test code

---

## Example Test Artifacts

### test.report

```yaml
status: success
summary: "All 47 tests passed (12 unit, 35 integration)"
artifacts_out:
  - test.report
evidence:
  - "dotnet test tests/Paso.Cap.UnitTests/ --logger trx: 12 passed, 0 failed"
  - "dotnet test tests/Paso.Cap.IntegrationTests/ --logger trx: 35 passed, 0 failed"
risks:
  - "Integration tests depend on Docker — CI runner must have Docker available"
decisions: []
recommended_next_agent: review
```

### integration-test.report

```yaml
status: success
summary: "35 integration tests passed across WeatherForecasts and Auth endpoints"
artifacts_out:
  - integration-test.report
evidence:
  - "dotnet test tests/Paso.Cap.IntegrationTests/ -v detailed: 35 passed, 0 failed"
  - "Testcontainers: MsSql container cap-mssql started on port 1433 (dynamic)"
  - "EF Core migrations applied: 3 migrations, database WeatherDb created fresh"
endpoints_tested:
  - "GET /api/weatherforecast/{id} — 200 OK, 404 Not Found"
  - "POST /api/weatherforecast — 201 Created"
  - "PATCH /api/weatherforecast/{id} — 200 OK, 409 Conflict (stale RowVersion)"
  - "POST /api/auth/register — 200 OK"
  - "POST /api/auth/login — 200 OK (JWT returned)"
  - "GET /api/weatherforecast/{id} — 401 Unauthorized (no token, expired, invalid)"
docker_status: "Docker running — Testcontainers operational"
risks:
  - "Integration tests depend on Docker — CI runner must have Docker available"
decisions: []
recommended_next_agent: review
```
