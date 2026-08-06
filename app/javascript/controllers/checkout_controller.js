import { Controller } from "@hotwired/stimulus"

// Phase 2 of Razorpay's flow. The order was created server-side (Phase 1) and
// arrives here as values; this opens Razorpay's hosted modal and relays the
// signed result to Phase 3 (capture) at POST /billing/charges.
//
// Card details are typed into Razorpay's iframe, never into this page — that is
// what keeps the app out of PCI-DSS scope.
export default class extends Controller {
  static targets = ["result"]
  static values = {
    key:      String,
    orderId:  String,
    amount:   Number,
    currency: String,
    email:    String,
    captureUrl: String
  }

  pay() {
    const rzp = new Razorpay({
      key:         this.keyValue,
      order_id:    this.orderIdValue,
      amount:      this.amountValue,
      currency:    this.currencyValue,
      name:        "Reptrack",
      description: "Test capture",
      prefill:     { email: this.emailValue },
      handler:     (response) => this.#capture(response),
      modal:       { ondismiss: () => this.#render("<p>Payment cancelled.</p>") }
    })

    // Razorpay reports a failed attempt here rather than through `handler`.
    rzp.on("payment.failed", (event) =>
      this.#render(`<h2 class="error">Payment failed</h2><pre>${this.#json(event.error)}</pre>`)
    )

    rzp.open()
  }

  // Relay Razorpay's signed result to our server, which verifies the HMAC and
  // only then captures. The signature matters because this payload travelled
  // through the browser and cannot be trusted on its own.
  async #capture(response) {
    this.#render("<p>Capturing…</p>")

    try {
      const res = await fetch(this.captureUrlValue, {
        method:  "POST",
        headers: { "Content-Type": "application/json", ...this.#csrfHeader() },
        body:    JSON.stringify({
          razorpay_payment_id: response.razorpay_payment_id,
          razorpay_order_id:   response.razorpay_order_id,
          razorpay_signature:  response.razorpay_signature
        })
      })
      const body = await res.json()

      this.#render(
        (res.ok ? "<h2>Captured</h2>" : '<h2 class="error">Capture failed</h2>') +
        `<pre>${this.#json(body)}</pre>`
      )
    } catch (error) {
      this.#render(`<h2 class="error">Capture request failed</h2><pre>${error}</pre>`)
    }
  }

  // Turbo only attaches CSRF to its own requests, not to a hand-written fetch.
  // Missing tag returns {} rather than throwing, so a capture still reaches the
  // server and fails visibly instead of dying silently in the console.
  #csrfHeader() {
    const tag = document.querySelector('meta[name="csrf-token"]')
    return tag ? { "X-CSRF-Token": tag.content } : {}
  }

  #json(value) {
    return JSON.stringify(value, null, 2)
  }

  #render(html) {
    this.resultTarget.innerHTML = html
  }
}
