---
name: "cap-template-role-frontend-forms"
description: "Angular 21 reactive forms, validation, and data entry patterns for Dallas."
domain: "frontend"
confidence: "high"
source: "split-from-cap-template-role-frontend"
---

> **Load this module when the task involves forms, user input, validation, or data entry.**

## Reactive Forms & Validation

### Overview

Use Angular 21 reactive forms for all form-based UI. Always use `inject(FormBuilder)` — never constructor injection. Use typed `FormGroup<{...}>` generics for compile-time safety.

### Setup and Imports

```typescript
import {
  Component, ChangeDetectionStrategy, inject, signal
} from '@angular/core';
import {
  FormBuilder, FormControl, FormGroup, ReactiveFormsModule, Validators, ValidationErrors, AbstractControl
} from '@angular/forms';
```

Always add `ReactiveFormsModule` to the component's `imports` array.

### FormBuilder with inject()

```typescript
export class MyFormComponent {
  private readonly fb = inject(FormBuilder);

  readonly form = this.fb.group({
    title: ['', [Validators.required, Validators.minLength(3), Validators.maxLength(100)]],
    email: ['', [Validators.required, Validators.email]],
    description: ['', Validators.maxLength(500)],
  });
}
```

### Typed FormGroup

For stricter typing, declare the type explicitly:

```typescript
readonly form: FormGroup<{
  title: FormControl<string | null>;
  email: FormControl<string | null>;
}> = this.fb.group({
  title: ['', [Validators.required, Validators.minLength(3)]],
  email: ['', [Validators.required, Validators.email]],
});
```

### Built-in Validators

| Validator | Usage |
|-----------|-------|
| `Validators.required` | Field must not be empty |
| `Validators.email` | Must be a valid email format |
| `Validators.minLength(n)` | Minimum character count |
| `Validators.maxLength(n)` | Maximum character count |
| `Validators.min(n)` | Minimum numeric value |
| `Validators.max(n)` | Maximum numeric value |
| `Validators.pattern(regex)` | Regex-based validation |

### Custom Validator Pattern

Custom validators are plain functions. Cross-field validators attach to the `FormGroup`.

```typescript
// Field-level custom validator
function noWhitespaceValidator(control: AbstractControl): ValidationErrors | null {
  const hasWhitespace = (control.value || '').trim().length === 0;
  return hasWhitespace && control.value ? { whitespace: true } : null;
}

// Cross-field validator (password confirmation)
function passwordMatchValidator(group: AbstractControl): ValidationErrors | null {
  const password = group.get('password')?.value;
  const confirm = group.get('confirmPassword')?.value;
  return password === confirm ? null : { passwordMismatch: true };
}
```

Apply cross-field validator at the group level:

```typescript
readonly form = this.fb.group({
  password: ['', [Validators.required, Validators.minLength(8)]],
  confirmPassword: ['', Validators.required],
}, { validators: passwordMatchValidator });
```

### Form Template Pattern

```html
<form [formGroup]="form" (ngSubmit)="onSubmit()">

  <label for="title">Title</label>
  <input id="title" formControlName="title" />
  @if (form.controls.title.hasError('required') && form.controls.title.touched) {
    <span class="error">Title is required.</span>
  }
  @if (form.controls.title.hasError('minlength') && form.controls.title.touched) {
    <span class="error">Title must be at least 3 characters.</span>
  }

  <label for="email">Email</label>
  <input id="email" formControlName="email" type="email" />
  @if (form.controls.email.hasError('required') && form.controls.email.touched) {
    <span class="error">Email is required.</span>
  }
  @if (form.controls.email.hasError('email') && form.controls.email.touched) {
    <span class="error">Enter a valid email address.</span>
  }

  <button type="submit" [disabled]="form.invalid || submitting()">Save</button>
</form>
```

Key rules:
- Use `@if (control.hasError('key') && control.touched)` — not `dirty` — so errors only show after the user has left the field.
- Use `[disabled]="form.invalid || submitting()"` to block double-submissions.

### Form Submission and DTO Mapping

