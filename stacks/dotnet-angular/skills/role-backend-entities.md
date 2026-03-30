---
name: "cap-template-role-backend-entities"
description: "Multi-entity FK patterns for Fenster — parent/child entities, relationships, soft-delete"
domain: "backend"
confidence: "high"
source: "manual"
---

> **Load this module when the task involves creating new entities, FK relationships, or multi-entity features.**

---

## 14. Multi-Entity Domain Patterns (FK Relationships)

### Parent Entity Pattern

```csharp
// File: src/Paso.Cap.Domain/Notes/Category.cs
namespace Paso.Cap.Domain.Notes;

/// <summary>A category that groups related notes.</summary>
public sealed class Category : IAggregateRoot {
    public Guid Id { get; set; }

    /// <summary>Display name for the category.</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>Hex colour code for UI display (e.g. "#FF5733").</summary>
    public string? Color { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.MinValue;

#if PostgreSQL
    public uint RowVersion { get; set; }
#else
    public byte[] RowVersion { get; set; } = [];
#endif

    // Navigation property — EF Core populates this; keep IReadOnlyList in the public API
    private readonly List<Note> _notes = [];
    public IReadOnlyList<Note> Notes => _notes;
}
```

### Child Entity Pattern (FK to Parent and to ApplicationUser)

```csharp
// File: src/Paso.Cap.Domain/Notes/Note.cs
namespace Paso.Cap.Domain.Notes;

/// <summary>A note belonging to a category, authored by a user.</summary>
public sealed class Note : IAggregateRoot {
    public Guid Id { get; set; }

    /// <summary>Short heading for the note.</summary>
    public string Title { get; set; } = string.Empty;

    /// <summary>Full body text of the note.</summary>
    public string? Content { get; set; }

    // FK — Category
    public Guid CategoryId { get; set; }
    public Category? Category { get; set; }

    // FK — ApplicationUser (created-by)
    public Guid CreatedById { get; set; }
    public ApplicationUser? CreatedBy { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.MinValue;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.MinValue;

    /// <summary>Soft-delete flag. Use instead of hard deletes.</summary>
    public bool IsArchived { get; set; }

#if PostgreSQL
    public uint RowVersion { get; set; }
#else
    public byte[] RowVersion { get; set; } = [];
#endif
}
```

### EF Configuration — Parent (Category)

```csharp
// File: src/Paso.Cap.Domain/Notes/CategoryConfiguration.cs
namespace Paso.Cap.Domain.Notes;

internal sealed class CategoryConfiguration : IEntityTypeConfiguration<Category> {
    public void Configure(EntityTypeBuilder<Category> builder) {
        builder.ToTable(nameof(Category), "Notes");
#if PostgreSQL
        builder.HasKey(e => e.Id);
        builder.HasIndex(e => e.CreatedAt);
#else
        builder.HasKey(e => e.Id).IsClustered(false);
        builder.HasIndex(e => e.CreatedAt).IsClustered();
#endif
        builder.Property(e => e.Name).HasMaxLength(100).IsRequired();
        builder.Property(e => e.Color).HasMaxLength(7);
        builder.Property(e => e.RowVersion).IsRowVersion();
    }
}
```

### EF Configuration — Child (Note) with FK Relationships

```csharp
// File: src/Paso.Cap.Domain/Notes/NoteConfiguration.cs
namespace Paso.Cap.Domain.Notes;

internal sealed class NoteConfiguration : IEntityTypeConfiguration<Note> {
    public void Configure(EntityTypeBuilder<Note> builder) {
        builder.ToTable(nameof(Note), "Notes");
#if PostgreSQL
        builder.HasKey(e => e.Id);
        builder.HasIndex(e => e.CreatedAt);
#else
        builder.HasKey(e => e.Id).IsClustered(false);
        builder.HasIndex(e => e.CreatedAt).IsClustered();
#endif
        builder.Property(e => e.Title).HasMaxLength(200).IsRequired();
        builder.Property(e => e.Content).HasMaxLength(4000);
        builder.Property(e => e.RowVersion).IsRowVersion();

        // FK: Note -> Category (cascade delete — deleting a category removes its notes)
        builder.HasOne(e => e.Category)
               .WithMany(c => c.Notes)
               .HasForeignKey(e => e.CategoryId)
               .OnDelete(DeleteBehavior.Cascade);

        // FK: Note -> ApplicationUser (restrict — deleting a user must not cascade to notes)
        builder.HasOne(e => e.CreatedBy)
               .WithMany()
               .HasForeignKey(e => e.CreatedById)
               .OnDelete(DeleteBehavior.Restrict);

        // Index FK columns for join/filter performance
        builder.HasIndex(e => e.CategoryId);
        builder.HasIndex(e => e.CreatedById);
        builder.HasIndex(e => new { e.CategoryId, e.IsArchived }); // composite for filtered queries
    }
}
```

