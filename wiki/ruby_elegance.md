# Ruby Elegance

## `*` — Splat (arrays)

Unpacks/collects arrays:

```ruby
# unpack array into arguments
def add(a, b)
  a + b
end
add(*[1, 2])  # => 3

# collect multiple args into array
def sum(*nums)
  nums.sum
end
sum(1, 2, 3)  # nums = [1, 2, 3]
```

## `**` — Double Splat (hashes)

Unpacks/collects hashes:

```ruby
# unpack hash into keyword arguments
def greet(name:, age:)
  "#{name}, #{age}"
end
greet(**{name: "Moin", age: 25})  # => "Moin, 25"

# collect multiple keyword args into hash
def log(**opts)
  puts opts
end
log(level: :info, msg: "ok")  # opts = {level: :info, msg: "ok"}
```

## Quick mental model

| Operator | Works with | Think of it as |
|----------|------------|----------------|
| `*`      | Arrays     | "spread/collect list" |
| `**`     | Hashes     | "spread/collect key-values" |

Very common in Rails — you'll see `**options` a lot in method signatures like in ActiveRecord, Devise, etc.
