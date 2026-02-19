export default {
  mounted() {
    this.steps = JSON.parse(this.el.dataset.steps);
    this.currentStep = 0;
    this.overlay = null;
    this.tooltip = null;
    this.originalStyles = new Map();

    this._onKeyDown = (e) => {
      if (e.key === "Escape") this.dismiss();
    };

    this._onResize = () => {
      if (this.overlay) this.showStep(this.currentStep);
    };

    document.addEventListener("keydown", this._onKeyDown);
    window.addEventListener("resize", this._onResize);

    // Delay to let LiveView settle
    this._timer = setTimeout(() => this.showStep(0), 500);
  },

  showStep(index) {
    this.cleanup();

    // Skip missing targets
    while (index < this.steps.length) {
      const step = this.steps[index];
      const target = document.querySelector(step.target);
      if (target) {
        this.currentStep = index;
        this.render(target, step, index);
        return;
      }
      index++;
    }

    // No more valid steps
    this.dismiss();
  },

  render(target, step, index) {
    // Overlay
    this.overlay = document.createElement("div");
    Object.assign(this.overlay.style, {
      position: "fixed",
      inset: "0",
      zIndex: "1000",
      background: "transparent",
    });
    this.overlay.addEventListener("click", (e) => {
      if (e.target === this.overlay) this.dismiss();
    });
    document.body.appendChild(this.overlay);

    // Spotlight target
    const orig = {
      position: target.style.position,
      zIndex: target.style.zIndex,
      boxShadow: target.style.boxShadow,
      borderRadius: target.style.borderRadius,
    };
    this.originalStyles.set(target, orig);
    const computed = getComputedStyle(target);
    if (computed.position === "static") target.style.position = "relative";
    target.style.zIndex = "1001";
    target.style.boxShadow = "0 0 0 9999px rgba(0,0,0,0.5)";
    target.style.borderRadius = target.style.borderRadius || "0.375rem";

    // Tooltip
    this.tooltip = document.createElement("div");
    this.tooltip.style.zIndex = "1002";
    this.tooltip.style.position = "absolute";
    this.tooltip.className = "card bg-base-100 shadow-xl border border-base-300 w-80";

    const isLast = index === this.steps.length - 1;
    this.tooltip.innerHTML = `
      <div class="card-body p-4 gap-3">
        <div class="flex items-center justify-between">
          <span class="badge badge-sm badge-ghost">${index + 1} / ${this.steps.length}</span>
        </div>
        <p class="text-sm">${step.message}</p>
        <div class="card-actions justify-end">
          <button data-action="skip" class="btn btn-ghost btn-sm">Skip</button>
          <button data-action="next" class="btn btn-primary btn-sm">${isLast ? "Got it" : "Next"}</button>
        </div>
      </div>
    `;

    this.tooltip
      .querySelector('[data-action="skip"]')
      .addEventListener("click", () => this.dismiss());
    this.tooltip
      .querySelector('[data-action="next"]')
      .addEventListener("click", () => {
        if (isLast) {
          this.dismiss();
        } else {
          this.showStep(index + 1);
        }
      });

    document.body.appendChild(this.tooltip);
    this.positionTooltip(target, step.position || "bottom");
  },

  positionTooltip(target, position) {
    const rect = target.getBoundingClientRect();
    const tipRect = this.tooltip.getBoundingClientRect();
    const gap = 12;

    let top, left;

    if (position === "bottom") {
      top = rect.bottom + gap + window.scrollY;
      left = rect.left + rect.width / 2 - tipRect.width / 2 + window.scrollX;
    } else {
      top = rect.top - tipRect.height - gap + window.scrollY;
      left = rect.left + rect.width / 2 - tipRect.width / 2 + window.scrollX;
    }

    // Flip if overflowing viewport
    if (
      position === "bottom" &&
      rect.bottom + gap + tipRect.height > window.innerHeight
    ) {
      top = rect.top - tipRect.height - gap + window.scrollY;
    } else if (position === "top" && rect.top - gap - tipRect.height < 0) {
      top = rect.bottom + gap + window.scrollY;
    }

    // Clamp horizontally
    const maxLeft = window.innerWidth - tipRect.width - 8 + window.scrollX;
    left = Math.max(8 + window.scrollX, Math.min(left, maxLeft));

    this.tooltip.style.top = `${top}px`;
    this.tooltip.style.left = `${left}px`;

    // Scroll target into view if needed
    target.scrollIntoView({ behavior: "smooth", block: "nearest" });
  },

  cleanup() {
    if (this.overlay) {
      this.overlay.remove();
      this.overlay = null;
    }
    if (this.tooltip) {
      this.tooltip.remove();
      this.tooltip = null;
    }
    for (const [el, orig] of this.originalStyles) {
      el.style.position = orig.position;
      el.style.zIndex = orig.zIndex;
      el.style.boxShadow = orig.boxShadow;
      el.style.borderRadius = orig.borderRadius;
    }
    this.originalStyles.clear();
  },

  dismiss() {
    this.cleanup();
    this.pushEvent("dismiss_tutorial", { id: this.el.id });
  },

  destroyed() {
    clearTimeout(this._timer);
    document.removeEventListener("keydown", this._onKeyDown);
    window.removeEventListener("resize", this._onResize);
    this.cleanup();
  },
};
