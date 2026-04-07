import { useRef } from "react";
import { SpriteCanvas, type SpriteCanvasHandle } from "../SpriteCanvas/SpriteCanvas.js";
import { PIXEL_SIZE } from "../../lib/constants.js";
import type { Slot } from "../../lib/slotManager.js";
import styles from "./FoodSlot.module.css";

interface FoodSlotProps {
  slot: Slot;
  onTap: () => void;
}

export function FoodSlot({ slot, onTap }: FoodSlotProps) {
  const spriteRef = useRef<SpriteCanvasHandle>(null);
  const highlight = slot.selected && slot.selectedTimer < 300;
  const interactable = slot.currentOpacity > 0.15 && !slot.selected;

  return (
    <div
      className={styles.slot}
      onClick={interactable ? onTap : undefined}
      style={{
        cursor: interactable ? "pointer" : "default",
        opacity: slot.currentOpacity,
        background: highlight ? "rgba(255,255,255,0.12)" : "transparent",
        borderColor: highlight ? "rgba(255,255,255,0.25)" : "transparent",
      }}
    >
      <div style={{ transform: highlight ? "scale(1.35)" : undefined, transition: "transform 0.1s" }}>
        <SpriteCanvas ref={spriteRef} pixels={slot.food.pixels} scale={PIXEL_SIZE} />
      </div>
      <span className={styles.label}>{slot.food.name}</span>
    </div>
  );
}
