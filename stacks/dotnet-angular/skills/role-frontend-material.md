---
name: "cap-template-role-frontend-material"
description: "Angular Material UI, API client generation, and HTTP error handling patterns for Dallas."
domain: "frontend"
confidence: "high"
source: "split-from-cap-template-role-frontend"
---

> **Load this module when the task involves UI styling, Angular Material, error handling, or API client integration.**

## Angular Material Integration

### Installation

```bash
npm install @angular/material @angular/cdk
```

Note: `@angular/material` is not currently listed in `package.json`. Add it only after confirming with the user, per project conventions (see "When to Stop and Ask" boundary in the core bundle).

### Theme Setup in styles.scss

File: `src/Paso.Cap.Angular/src/styles.scss`

```scss
@use '@angular/material' as mat;

// Include core styles (animations, ripple, etc.)
@include mat.core();

// Define a custom theme
$cap-primary: mat.define-palette(mat.$indigo-palette);
$cap-accent:  mat.define-palette(mat.$pink-palette, A200, A100, A400);
$cap-warn:    mat.define-palette(mat.$red-palette);

$cap-theme: mat.define-light-theme((
  color: (
    primary: $cap-primary,
    accent:  $cap-accent,
    warn:    $cap-warn,
  ),
  typography: mat.define-typography-config(),
  density: 0,
));

@include mat.all-component-themes($cap-theme);
```

For dark mode variant:
```scss
$cap-dark-theme: mat.define-dark-theme((
  color: (
    primary: $cap-primary,
    accent:  $cap-accent,
    warn:    $cap-warn,
  ),
));

.dark-theme {
  @include mat.all-component-colors($cap-dark-theme);
}
```

### Standalone Component Imports Reference

Each Angular Material module is imported individually in the component `imports` array. Never import `MaterialModule` (it does not exist in modern Angular Material).

#### Layout

```typescript
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatSidenavModule } from '@angular/material/sidenav';   // MatSidenav, MatSidenavContainer, MatSidenavContent
import { MatListModule } from '@angular/material/list';         // MatList, MatListItem, MatNavList
```

#### Data Display

```typescript
import { MatTableModule } from '@angular/material/table';       // MatTable, MatHeaderRow, MatRow, MatColumnDef
import { MatPaginatorModule } from '@angular/material/paginator'; // MatPaginator
import { MatSortModule } from '@angular/material/sort';         // MatSort, MatSortHeader
```

#### Forms

```typescript
import { MatFormFieldModule } from '@angular/material/form-field'; // MatFormField, MatLabel, MatError, MatHint
import { MatInputModule } from '@angular/material/input';          // matInput directive
import { MatSelectModule } from '@angular/material/select';        // MatSelect, MatOption
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatCheckboxModule } from '@angular/material/checkbox';
```

#### Buttons and Icons

```typescript
import { MatButtonModule } from '@angular/material/button';     // matButton, matRaisedButton, matFlatButton, matStrokedButton
import { MatIconButtonModule } from '@angular/material/button'; // matIconButton (same module)
import { MatFabButton } from '@angular/material/button';        // matFab, matMiniFab
import { MatIconModule } from '@angular/material/icon';         // MatIcon, mat-icon
```

#### Feedback and Overlays

```typescript
import { MatSnackBarModule } from '@angular/material/snack-bar'; // injected as MatSnackBar service
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatDialogModule } from '@angular/material/dialog';     // MatDialog service, MatDialogRef, MAT_DIALOG_DATA
```

#### Navigation and Content

```typescript
import { MatCardModule } from '@angular/material/card';         // MatCard, MatCardContent, MatCardHeader, MatCardActions
import { MatChipsModule } from '@angular/material/chips';       // MatChip, MatChipSet
import { MatMenuModule } from '@angular/material/menu';         // MatMenu, MatMenuItem, MatMenuTrigger
import { MatTabsModule } from '@angular/material/tabs';         // MatTabGroup, MatTab
import { MatTooltipModule } from '@angular/material/tooltip';   // matTooltip directive
```

### Layout Component Pattern (Toolbar + Sidenav + Router Outlet)

```typescript
@Component({
  selector: 'app-shell',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    RouterModule,
    MatToolbarModule,
    MatSidenavModule,
    MatListModule,
    MatIconModule,
    MatButtonModule,
  ],
  template: `
    <mat-sidenav-container class="shell-container">
      <mat-sidenav #sidenav mode="side" opened>
        <mat-nav-list>
          <a mat-list-item routerLink="/weatherforecast" routerLinkActive="active">
            <mat-icon matListItemIcon>cloud</mat-icon>
            <span matListItemTitle>Weather</span>
          </a>
        </mat-nav-list>
      </mat-sidenav>

      <mat-sidenav-content>
        <mat-toolbar color="primary">
          <button mat-icon-button (click)="sidenav.toggle()">
            <mat-icon>menu</mat-icon>
          </button>
          <span>CAP Template</span>
        </mat-toolbar>

        <main class="content">
          <router-outlet />
        </main>
      </mat-sidenav-content>
    </mat-sidenav-container>
  `,
  styles: [`
    .shell-container { height: 100vh; }
    .content { padding: 16px; }
    mat-sidenav { width: 220px; }
  `],
})
export class AppShellComponent {}
```

