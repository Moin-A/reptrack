class AppConfiguration < Reptrack::Configuration
    preference :slot_credit_packages, :array, default: [
      {
        key: "starter",
        name: "Starter",
        sessions: 1,
        amount: 1,
        popular: false,
        theme: "emerald",
        description: "Book a single session now.<br>You can always buy more later!"
      }]
end