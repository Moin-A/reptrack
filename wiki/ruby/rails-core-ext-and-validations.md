# Rails Core Extensions & Validations

## Where are Rails validation methods defined?

Each validator has its own file inside `activemodel`:

| Method | File |
|---|---|
| `validates_presence_of` | `activemodel/lib/active_model/validations/presence.rb` |
| `validates_absence_of` | `activemodel/lib/active_model/validations/absence.rb` |
| `validates_length_of` | `activemodel/lib/active_model/validations/length.rb` |
| `validates_format_of` | `activemodel/lib/active_model/validations/format.rb` |
| `validates_numericality_of` | `activemodel/lib/active_model/validations/numericality.rb` |
| `validates_inclusion_of` | `activemodel/lib/active_model/validations/inclusion.rb` |
| `validates_exclusion_of` | `activemodel/lib/active_model/validations/exclusion.rb` |
| `validates_confirmation_of` | `activemodel/lib/active_model/validations/confirmation.rb` |
| `validates_acceptance_of` | `activemodel/lib/active_model/validations/acceptance.rb` |
| `validates_uniqueness_of` | `activerecord/lib/active_record/validations/uniqueness.rb` |

`validates_uniqueness_of` lives in `activerecord` (not `activemodel`) because it needs a database.

The unified `validates` method is in `activemodel/lib/active_model/validations.rb`.

## validates vs validates_presence_of

Always use `validates :name, presence: true` — the unified Rails 3+ API:

```ruby
# old Rails 2 style — avoid
validates_presence_of :name
validates_length_of :name, minimum: 3

# new unified style — use this
validates :name, presence: true, length: { minimum: 3 }
```

The old `validates_presence_of` style still works but is legacy — kept only for backwards compatibility.

## What is extract_options!

`extract_options!` is a method on `Array`, defined in:
`.bundle/ruby/3.1.0/gems/activesupport-7.2.3.1/lib/active_support/core_ext/array/extract_options.rb:24`

It pops the last element off an array if it is a plain `Hash`, otherwise returns `{}`.

```ruby
args = [:name, :email, { presence: true }]
opts = args.extract_options!
# opts => { presence: true }
# args => [:name, :email]
```

This is how `validates :name, :email, presence: true` splits attribute names from options.

It checks `last.is_a?(Hash) && last.extractable_options?` — the double check exists because `is_a?(Hash)` returns true for Hash subclasses too, while `extractable_options?` uses `instance_of?(Hash)` which only matches plain Hash. Subclasses can opt in by overriding `extractable_options?` to return `true`.

## How validates processes arguments internally

Defined in `.bundle/ruby/3.1.0/gems/activemodel-7.2.3.1/lib/active_model/validations/validates.rb:106`.

```ruby
validates :name, :description, presence: true, uniqueness: true
```

**Step 1 — separate fields from options**

`validates(*attributes)` collects everything into one array:
`[:name, :description, { presence: true, uniqueness: true }]`

`extract_options!` pops the hash and `.dup` copies it so mutations inside the method don't affect the caller's original object:

```ruby
defaults = attributes.extract_options!.dup
# attributes => [:name, :description]
# defaults   => { presence: true, uniqueness: true }
```

**Step 2 — separate validator keys from framework options**

`slice!` splits `defaults` into two parts. Framework keys (`:on`, `:if`, `:unless`, `:strict`) stay in `defaults`. Validator keys move into `validations`:

```ruby
validations = defaults.slice!(*_validates_default_keys)
# defaults    => {}                                   (framework options like on:, if:)
# validations => { presence: true, uniqueness: true } (what to validate)
```

**Step 3 — run each validator**

Loops over `validations`, converts each key to a class name, and calls that validator:

```ruby
validations.each do |key, options|
  key = "#{key.to_s.camelize}Validator"   # :presence => "PresenceValidator"
  validator = const_get(key)
  validates_with(validator, defaults.merge(_parse_validates_options(options)))
end
```

So `presence: true` and `uniqueness: true` each trigger a separate validator class, both applied to all listed attributes. Multiple validations in one line work because of this loop — there is only ever one hash, Ruby merges all keyword arguments into it automatically.

## Open Classes & Monkeypatching

Ruby allows any class to be reopened at any time and new methods added. This is called **open classes**.

```ruby
class Array
  def printHello
    puts "Hello"
  end
end

[].printHello  # => Hello
```

Rails uses this to add methods to Ruby's built-in classes (`Array`, `Hash`, `String`, etc.) via `core_ext`. Since there is only one `Array` class in the Ruby runtime, any method added to it is available on every array everywhere — including ones you create yourself.

## How core_ext loads at boot

The chain starting from your app:

1. `config/application.rb` → `require "rails/all"`
2. `rails/all` → requires every Rails component (`activerecord`, `activesupport`, etc.)
3. Each component → requires its needed `core_ext` files
4. Each `core_ext` file → reopens a built-in class and adds methods

Example — `activesupport/lib/active_support/core_ext/hash.rb` is just a loader:

```ruby
require "active_support/core_ext/hash/deep_merge"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/hash/slice"
# ...etc
```

Each of those files reopens `class Hash` and adds methods. By the time your app code runs, all classes are already patched.

## The danger of open classes

There is no protection. If you define `class Array; def slice; end; end` anywhere in the load path, you overwrite the original. Rails mitigates this by using unusual method names (`extract_options!`, `deep_merge`, `with_indifferent_access`) to avoid collisions — but it is an honor system, not a technical guarantee.

**Ruby's official solution: Refinements**

```ruby
module MyPatch
  refine Array do
    def slice
      "my version"
    end
  end
end

# patch is inactive everywhere by default
[1,2,3].slice(0,1)  # => [1, 2]  original

using MyPatch  # activate only in this file

[1,2,3].slice(0,1)  # => "my version"
```

Refinements scope the patch to files that explicitly opt in with `using`. Rails does not use refinements (too late to change), but new code should prefer them.

## Pattern names

| Pattern | What it means |
|---|---|
| **Monkeypatching** | Reopening an existing class and adding/changing methods |
| **Open Classes** | Ruby language feature that allows any class to be reopened |
| **Mixin / Module Include** | Putting methods in a module and including it into a class |
| **Namespace** | Wrapping inside modules to avoid name collisions |
| **Core Extensions** | Rails' term for monkeypatching Ruby built-ins via open classes |