### Table Component Pattern (mat-table + Sort + Paginator)

```typescript
@Component({
  selector: 'app-forecast-table',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    MatTableModule,
    MatSortModule,
    MatPaginatorModule,
    MatProgressBarModule,
    DatePipe,
  ],
  template: `
    @if (loading()) {
      <mat-progress-bar mode="indeterminate" />
    }

    <table mat-table [dataSource]="dataSource" matSort>
      <ng-container matColumnDef="date">
        <th mat-header-cell *matHeaderCellDef mat-sort-header>Date</th>
        <td mat-cell *matCellDef="let row">{{ row.date | date:'dd.MM.yyyy' }}</td>
      </ng-container>

      <ng-container matColumnDef="temperatureC">
        <th mat-header-cell *matHeaderCellDef mat-sort-header>Temp (C)</th>
        <td mat-cell *matCellDef="let row">{{ row.temperatureC }}</td>
      </ng-container>

      <ng-container matColumnDef="summary">
        <th mat-header-cell *matHeaderCellDef mat-sort-header>Summary</th>
        <td mat-cell *matCellDef="let row">{{ row.summary }}</td>
      </ng-container>

      <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
      <tr mat-row *matRowDef="let row; columns: displayedColumns;" (click)="onRowClick(row)"></tr>
    </table>

    <mat-paginator [pageSizeOptions]="[10, 25, 50]" showFirstLastButtons />
  `,
})
export class ForecastTableComponent implements AfterViewInit {
  @ViewChild(MatSort) sort!: MatSort;
  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly loading = signal(false);
  readonly displayedColumns = ['date', 'temperatureC', 'summary'];
  readonly dataSource = new MatTableDataSource<WeatherForecastDto>([]);

  private readonly service = inject(WeatherForecastService);
  private readonly router = inject(Router);
  private readonly destroyRef = inject(DestroyRef);

  ngAfterViewInit(): void {
    this.dataSource.sort = this.sort;
    this.dataSource.paginator = this.paginator;
    this.loadData();
  }

  private loadData(): void {
    this.loading.set(true);
    this.service.getWeatherForecasts()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: data => { this.dataSource.data = data; this.loading.set(false); },
        error: () => this.loading.set(false),
      });
  }

  onRowClick(row: WeatherForecastDto): void {
    this.router.navigate(['/weatherforecast', row.id]);
  }
}
```

Note: Import `MatTableDataSource` from `@angular/material/table`.

### Form Component Pattern (mat-form-field + matInput + mat-error)

Combine `MatFormFieldModule`, `MatInputModule`, and `ReactiveFormsModule`:

```html
<form [formGroup]="form" (ngSubmit)="onSubmit()">
  <mat-form-field appearance="outline">
    <mat-label>Summary</mat-label>
    <input matInput formControlName="summary" placeholder="Enter summary" />
    @if (form.controls.summary.hasError('required') && form.controls.summary.touched) {
      <mat-error>Summary is required.</mat-error>
    }
    @if (form.controls.summary.hasError('maxlength') && form.controls.summary.touched) {
      <mat-error>Summary must not exceed 200 characters.</mat-error>
    }
    <mat-hint>Describe the forecast condition</mat-hint>
  </mat-form-field>

  <mat-form-field appearance="outline">
    <mat-label>Temperature (C)</mat-label>
    <input matInput type="number" formControlName="temperatureC" />
    @if (form.controls.temperatureC.hasError('required') && form.controls.temperatureC.touched) {
      <mat-error>Temperature is required.</mat-error>
    }
  </mat-form-field>

  <mat-form-field appearance="outline">
    <mat-label>Category</mat-label>
    <mat-select formControlName="category">
      <mat-option value="hot">Hot</mat-option>
      <mat-option value="cold">Cold</mat-option>
      <mat-option value="mild">Mild</mat-option>
    </mat-select>
  </mat-form-field>

  <div class="form-actions">
    <button mat-stroked-button type="button" (click)="cancel()">Cancel</button>
    <button mat-flat-button color="primary" type="submit" [disabled]="form.invalid || submitting()">
      @if (submitting()) {
        <mat-progress-spinner diameter="18" mode="indeterminate" />
      } @else {
        Save
      }
    </button>
  </div>
</form>
```

