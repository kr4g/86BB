import { CATALOG } from "@shared/data/catalog.js";

const ALL_IDS = CATALOG.map((item) => item.id);

export class FoodQueue {
  private queue: string[] = [];

  constructor() {
    this.refill();
  }

  private refill() {
    this.queue.push(...[...ALL_IDS].sort(() => Math.random() - 0.5));
  }

  next(excludeSet: Set<string>): string {
    for (let attempt = 0; attempt < 3; attempt++) {
      if (this.queue.length < ALL_IDS.length) this.refill();
      const idx = this.queue.findIndex((k) => !excludeSet.has(k));
      if (idx !== -1) return this.queue.splice(idx, 1)[0];
      this.refill();
    }
    return this.queue.shift()!;
  }
}
