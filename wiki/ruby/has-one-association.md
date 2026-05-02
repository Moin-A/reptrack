# has_one Association

**Summary:** How `has_one` is defined, how it processes arguments, and the full options list.

**Tags:** rails, activerecord, associations, has_one, reflection

**Last updated:** 2026-04-30

---

## Where it is defined

Two locations — they serve different purposes:

| Method | File | What it is |
|--------|------|------------|
| `def has_one` | `.bundle/ruby/3.1.0/gems/activerecord-7.2.3.1/lib/active_record/associations.rb:1468` | The DSL method you call in your model |
| `def self.build` | `.bundle/ruby/3.1.0/gems/activerecord-7.2.3.1/lib/active_record/associations/builder/association.rb:25` | Base builder — entry point called by `has_one` |
| `def self.create_reflection` | `.bundle/ruby/3.1.0/gems/activerecord-7.2.3.1/lib/active_record/associations/builder/association.rb:40` | Validates options, builds scope, creates Reflection object |
| `def self.build_scope` | `.bundle/ruby/3.1.0/gems/activerecord-7.2.3.1/lib/active_record/associations/builder/association.rb:53` | Wraps the lambda for correct execution context |
| `def self.define_extensions` (no-op) | `.bundle/ruby/3.1.0/gems/activerecord-7.2.3.1/lib/active_record/associations/builder/association.rb:73` | Empty fallback for singular associations |
| `def self.define_extensions` (real) | `.bundle/ruby/3.1.0/gems/activerecord-7.2.3.1/lib/active_record/associations/builder/collection_association.rb:22` | Used by `has_many` — handles extension blocks |

## Method signature

```ruby
def has_one(name, scope = nil, **options)
  reflection = Builder::HasOne.build(self, name, scope, options)
  Reflection.add_reflection self, name, reflection
end
```

Three distinct arguments:

- `name` — symbol, always first (e.g. `:profile`)
- `scope` — optional lambda, second positional argument
- `**options` — keyword arguments, captured as a plain hash

`**options` lets callers write `has_one :profile, dependent: :destroy` naturally without wrapping in `{}`. Ruby collects all keyword-style arguments into one hash automatically.

## How arguments are processed

**`Builder::HasOne.build`** delegates up to the base `Association` class (`build` is defined there, not in `HasOne`). Inside `build`, `create_reflection` is called:

```ruby
def self.create_reflection(model, name, scope, options, &block)
  validate_options(options)
  extension = define_extensions(model, name, &block)   # no-op for has_one
  scope = build_scope(scope)
  ActiveRecord::Reflection.create(macro, name, scope, options, model)
end
```

**`build_scope`** wraps the lambda so it runs in the right context:

```ruby
def self.build_scope(scope)
  if scope && scope.arity == 0
    proc { instance_exec(&scope) }
  else
    scope
  end
end
```

If your lambda takes no arguments (arity 0), it is wrapped so it executes with `instance_exec` against the record — giving it access to `self`. If it takes an argument (e.g. the owner record), it is passed as-is.

**`Reflection.create`** stores all association metadata (macro, name, scope, options, model) in a Reflection object. Rails reads this later to know how to query, join, and load the associated record.

## Class method lookup — why self matters

`build` is defined in `Association` (the base class). When you call `HasOne.build(...)`, `self` inside `build` is `HasOne`. So when `create_reflection` calls `self.define_extensions`, Ruby looks up the class method chain starting from `HasOne`:

```
HasOne  →  no define_extensions
  ↓
Association  →  FOUND (empty no-op)  ✓
```

For `has_many`, the chain is `HasMany → CollectionAssociation → Association`, and `CollectionAssociation` provides a real `define_extensions` that handles extension blocks. `has_one` gets the empty fallback because singular associations do not support extension blocks.

## Scope (lambda)

```ruby
has_one :profile, -> { where(active: true) }
has_one :latest_post, ->(blog) { where("created_at > ?", blog.enabled_at) }
```

The scope is a lambda (not a block) so it can be stored in the Reflection object and called later. A block cannot be stored directly.

## Options

| Option | What it does |
|--------|-------------|
| `:class_name` | Override inferred class name. `has_one :manager` assumes `Manager`; use `:class_name` if the real class is different |
| `:dependent` | What happens when the owner is destroyed — see table below |
| `:foreign_key` | Override the default foreign key column (default: `ownerclass_id`) |
| `:primary_key` | Override the default primary key (default: `id`) |
| `:as` | Polymorphic interface — `has_one :tag, as: :taggable` |
| `:through` | Query through a join model — `has_one :country, through: :address` |
| `:source` | Source association name for `:through` queries when it cannot be inferred |
| `:source_type` | Source association type for polymorphic `:through` queries |
| `:validate` | Validate the associated object when saving the parent (default: `false`) |
| `:autosave` | Always save/destroy the associated object when the parent saves |
| `:touch` | Touch `updated_at` on the associated object when the parent saves or is destroyed |
| `:inverse_of` | Name of the `belongs_to` on the other side — avoids extra queries |
| `:required` | Validates presence of the association |
| `:strict_loading` | Enforce strict loading every time the association is accessed |
| `:query_constraints` | Composite foreign key — list of columns to use for the query |

### :dependent options

| Value | Behaviour |
|-------|-----------|
| `nil` (default) | Do nothing |
| `:destroy` | Call `.destroy` on the associated record (runs callbacks) |
| `:destroy_async` | Destroy in a background job |
| `:delete` | Delete directly from the database (skips callbacks) |
| `:nullify` | Set the foreign key to `NULL` (skips callbacks) |
| `:restrict_with_exception` | Raise `ActiveRecord::DeleteRestrictionError` if associated record exists |
| `:restrict_with_error` | Add an error to the owner if an associated record exists |

## See Also

- [[rails-core-ext-and-validations]]
- [[super-collector-pattern]]