Key rule: Use `mat-error` inside `mat-form-field` — not a plain `<span>` — so Material handles error display and accessibility.

### MatSnackBar Service Pattern (Success/Error Toasts)

Inject `MatSnackBar` in any component or service:

```typescript
import { MatSnackBar } from '@angular/material/snack-bar';

export class MyComponent {
  private readonly snackBar = inject(MatSnackBar);

  private showSuccess(message: string): void {
    this.snackBar.open(message, 'Dismiss', {
      duration: 3000,
      panelClass: ['snack-success'],
    });
  }

  private showError(message: string): void {
    this.snackBar.open(message, 'Close', {
      duration: 5000,
      panelClass: ['snack-error'],
    });
  }
}
```

Add CSS classes in `styles.scss`:
```scss
.snack-success .mat-mdc-snack-bar-container { --mdc-snackbar-container-color: #2e7d32; }
.snack-error   .mat-mdc-snack-bar-container { --mdc-snackbar-container-color: #c62828; }
```

### Confirm Dialog Pattern (MatDialog)

**Dialog component:**
```typescript
import { Component, inject } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';

export interface ConfirmDialogData {
  title: string;
  message: string;
  confirmLabel?: string;
}

@Component({
  selector: 'app-confirm-dialog',
  standalone: true,
  imports: [MatDialogModule, MatButtonModule],
  template: `
    <h2 mat-dialog-title>{{ data.title }}</h2>
    <mat-dialog-content>{{ data.message }}</mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-stroked-button mat-dialog-close>Cancel</button>
      <button mat-flat-button color="warn" [mat-dialog-close]="true">
        {{ data.confirmLabel ?? 'Confirm' }}
      </button>
    </mat-dialog-actions>
  `,
})
export class ConfirmDialogComponent {
  readonly data = inject<ConfirmDialogData>(MAT_DIALOG_DATA);
  readonly dialogRef = inject(MatDialogRef<ConfirmDialogComponent>);
}
```

**Usage in a parent component:**
```typescript
import { MatDialog } from '@angular/material/dialog';
import { ConfirmDialogComponent, ConfirmDialogData } from './confirm-dialog.component';

export class ForecastListPageComponent {
  private readonly dialog = inject(MatDialog);
  private readonly service = inject(WeatherForecastService);
  private readonly destroyRef = inject(DestroyRef);

  deleteItem(id: string): void {
    const data: ConfirmDialogData = {
      title: 'Delete Forecast',
      message: 'This action cannot be undone. Are you sure?',
      confirmLabel: 'Delete',
    };

    this.dialog.open(ConfirmDialogComponent, { data })
      .afterClosed()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(confirmed => {
        if (confirmed) {
          this.service.deleteWeatherForecast(id)
            .pipe(takeUntilDestroyed(this.destroyRef))
            .subscribe(() => this.refresh());
        }
      });
  }
}
```

### Checklist: Angular Material

- [ ] `@angular/material` and `@angular/cdk` installed (confirm with user first if not in `package.json`)
- [ ] Theme configured in `src/styles.scss` with `@use '@angular/material' as mat`
- [ ] Each Material module imported individually in component `imports` array
- [ ] `mat-error` used inside `mat-form-field` (not standalone `<span>`)
- [ ] `MatSnackBar` injected via `inject(MatSnackBar)` for user feedback
- [ ] Dialog components are standalone with `MatDialogModule` imported
- [ ] `MatProgressBar` / `MatProgressSpinner` used to show loading states

---

## API Client Generation & HTTP Error Handling

### OpenAPI Client Generation

The project uses `@openapitools/openapi-generator-cli` to generate a typed Angular HTTP client from the backend OpenAPI spec.

**Step 1: Generate the OpenAPI spec from the backend**

```bash
cd src/Paso.Cap.Angular
npm run generate-openapi   # Builds Paso.Cap.Web → emits .gen/openapi.json
```

This runs: `dotnet build ../Paso.Cap.Web -c Release`

**Step 2: Generate the Angular HTTP client**

```bash
npm run generate-client
```

This runs:
```
npx @openapitools/openapi-generator-cli generate \
  -i ../../.gen/openapi.json \
  -g typescript-angular \
  -o ./libs/api-client/src
```

Generated output location: `src/Paso.Cap.Angular/libs/api-client/src/`

### Path Alias for the Generated Client

The generated client is exposed via Nx path alias:

```typescript
import { WeatherForecastService, CreateWeatherForecastDto, WeatherForecastDto } from '@paso.cap.angular/api-client';
```

This alias is configured in `tsconfig.base.json`. Never use deep relative imports into `libs/api-client/src/` directly.

