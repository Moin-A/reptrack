import { Controller } from "@hotwired/stimulus"

// Drives the pricing page:
//  - Monthly/Annual toggle (swaps the displayed price + suffix)
//  - "Get Started" → mint a Razorpay order for the chosen tier+period
//    (POST createOrderUrl), then open the hosted modal
//  - relay the signed result to captureUrl (Phase 3)
//
// Card details are typed into Razorpay's iframe, never this page — that keeps
// the app out of PCI-DSS scope.
export default class extends Controller {
  static targets = ["price", "switch", "knob", "monthlyLabel", "annualLabel", "result"]
  static values = { key: String, createOrderUrl: String, captureUrl: String }

  connect() {
    this.period = "monthly"
  }

  // ── Monthly / Annual toggle ────────────────────────────────────────────
  toggle() {
    this.period = this.period === "monthly" ? "annual" : "monthly"
    const annual = this.period === "annual"

    this.switchTarget.classList.toggle("bg-slate-900", annual)
    this.switchTarget.classList.toggle("bg-slate-300", !annual)
    this.knobTarget.classList.toggle("translate-x-5", annual)
    this.knobTarget.classList.toggle("translate-x-0.5", !annual)
    this.monthlyLabelTarget.classList.toggle("text-slate-900", !annual)
    this.monthlyLabelTarget.classList.toggle("text-slate-500", annual)
    this.annualLabelTarget.classList.toggle("text-slate-900", annual)
    this.annualLabelTarget.classList.toggle("text-slate-500", !annual)

    this.priceTargets.forEach((el) => {
      const paise = annual ? el.dataset.annual : el.dataset.monthly
      el.querySelector("[data-amount]").textContent = this.#format(paise)
      el.querySelector("[data-suffix]").textContent = annual ? "/ year" : "/ month"
    })
  }

  // ── Get Started → order → modal ────────────────────────────────────────
  async pay(event) {
    const tier = event.currentTarget.dataset.tier
    this.#status("Starting checkout…")

    try {
      const res = await fetch(this.createOrderUrlValue, {
        method: "POST",
        headers: { "Content-Type": "application/json", ...this.#csrf() },
        body: JSON.stringify({ tier, period: this.period })
      })
      const order = await res.json()
      if (!res.ok) return this.#status(`Could not start checkout: ${order.error ?? "error"}`, true)

      this.#openRazorpay(order)
    } catch (error) {
      this.#status(`Checkout request failed: ${error}`, true)
    }
  }

  #openRazorpay(order) {
    this.#status("")
    const rzp = new Razorpay({
      key:         order.key || this.keyValue,
      order_id:    order.order_id,
      amount:      order.amount,
      currency:    "INR",
      name:        "RepTrack",
      description: "Subscription",
      handler:     (response) => this.#capture(response),
      modal:       { ondismiss: () => this.#status("Payment cancelled.") }
    })
    rzp.on("payment.failed", (event) => this.#status(`Payment failed: ${event.error?.description ?? ""}`, true))
    rzp.open()
  }

  // Relay the signed result; the server verifies the HMAC before capturing.
  async #capture(response) {
    this.#status("Capturing…")
    try {
      const res = await fetch(this.captureUrlValue, {
        method: "POST",
        headers: { "Content-Type": "application/json", ...this.#csrf() },
        body: JSON.stringify({
          razorpay_payment_id: response.razorpay_payment_id,
          razorpay_order_id:   response.razorpay_order_id,
          razorpay_signature:  response.razorpay_signature
        })
      })
      const body = await res.json()
      this.#status(res.ok ? "Payment successful — you're all set!" : `Capture failed: ${body.error ?? ""}`, !res.ok)
    } catch (error) {
      this.#status(`Capture request failed: ${error}`, true)
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────
  #format(paise) {
    return "₹" + (Number(paise) / 100).toLocaleString("en-IN", { maximumFractionDigits: 0 })
  }

  #csrf() {
    const tag = document.querySelector('meta[name="csrf-token"]')
    return tag ? { "X-CSRF-Token": tag.content } : {}
  }

  #status(message, isError = false) {
    this.resultTarget.textContent = message
    this.resultTarget.className = `mx-auto max-w-4xl px-4 text-center text-sm ${isError ? "text-red-600" : "text-slate-600"}`
  }
}
