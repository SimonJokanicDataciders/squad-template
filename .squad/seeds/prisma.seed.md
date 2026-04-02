---
name: "prisma"
matches: ["prisma", "prisma orm"]
version: "6.x"
updated: "2026-03-30"
status: "verified"
---

# Prisma ORM — Seed

## Critical Rules (LLM MUST follow these)
1. Design schema-first — define models in `schema.prisma` before writing any query code.
2. Always use the typed Prisma client — never fall back to raw SQL unless absolutely necessary.
3. Use `select` or `include` to fetch only the fields you need — never pull entire rows by default.
4. Wrap multi-table writes in `prisma.$transaction()` — partial writes without transactions corrupt data.
5. Handle unique constraint violations explicitly (`PrismaClientKnownRequestError` code `P2002`) — do not let them bubble as 500s.
6. Define relations in the schema and use nested reads/writes — avoid manual JOIN-like query chains.

## Golden Example
```prisma
// prisma/schema.prisma
model Order {
  id        Int         @id @default(autoincrement())
  status    String      @default("pending")
  items     OrderItem[]
  createdAt DateTime    @default(now())
}

model OrderItem {
  id        Int    @id @default(autoincrement())
  orderId   Int
  order     Order  @relation(fields: [orderId], references: [id])
  productId Int
  quantity  Int
}
```

```ts
// src/services/order.service.ts
import { PrismaClient, Prisma } from "@prisma/client";

const prisma = new PrismaClient();

export async function createOrder(items: { productId: number; quantity: number }[]) {
  return prisma.$transaction(async (tx) => {
    const order = await tx.order.create({
      data: {
        items: {
          create: items.map((i) => ({
            productId: i.productId,
            quantity: i.quantity,
          })),
        },
      },
      select: {
        id: true,
        status: true,
        items: { select: { productId: true, quantity: true } },
      },
    });
    return order;
  });
}

export async function getOrder(id: number) {
  return prisma.order.findUnique({
    where: { id },
    select: {
      id: true,
      status: true,
      createdAt: true,
      items: { select: { productId: true, quantity: true } },
    },
  });
}

export async function safeCreateUniqueResource(data: Prisma.OrderCreateInput) {
  try {
    return await prisma.order.create({ data });
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
      throw new Error("A record with that unique field already exists");
    }
    throw err;
  }
}
```

## Common LLM Mistakes
- Calling `findMany()` / `findUnique()` without `select` or `include` — fetches every column, wasting bandwidth and leaking fields.
- Writing multiple related `create()` / `update()` calls outside a `$transaction` — leaves data in an inconsistent state on partial failure.
- Ignoring `P2002` unique constraint errors — returns a confusing 500 instead of a clear 409 Conflict to the client.
- Writing manual JOIN-style queries instead of using Prisma relations and nested reads — defeats the purpose of the ORM.
- Passing unvalidated input directly into `where` or `data` — risks unexpected queries even though Prisma parameterizes by default.