### App Config: API Base Path

The `Configuration` token from the generated client is provided in `app.config.ts` using `environment.apiUrl`:

```typescript
// src/app/app.config.ts
{
  provide: Configuration,
  useFactory: () => new Configuration({ basePath: environment.apiUrl })
}
```

For local development, the proxy in `proxy.conf.json` forwards `/api/**` to `http://localhost:5043`.

### HTTP Error Interceptor Pattern

Create an interceptor to catch HTTP errors globally and display `MatSnackBar` notifications:

```typescript
// src/app/core/interceptors/http-error.interceptor.ts
import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { catchError, throwError } from 'rxjs';

export const httpErrorInterceptor: HttpInterceptorFn = (req, next) => {
  const snackBar = inject(MatSnackBar);
  const router = inject(Router);

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      switch (error.status) {
        case 0:
          snackBar.open('Network error — check your connection.', 'Close', { duration: 5000 });
          break;
        case 400:
          snackBar.open(error.error?.detail ?? 'Invalid request.', 'Close', { duration: 5000 });
          break;
        case 401:
          router.navigate(['/login']);
          break;
        case 403:
          snackBar.open('You do not have permission to perform this action.', 'Close', { duration: 5000 });
          break;
        case 404:
          snackBar.open('Resource not found.', 'Close', { duration: 4000 });
          break;
        case 500:
        default:
          snackBar.open('An unexpected error occurred. Please try again.', 'Close', { duration: 6000 });
          break;
      }
      return throwError(() => error);
    })
  );
};
```

**Register in `app.config.ts`:**

```typescript
import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { httpErrorInterceptor } from './core/interceptors/http-error.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(appRoutes, withComponentInputBinding()),
    provideHttpClient(
      withFetch(),
      withInterceptors([httpErrorInterceptor]),
    ),
    {
      provide: Configuration,
      useFactory: () => new Configuration({ basePath: environment.apiUrl })
    },
  ],
};
```

### Loading State Pattern with MatProgressBar

Use a signal-based loading state combined with `MatProgressBar` in the template:

```typescript
readonly loading = signal(false);
readonly forecasts = signal<WeatherForecastDto[]>([]);

private loadForecasts(): void {
  this.loading.set(true);
  this.service.getWeatherForecasts()
    .pipe(takeUntilDestroyed(this.destroyRef))
    .subscribe({
      next: data => { this.forecasts.set(data); this.loading.set(false); },
      error: ()   => { this.loading.set(false); },  // snackBar handled by interceptor
    });
}
```

```html
@if (loading()) {
  <mat-progress-bar mode="indeterminate" />
}
```

Alternatively, use `rxResource` (as in the existing `WeatherForecastListPageComponent`) and branch on `.status()`:

```html
@if (forecasts.status() === 'loading') {
  <mat-progress-bar mode="indeterminate" />
} @else if (forecasts.status() === 'error') {
  <p class="error-msg">Failed to load data.</p>
} @else {
  <!-- render data -->
}
```

### Error Boundary Pattern (Component-Level)

For isolated error boundaries within a page, use a dedicated error state signal:

```typescript
readonly error = signal<string | null>(null);

private load(): void {
  this.loading.set(true);
  this.error.set(null);

  this.service.getWeatherForecast(this.id())
    .pipe(takeUntilDestroyed(this.destroyRef))
    .subscribe({
      next: data  => { this.item.set(data); this.loading.set(false); },
      error: (err: HttpErrorResponse) => {
        this.error.set(err.error?.detail ?? 'Failed to load item.');
        this.loading.set(false);
      },
    });
}
```

```html
@if (loading()) {
  <mat-progress-spinner mode="indeterminate" diameter="40" />
} @else if (error()) {
  <mat-card class="error-card">
    <mat-card-content>{{ error() }}</mat-card-content>
    <mat-card-actions>
      <button mat-stroked-button (click)="load()">Retry</button>
    </mat-card-actions>
  </mat-card>
} @else {
  <!-- render item -->
}
```

### Checklist: API Client & HTTP

- [ ] Client regenerated after any backend DTO or endpoint change (`npm run generate-openapi && npm run generate-client`)
- [ ] Always import from `@paso.cap.angular/api-client` — never from deep relative paths
- [ ] `httpErrorInterceptor` registered in `app.config.ts` via `withInterceptors`
- [ ] 401 handler navigates to `/login`; 403 handler shows permission error
- [ ] Loading state reflected in UI via `MatProgressBar` or `MatProgressSpinner`
- [ ] Error state displayed inline with retry option on detail pages
- [ ] Component-level error does not swallow the error — `throwError(() => error)` re-throws after snackbar