**Cascade behaviour rules:**
- `DeleteBehavior.Cascade` — use when the child has no meaning without the parent (notes without a category).
- `DeleteBehavior.Restrict` — use when the FK references a shared entity (users, lookup tables); prevents accidental data loss.
- `DeleteBehavior.SetNull` — use when the FK is nullable and orphaned children are still valid.

### DbSet Registration

```csharp
// In ApplicationDbContext.cs
public DbSet<Category> Categories { get; set; }
public DbSet<Note> Notes { get; set; }
```

### Compiled Query Patterns with .Include()

```csharp
// In NoteService.cs
private static Expression<Func<Note, NoteDto>> MapDto =>
    entity => new NoteDto {
        Id = entity.Id,
        Title = entity.Title,
        Content = entity.Content,
        CategoryId = entity.CategoryId,
        CategoryName = entity.Category!.Name,
        CreatedById = entity.CreatedById,
        CreatedAt = entity.CreatedAt,
        UpdatedAt = entity.UpdatedAt,
        IsArchived = entity.IsArchived,
    };

// Compiled query — filter by CategoryId, exclude archived
private static readonly Func<ApplicationDbContext, Guid, IAsyncEnumerable<NoteDto>> QueryByCategory =
    EF.CompileAsyncQuery((ApplicationDbContext context, Guid categoryId) =>
        context.Notes
            .Where(x => x.CategoryId == categoryId && !x.IsArchived)
            .OrderBy(x => x.CreatedAt)
            .Include(x => x.Category)   // needed for CategoryName in projection
            .Select(MapDto));

// Compiled query — single note by Id
private static readonly Func<ApplicationDbContext, Guid, IAsyncEnumerable<NoteDto>> QueryById =
    EF.CompileAsyncQuery((ApplicationDbContext context, Guid id) =>
        context.Notes
            .Where(x => x.Id == id && !x.IsArchived)
            .Take(1)
            .Include(x => x.Category)
            .Select(MapDto));
```

**Note on `.Include()` with compiled queries:** EF Core supports `.Include()` inside `EF.CompileAsyncQuery`. Place `.Include()` before `.Select()`.

### Service Pattern — Filtering by FK