Always map form value to a typed DTO before calling the API. Never pass `form.value` directly.

```typescript
export class CreateWeatherForecastFormComponent {
  private readonly fb = inject(FormBuilder);
  private readonly service = inject(WeatherForecastService);
  private readonly router = inject(Router);

  readonly submitting = signal(false);

  readonly form = this.fb.group({
    summary: ['', [Validators.required, Validators.maxLength(200)]],
    temperatureC: [0, [Validators.required, Validators.min(-100), Validators.max(100)]],
  });

  onSubmit(): void {
    if (this.form.invalid) return;
    this.submitting.set(true);

    const dto: CreateWeatherForecastDto = {
      summary: this.form.controls.summary.value!,
      temperatureC: this.form.controls.temperatureC.value!,
    };

    this.service.createWeatherForecast(dto)
      .pipe(takeUntilDestroyed(inject(DestroyRef)))
      .subscribe({
        next: () => this.router.navigate(['/weatherforecast']),
        error: () => this.submitting.set(false),
        complete: () => this.submitting.set(false),
      });
  }
}
```

### Edit Form Pattern (populate from existing data)

Use `form.patchValue()` to pre-populate fields when editing:

```typescript
readonly id = input.required<string>();

private readonly existing = rxResource({
  params: this.id,
  stream: ({ params }) => this.service.getWeatherForecast(params),
});

constructor() {
  effect(() => {
    const data = this.existing.value();
    if (data) {
      this.form.patchValue({
        summary: data.summary ?? '',
        temperatureC: data.temperatureC ?? 0,
      });
    }
  });
}
```

### Full Example: Create/Edit Form Component

```typescript
import {
  Component, ChangeDetectionStrategy, inject, signal, DestroyRef, input, effect
} from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { WeatherForecastService, CreateWeatherForecastDto } from '@paso.cap.angular/api-client';

@Component({
  selector: 'app-weather-forecast-form',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      <div>
        <label>Summary</label>
        <input formControlName="summary" />
        @if (form.controls.summary.hasError('required') && form.controls.summary.touched) {
          <span class="error">Summary is required.</span>
        }
      </div>
      <div>
        <label>Temperature (C)</label>
        <input type="number" formControlName="temperatureC" />
        @if (form.controls.temperatureC.hasError('required') && form.controls.temperatureC.touched) {
          <span class="error">Temperature is required.</span>
        }
      </div>
      <button type="submit" [disabled]="form.invalid || submitting()">Save</button>
      <button type="button" (click)="cancel()">Cancel</button>
    </form>
  `,
})
export class WeatherForecastFormComponent {
  private readonly fb = inject(FormBuilder);
  private readonly service = inject(WeatherForecastService);
  private readonly router = inject(Router);
  private readonly destroyRef = inject(DestroyRef);

  readonly submitting = signal(false);

  readonly form = this.fb.group({
    summary: ['', [Validators.required, Validators.maxLength(200)]],
    temperatureC: [0, [Validators.required, Validators.min(-100), Validators.max(100)]],
  });

  onSubmit(): void {
    if (this.form.invalid) return;
    this.submitting.set(true);

    const dto: CreateWeatherForecastDto = {
      summary: this.form.controls.summary.value!,
      temperatureC: this.form.controls.temperatureC.value!,
    };

    this.service.createWeatherForecast(dto)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: () => this.router.navigate(['/weatherforecast']),
        error: () => this.submitting.set(false),
        complete: () => this.submitting.set(false),
      });
  }

  cancel(): void {
    this.router.navigate(['/weatherforecast']);
  }
}
```

### Checklist: Reactive Forms

- [ ] `inject(FormBuilder)` used — not constructor injection
- [ ] `ReactiveFormsModule` in component `imports`
- [ ] Error display uses `hasError('key') && touched` — not `dirty`
- [ ] Submit handler guards with `if (this.form.invalid) return;`
- [ ] Form value mapped to typed DTO before API call
- [ ] `submitting` signal prevents double-submit
- [ ] Cross-field validators attached to `FormGroup`, not individual controls
