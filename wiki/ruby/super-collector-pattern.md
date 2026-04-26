# Super Collector Pattern

**Summary:** A Ruby inheritance pattern where each class contributes its own values and `super` accumulates them across the entire ancestor chain.

**Tags:** ruby, inheritance, design-patterns, modules, metaprogramming

**Last updated:** 2026-04-25

---

## Overview

When a method calls `super() + own_values`, each class in the inheritance chain contributes its own slice, and `super` assembles the full picture walking upward. No class needs to know about its ancestors or descendants.

```ruby
def some_collection
  super() + my_own_values
end
```

Walking the chain:

```
ChildModel.some_collection
  → super() → ParentModel.some_collection
                → super() → BaseClass.some_collection
                              → []              # base case
              ← [] + [:a, :b]  = [:a, :b]
  ← [:a, :b] + [:c] = [:a, :b, :c]
```

---

## How It Works in Practice (Preferable example)

In `PreferableClassMethods`, a base `defined_preferences` returns `[]`. When `preference(:name)` is called on a class, `define_singleton_method` puts a new `defined_preferences` directly on that class's singleton — closer in the lookup chain than the base method, so it wins. Each override calls `super()` to collect from above.

```ruby
# Base case — from extend PreferableClassMethods
def defined_preferences
  []
end

# After ParentModel.preference(:theme)
define_singleton_method :defined_preferences do
  super() + [:theme]   # [] + [:theme] = [:theme]
end

# After ChildModel.preference(:notifications)
define_singleton_method :defined_preferences do
  super() + [:notifications]   # [:theme] + [:notifications] = [:theme, :notifications]
end
```

Key points:
- `define_singleton_method` puts the method on the class's **own singleton** — highest priority in lookup
- The base method from `extend` stays in the chain untouched, serving as the `[]` base case
- `super` skips the current method and finds the **next match** up the chain — proving nothing is ever truly overwritten

---

## Real-Life Usecases

### 1. Permissions / Abilities
```ruby
class User
  def abilities
    super + [:read_posts, :comment]
  end
end

class AdminUser < User
  def abilities
    super + [:delete_posts, :ban_users]
  end
end

AdminUser.new.abilities
# => [:read_posts, :comment, :delete_posts, :ban_users]
```

### 2. Form Validations (STI models)
```ruby
class Vehicle
  def required_fields
    super + [:make, :model, :year]
  end
end

class ElectricVehicle < Vehicle
  def required_fields
    super + [:battery_capacity, :range]
  end
end
```

### 3. API Response Serialization
```ruby
class BaseSerializer
  def fields
    super + [:id, :created_at]
  end
end

class UserSerializer < BaseSerializer
  def fields
    super + [:name, :email]
  end
end
```

### 4. Feature Flags per Plan Tier
```ruby
class BasicPlan
  def features
    super + [:dashboard, :reports]
  end
end

class ProPlan < BasicPlan
  def features
    super + [:api_access, :exports]
  end
end
```

### 5. Search Index Fields
```ruby
class BaseDocument
  def indexed_fields
    super + [:id, :created_at]
  end
end

class ProductDocument < BaseDocument
  def indexed_fields
    super + [:title, :price, :category]
  end
end
```

---

## Key Concepts

| Concept | Explanation |
|---------|-------------|
| `define_singleton_method` | Puts method directly on a class's own singleton — highest priority in lookup chain |
| `super()` | Skips current method, finds next match up the chain |
| Base case | Topmost ancestor returns `[]` so the first `super()` has something to return |
| Deduplication | If a module is already in the ancestor chain, Ruby skips reinserting it — preventing double collection |
| Nothing is overwritten | Old method stays in chain untouched — `super` proves this by still being able to call it |

---

## See Also
- [[bash/bash-commands]]