```csharp
// File: src/Paso.Cap.Domain/Notes/NoteService.cs
namespace Paso.Cap.Domain.Notes;

/// <summary>Domain service for managing notes and categories.</summary>
public sealed class NoteService {
    private readonly ApplicationDbContext _dbContext;
    private readonly TimeProvider _timeProvider;

    public NoteService(ApplicationDbContext dbContext, TimeProvider timeProvider) {
        _dbContext = dbContext;
        _timeProvider = timeProvider;
    }

    /// <summary>Returns all active notes for a given category.</summary>
    public async Task<List<NoteDto>> GetNotesByCategory(
        Guid categoryId, CancellationToken cancellationToken = default) {
        return await QueryByCategory(_dbContext, categoryId)
            .ToListAsync(cancellationToken);
    }

    /// <summary>Returns a single note by ID. Throws <see cref="EntityNotFoundException"/> if not found or archived.</summary>
    public async Task<NoteDto> GetNoteById(
        Guid id, CancellationToken cancellationToken = default) {
        return await QueryById(_dbContext, id).FirstOrDefaultAsync(cancellationToken)
            ?? throw new EntityNotFoundException();
    }

    /// <summary>Creates a new note in the specified category.</summary>
    public async Task CreateNote(
        CreateNoteDto createDto, Guid userId, CancellationToken cancellationToken = default) {
        if (createDto is null) throw new ArgumentNullException(nameof(createDto));
        var nowTime = _timeProvider.GetUtcNow();
        var entity = new Note {
#if PostgreSQL
            Id = createDto.Id ?? Guid.CreateVersion7(nowTime),
#else
            Id = createDto.Id ?? Guid.NewGuid(),
#endif
            Title = createDto.Title,
            Content = createDto.Content,
            CategoryId = createDto.CategoryId,
            CreatedById = userId,
            CreatedAt = nowTime,
            UpdatedAt = nowTime,
        };
        _dbContext.Notes.Add(entity);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    /// <summary>Soft-deletes a note by setting <see cref="Note.IsArchived"/> to <c>true</c>.</summary>
    public async Task ArchiveNote(
        Guid id, CancellationToken cancellationToken = default) {
        var executionStrategy = _dbContext.Database.CreateExecutionStrategy();
        await executionStrategy.ExecuteInTransactionAsync(async () => {
            var entity = await _dbContext.Notes.FindAsync([id], cancellationToken)
                ?? throw new EntityNotFoundException();
            entity.IsArchived = true;
            entity.UpdatedAt = _timeProvider.GetUtcNow();
            _dbContext.Notes.Update(entity);
            try {
                await _dbContext.SaveChangesAsync(cancellationToken);
            } catch (DbUpdateConcurrencyException ex) {
                throw new ConcurrencyException(ex);
            }
        }, static () => Task.FromResult(true));
    }
}
```

### Soft-Delete Pattern

Prefer soft deletes (`IsArchived = true`) over hard `DELETE` for user-generated content. Rules:

- All read queries must filter `!x.IsArchived` unless explicitly fetching archived items.
- Expose an `Archive` action endpoint instead of `DELETE` for soft-delete entities.
- Reserve `DELETE` endpoints for hard-delete scenarios (admin, cleanup jobs).
- Add a composite index on `(CategoryId, IsArchived)` for common filtered queries.

### DTOs for Parent/Child

```csharp
// File: src/Paso.Cap.Domain/Notes/NoteDtos.cs
namespace Paso.Cap.Domain.Notes;

/// <summary>Full note projection returned by read endpoints.</summary>
public sealed record NoteDto {
    public required Guid Id { get; init; }
    public required string Title { get; init; }
    public string? Content { get; init; }
    public required Guid CategoryId { get; init; }
    public required string CategoryName { get; init; }  // denormalised from navigation
    public required Guid CreatedById { get; init; }
    public required DateTimeOffset CreatedAt { get; init; }
    public required DateTimeOffset UpdatedAt { get; init; }
    public required bool IsArchived { get; init; }
}

/// <summary>Payload for creating a new note.</summary>
public sealed record CreateNoteDto {
    public Guid? Id { get; init; }
    public required string Title { get; init; }
    public string? Content { get; init; }
    public required Guid CategoryId { get; init; }
}

/// <summary>Payload for updating a note via JSON Patch.</summary>
public sealed record UpdateNoteDto {
    public required Guid Id { get; init; }
    public required string Title { get; init; }
    public string? Content { get; init; }
}

/// <summary>Summary DTO for category list views — includes note count.</summary>
public sealed record CategorySummaryDto {
    public required Guid Id { get; init; }
    public required string Name { get; init; }
    public string? Color { get; init; }
    public required int NoteCount { get; init; }
    public required DateTimeOffset CreatedAt { get; init; }
}
```

### Endpoint Pattern with Query Parameter Filtering

