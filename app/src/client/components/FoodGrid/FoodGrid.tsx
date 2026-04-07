import { useState, useEffect, useRef, useCallback } from "react";
import { FoodSlot } from "../FoodSlot/index.js";
import { FoodQueue } from "../../lib/FoodQueue.js";
import { GRID_SLOTS } from "../../lib/constants.js";
import { createSlot, tickSlot, type Slot } from "../../lib/slotManager.js";
import styles from "./FoodGrid.module.css";

interface FoodGridProps {
  onSelect: (foodId: string) => void;
}

export function FoodGrid({ onSelect }: FoodGridProps) {
  const [renderSlots, setRenderSlots] = useState<Slot[]>([]);
  const slotsRef = useRef<Slot[]>([]);
  const animRef = useRef<number | null>(null);
  const lastTimeRef = useRef<number | null>(null);
  const queueRef = useRef(new FoodQueue());

  useEffect(() => {
    const queue = queueRef.current;
    const used = new Set<string>();
    const slots: Slot[] = [];
    for (let i = 0; i < GRID_SLOTS; i++) {
      const key = queue.next(used);
      used.add(key);
      const slot = createSlot(i, key);
      slot.timer = Math.random() * slot.fadeDuration;
      slots.push(slot);
    }
    slotsRef.current = slots;
    setRenderSlots(slots.map((s) => ({ ...s })));
  }, []);

  useEffect(() => {
    let frameCount = 0;
    const tick = (now: number) => {
      if (lastTimeRef.current === null) {
        lastTimeRef.current = now;
        animRef.current = requestAnimationFrame(tick);
        return;
      }
      const dt = Math.min(now - lastTimeRef.current, 100);
      lastTimeRef.current = now;
      const slots = slotsRef.current;
      const queue = queueRef.current;

      for (const slot of slots) {
        tickSlot(slot, dt, queue, slots);
      }

      frameCount++;
      if (frameCount % 2 === 0) {
        setRenderSlots(slots.map((s) => ({ ...s })));
      }
      animRef.current = requestAnimationFrame(tick);
    };

    animRef.current = requestAnimationFrame(tick);
    return () => {
      if (animRef.current) cancelAnimationFrame(animRef.current);
    };
  }, []);

  const handleTap = useCallback(
    (idx: number) => {
      const slot = slotsRef.current[idx];
      if (!slot || slot.currentOpacity < 0.15 || slot.selected) return;
      slot.selected = true;
      slot.selectedTimer = 0;
      onSelect(slot.foodId);
    },
    [onSelect],
  );

  return (
    <div className={styles.grid}>
      {renderSlots.map((slot, idx) => (
        <FoodSlot key={idx} slot={slot} onTap={() => handleTap(idx)} />
      ))}
    </div>
  );
}
