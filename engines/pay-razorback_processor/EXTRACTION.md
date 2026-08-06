# Extracting `pay-razorback_processor` into a standalone gem

This engine currently lives in-repo and is tested by the **host app's** RSpec
suite. When you move it to its own repository, the one real task is standing up
the engine's own test harness (a dummy Rails app), because the specs depend on
host-provided pieces. This checklist captures exactly what to move and what to
recreate.

## 1. Move the Gemfile reference to a real source

Host `Gemfile`:

```ruby
# from (in-repo path gem)
gem "pay-razorback_processor", path: "engines/pay-razorback_processor"
# to (extracted)
gem "pay-razorback_processor", git: "git@github.com:ORG/pay-razorback_processor.git"
# or, once published:
gem "pay-razorback_processor", "~> 0.1"
```

Nothing else in the host needs to change — routes still `mount
Pay::RazorbackProcessor::Engine => "/"`, and the processor still resolves via
`set_payment_processor(:razorback_processor)`.

## 2. Build a dummy app for the engine's specs

The specs need a booted Rails app with a database and — critically — a `User`
model. `User` is **host code**, not part of this gem, so the dummy app must
supply a stand-in.

```
engines/pay-razorback_processor/
└── spec/
    ├── dummy/                         # minimal Rails app
    │   ├── app/models/user.rb         #   class User < ApplicationRecord; pay_customer; end
    │   ├── app/models/application_record.rb
    │   ├── app/channels/application_cable/{connection,channel}.rb
    │   ├── config/environment.rb, application.rb, database.yml, cable.yml (adapter: test)
    │   └── db/migrate/                 #   pay tables (create_pay_tables + STI cols) + a users table
    ├── rails_helper.rb                # require dummy app's environment
    ├── spec_helper.rb
    ├── factories/user.rb              # factory :user (for the dummy User)
    ├── support/payment_processor_helpers.rb
    └── fixtures/files/payment_processor/...
```

The fastest way to generate the scaffolding is `rails plugin new
pay-razorback_processor --mountable --dummy-path=spec/dummy -T` in a scratch
dir, then copy this engine's `app/`, `lib/`, and `config/routes.rb` over it.

## 3. Files to move from the host into the engine's `spec/`

Specs (all of these are engine-owned; move verbatim):

- `spec/models/pay/razorback_processor/customer_spec.rb`
- `spec/models/pay/razorback_processor/charge_spec.rb`
- `spec/models/pay/razorback_processor/webhooks/payment_captured_spec.rb`
- `spec/models/pay/razorback_processor/webhooks/payment_captured_backstop_spec.rb`
- `spec/models/pay/razorback_processor/webhooks/delegation_spec.rb`
- `spec/requests/webhooks/razorpay_spec.rb`
- `spec/requests/billing_spec.rb`

Support + fixtures:

- `spec/support/payment_processor_helpers.rb`  (defines `show_response`, `stub_api_response`)
- `spec/fixtures/files/payment_processor/customer/{success,authorized,failure}.json`
- `spec/fixtures/files/payment_processor/webhook/payment_captured.json`

Recreate in the dummy harness (do NOT copy the host versions blindly):

- `spec/factories/user.rb` — must build the **dummy** `User`, not the host one.
- `rails_helper.rb` — replicate the two things the host's version does for these specs:
  1. `Rails.root.glob("spec/support/**/*.rb").each { |f| require f }`
  2. `config.include PaymentProcessorHelpers`
  and the usual FactoryBot/`fixture_paths` setup.

## 4. Do NOT move (host-only)

- `public/cable_test.html` — throwaway manual test page; delete or keep in host.
- `config/cable.yml` redis adapter change, `Gemfile` redis gem — host infra.
- The Pay install migrations in host `db/migrate` — the gem ships its own via a
  generator/`install` task instead; the dummy app gets its own copies.

## 5. CI

Once specs live in the engine, they stop running under the host's
`bundle exec rspec`. Add a second CI job:

```
cd engines/pay-razorback_processor && bundle install && bundle exec rspec
```

(or, after extraction, the gem's own repo CI).

## 6. Gem metadata to finish

- Fill in `pay-razorback_processor.gemspec` authors/email/homepage/metadata.
- Add `MIT-LICENSE` and `README.md` (the gemspec's `files` already globs them).
- Consider a `Pay::RazorbackProcessor::InstallGenerator` to copy the pay
  migrations into the host, mirroring how Pay itself installs.
```