```csharp
// File: src/Paso.Cap.Web/Endpoints/Notes.cs
namespace Paso.Cap.Endpoints;

/// <summary>Notes endpoints with optional category filtering.</summary>
public sealed class Notes : EndpointGroupBase {
    public override void Map(IEndpointRouteBuilder routeBuilder) {
        routeBuilder.MapGet("/", GetNotes).WithDefaultMetadata();
        routeBuilder.MapGet("/{id:guid}", GetNote).WithDefaultMetadata();
        routeBuilder.MapPost("/", CreateNote).WithDefaultMetadata().RequireAuthorization();
        routeBuilder.MapPatch("/{id:guid}", UpdateNote).WithDefaultMetadata().RequireAuthorization();
        routeBuilder.MapDelete("/{id:guid}", ArchiveNote).WithDefaultMetadata().RequireAuthorization();
    }

    /// <summary>Returns notes, optionally filtered by categoryId.</summary>
    private async Task<List<NoteDto>> GetNotes(
        [FromQuery] Guid? categoryId,
        [FromServices] NoteService service,
        CancellationToken cancellationToken = default) {
        if (categoryId is not null) {
            return await service.GetNotesByCategory(categoryId.Value, cancellationToken);
        }
        return await service.GetAllNotes(cancellationToken);
    }

    private async Task<NoteDto> GetNote(
        [FromRoute] Guid id,
        [FromServices] NoteService service,
        CancellationToken cancellationToken = default) {
        return await service.GetNoteById(id, cancellationToken);
    }

    private async Task<Created> CreateNote(
        [FromBody] CreateNoteDto request,
        [FromServices] NoteService service,
        ClaimsPrincipal principal,
        CancellationToken cancellationToken = default) {
        var userId = Guid.Parse(principal.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? throw new ArgumentException("User ID claim missing."));
        var id = request.Id ?? Guid.NewGuid();
        if (request.Id is null) request = request with { Id = id };
        await service.CreateNote(request, userId, cancellationToken);
        return TypedResults.Created($"{this.GetPath()}/{id}");
    }

    private async Task<NoContent> UpdateNote(
        [FromRoute] Guid id,
        [FromBody] JsonPatchDocument<UpdateNoteDto> request,
        [FromServices] NoteService service,
        CancellationToken cancellationToken = default) {
        // Build update command from patch document (same pattern as WeatherForecast)
        await service.UpdateNote(id, request, cancellationToken);
        return TypedResults.NoContent();
    }

    private async Task<NoContent> ArchiveNote(
        [FromRoute] Guid id,
        [FromServices] NoteService service,
        CancellationToken cancellationToken = default) {
        await service.ArchiveNote(id, cancellationToken);
        return TypedResults.NoContent();
    }
}
```

### DI Registration for Multi-Entity Feature

```csharp
// In DomainServiceExtensions.cs — inside AddDomain()
if (Features.Notes.IsEnabled) {
    services.AddScoped<NoteService>();
}
```

```csharp
// In Features.cs — add inside the Features static class
public static class Notes {
    [FeatureSwitchDefinition("Notes.IsEnabled")]
    public static bool IsEnabled => AppContext.TryGetSwitch("Notes.IsEnabled", out bool isEnabled) ? isEnabled : true;
}
```

### Implementation Checklist (Multi-Entity)

- [ ] Parent entity is `sealed` with `IAggregateRoot`, has `IReadOnlyList<Child>` navigation backed by private `List<T>`
- [ ] Child entity is `sealed` with `IAggregateRoot`, has FK property + navigation property for each FK
- [ ] `RowVersion` on every entity
- [ ] Separate `IEntityTypeConfiguration<T>` files for both parent and child
- [ ] `.HasOne().WithMany().HasForeignKey().OnDelete()` declared explicitly
- [ ] `DeleteBehavior.Cascade` for owned children, `DeleteBehavior.Restrict` for shared references
- [ ] Index on every FK column; composite index for common multi-column filters
- [ ] Compiled queries use `.Include()` before `.Select()`
- [ ] All read queries filter `!x.IsArchived` for soft-delete entities
- [ ] `DbSet<T>` added to `ApplicationDbContext` for every new entity
- [ ] Feature flag in `Features.cs`, service registration in `DomainServiceExtensions.cs`
- [ ] DTOs are `sealed record` with `IReadOnlyList<T>` for nested collections
- [ ] `[FromQuery]` parameters used for URL-level filtering (e.g. `?categoryId=...`)
- [ ] Write endpoints use `.RequireAuthorization()`
- [ ] XML docs on all public service methods and DTOs
- [ ] Migration `Down()` has proper rollback — reverses FK constraints before dropping tables
