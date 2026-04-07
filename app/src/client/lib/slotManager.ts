import type { FoodItem } from "@shared/types.js";
import { CATALOG } from "@shared/data/catalog.js";
import { FoodQueue } from "./FoodQueue.js";

export type SlotPhase = "fadingIn" | "holding" | "fadingOut" | "waiting";

export interface Slot {
  index: number;
  foodId: string;
  food: FoodItem;
  targetOpacity: number;
  currentOpacity: number;
  scale: number;
  phase: SlotPhase;
  timer: number;
  fadeDuration: number;
  holdDuration: number;
  selected: boolean;
  selectedTimer: number;
}

const FOOD_MAP = new Map(CATALOG.map((f) => [f.id, f]));

export function createSlot(index: number, foodId: string): Slot {
  const food = FOOD_MAP.get(foodId)!;
  return {
    index,
    foodId,
    food,
    targetOpacity: 1.0,
    currentOpacity: 0,
    scale: 1.0,
    phase: "fadingIn",
    timer: 0,
    fadeDuration: 2000 + Math.random() * 2500,
    holdDuration: 4000 + Math.random() * 4000,
    selected: false,
    selectedTimer: 0,
  };
}

function smoothstep(p: number): number {
  return p * p * (3 - 2 * p);
}

function replaceSlotFood(
  slot: Slot,
  queue: FoodQueue,
  allSlots: Slot[],
): void {
  const usedKeys = new Set(
    allSlots.filter((_, j) => j !== slot.index).map((s) => s.foodId),
  );
  const newId = queue.next(usedKeys);
  const food = FOOD_MAP.get(newId)!;

  slot.foodId = newId;
  slot.food = food;
  slot.targetOpacity = 1.0;
  slot.scale = 1.0;
  slot.currentOpacity = 0;
  slot.timer = 0;
  slot.phase = Math.random() < 0.7 ? "fadingIn" : "waiting";
  slot.fadeDuration = slot.phase === "fadingIn"
    ? 1500 + Math.random() * 2000
    : 1500 + Math.random() * 3000;
  slot.holdDuration = 4000 + Math.random() * 4000;
}

export function tickSlot(slot: Slot, dt: number, queue: FoodQueue, allSlots: Slot[]): void {
  slot.timer += dt;

  if (slot.selected) {
    slot.selectedTimer += dt;
    if (slot.selectedTimer < 300) {
      slot.currentOpacity = slot.targetOpacity * 1.2;
    } else {
      slot.currentOpacity = 0;
      slot.selected = false;
      slot.selectedTimer = 0;
      replaceSlotFood(slot, queue, allSlots);
    }
    return;
  }

  if (slot.phase === "fadingIn") {
    const p = Math.min(slot.timer / slot.fadeDuration, 1);
    slot.currentOpacity = smoothstep(p) * slot.targetOpacity;
    if (p >= 1) {
      slot.phase = "holding";
      slot.timer = 0;
    }
  } else if (slot.phase === "holding") {
    slot.currentOpacity = slot.targetOpacity;
    if (slot.timer >= slot.holdDuration) {
      slot.phase = "fadingOut";
      slot.timer = 0;
      slot.fadeDuration = 1500 + Math.random() * 2000;
    }
  } else if (slot.phase === "fadingOut") {
    const p = Math.min(slot.timer / slot.fadeDuration, 1);
    slot.currentOpacity = slot.targetOpacity * (1 - smoothstep(p));
    if (p >= 1) {
      replaceSlotFood(slot, queue, allSlots);
    }
  } else if (slot.phase === "waiting") {
    if (slot.timer >= slot.fadeDuration) {
      slot.phase = "fadingIn";
      slot.timer = 0;
      slot.fadeDuration = 2000 + Math.random() * 2500;
      slot.holdDuration = 4000 + Math.random() * 4000;
    }
  }
}
