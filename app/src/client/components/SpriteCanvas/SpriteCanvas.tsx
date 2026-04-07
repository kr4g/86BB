import { useRef, useEffect, useImperativeHandle, forwardRef } from "react";
import { COLOR_MAP } from "@shared/data/sprites.js";

interface SpriteCanvasProps {
  pixels: string[];
  scale: number;
}

export interface SpriteCanvasHandle {
  getCanvas: () => HTMLCanvasElement | null;
}

export const SpriteCanvas = forwardRef<SpriteCanvasHandle, SpriteCanvasProps>(
  function SpriteCanvas({ pixels, scale }, fwdRef) {
    const ref = useRef<HTMLCanvasElement>(null);

    useImperativeHandle(fwdRef, () => ({
      getCanvas: () => ref.current,
    }));

    useEffect(() => {
      const canvas = ref.current;
      if (!canvas) return;
      const ctx = canvas.getContext("2d");
      if (!ctx) return;

      const w = pixels[0].length;
      const h = pixels.length;
      canvas.width = w * scale;
      canvas.height = h * scale;
      ctx.imageSmoothingEnabled = false;
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      for (let y = 0; y < h; y++) {
        for (let x = 0; x < w; x++) {
          const c = COLOR_MAP[pixels[y][x]];
          if (c) {
            ctx.fillStyle = c;
            ctx.fillRect(x * scale, y * scale, scale, scale);
          }
        }
      }
    }, [pixels, scale]);

    return <canvas ref={ref} style={{ imageRendering: "pixelated" }} />;
  },
);
