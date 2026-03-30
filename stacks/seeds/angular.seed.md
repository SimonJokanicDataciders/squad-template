---
name: "angular"
matches: ["angular", "angularjs", "ng"]
version: "21.x"
updated: "2026-03-30"
status: "verified"
---

# Angular 21 — Seed

## Critical Rules (LLM MUST follow these)
1. Use standalone components exclusively — never create or reference `NgModule` classes.
2. Use `ChangeDetectionStrategy.OnPush` on every component — never rely on the default change detection strategy.
3. Use `inject()` for dependency injection — never use constructor parameter injection.
4. Use `signal()` and `computed()` for all reactive state — never manage state with plain class fields that require manual change detection.
5. Lazy-load routes with `loadComponent` — never eagerly import routed components.
6. Never call `.subscribe()` without `takeUntilDestroyed()` — all manual subscriptions must be cleaned up automatically on destroy.

## Golden Example
```ts
// src/app/products/product.service.ts
import { Injectable, inject } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { Observable } from "rxjs";

export interface Product {
  id: string;
  name: string;
  price: number;
}

@Injectable({ providedIn: "root" })
export class ProductService {
  private readonly http = inject(HttpClient);

  getAll(): Observable<Product[]> {
    return this.http.get<Product[]>("/api/products");
  }

  getById(id: string): Observable<Product> {
    return this.http.get<Product>(`/api/products/${id}`);
  }
}

// src/app/products/product-list.component.ts
import { Component, ChangeDetectionStrategy, inject, signal, computed, OnInit } from "@angular/core";
import { takeUntilDestroyed } from "@angular/core/rxjs-interop";
import { DestroyRef } from "@angular/core";
import { ProductService, Product } from "./product.service";

@Component({
  selector: "app-product-list",
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <h2>Products ({{ totalCount() }})</h2>
    <ul>
      @for (product of products(); track product.id) {
        <li>{{ product.name }} — {{ product.price | currency }}</li>
      }
    </ul>
    @if (loading()) {
      <p>Loading…</p>
    }
  `,
})
export class ProductListComponent implements OnInit {
  private readonly productService = inject(ProductService);
  private readonly destroyRef = inject(DestroyRef);

  readonly products = signal<Product[]>([]);
  readonly loading = signal(true);
  readonly totalCount = computed(() => this.products().length);

  ngOnInit(): void {
    this.productService
      .getAll()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((data) => {
        this.products.set(data);
        this.loading.set(false);
      });
  }
}

// src/app/app.routes.ts
import { Routes } from "@angular/router";

export const routes: Routes = [
  {
    path: "products",
    loadComponent: () =>
      import("./products/product-list.component").then((m) => m.ProductListComponent),
  },
  { path: "", redirectTo: "products", pathMatch: "full" },
];
```

## Common LLM Mistakes
- Generating `@NgModule` classes and `declarations` arrays — Angular 21 is standalone-first; modules are legacy.
- Using constructor parameter injection (`constructor(private svc: MyService)`) instead of `inject()` — breaks the modern DI pattern.
- Calling `.subscribe()` without `takeUntilDestroyed()` — causes memory leaks from orphaned subscriptions.
- Leaving `ChangeDetectionStrategy.Default` — triggers unnecessary re-renders across the entire component tree.
- Storing state in plain class fields instead of `signal()` / `computed()` — bypasses the reactivity model and causes stale UI.
