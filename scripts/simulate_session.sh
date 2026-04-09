#!/bin/bash
# Simulate a realistic food selection session.
# Usage: ./scripts/simulate_session.sh

API="http://localhost:3000/api"

pick() {
    local food="$1"
    local label="$2"
    local pause="$3"
    echo "  → $food"
    curl -s -X POST "$API/select" -H "Content-Type: application/json" \
        -d "{\"foodId\":\"$food\"}" | python3 -c "
import sys, json
d = json.load(sys.stdin)
h = d['stableBioScores']['health']
imp = d['impulseMagnitude']
print(f'    health={h:+.3f}  impulse={imp:.3f}')
" 2>/dev/null
    sleep "${pause:-1}"
}

rpause() {
    local lo="${1:-0.5}"
    local hi="${2:-2.0}"
    python3 -c "import random; print(f'{random.uniform($lo,$hi):.1f}')" | xargs sleep
}

echo ""
echo "═══════════════════════════════════════════════"
echo "  86BB Session Simulator (no batching)"
echo "═══════════════════════════════════════════════"
echo ""

echo "Resetting gut state..."
curl -s -X POST "$API/gut-state/reset?confirm=true" > /dev/null
sleep 1
echo ""

# --- Phase 1: Mediterranean ---
echo "── Phase 1: Mediterranean ──"
for f in salmon broccoli yogurt almonds grapes \
         lentils green_tea sourdough asparagus quinoa; do
    pick "$f" "med"
    rpause 0.8 2.5
done
echo "  ── pause 30s: watch decay ──"
sleep 30

# --- Phase 2: Junk food ---
echo ""
echo "── Phase 2: Junk food streak ──"
for f in burger fries soda candy_bar pizza \
         hot_dog chips energy_drink donut nachos; do
    pick "$f" "junk"
    rpause 0.5 1.5
done
echo "  ── pause 30s: watch decay ──"
sleep 30

# --- Phase 3: Fermented recovery ---
echo ""
echo "── Phase 3: Fermented + fiber ──"
for f in kimchi oatmeal kombucha black_beans tempeh \
         sauerkraut chia_seeds kefir miso_soup flaxseed; do
    pick "$f" "recovery"
    rpause 1.0 3.0
done
echo "  ── pause 30s: watch decay ──"
sleep 30

# --- Phase 4: Random (simulates crowd) ---
echo ""
echo "── Phase 4: Random crowd selections ──"
for f in steak blueberries coffee cake eggs \
         avocado beer dark_chocolate tofu curry \
         salmon bone_broth apple walnuts rice \
         ice_cream garlic smoothie lemon pad_thai; do
    pick "$f" "random"
    rpause 0.3 1.8
done
echo "  ── pause 30s: watch decay ──"
sleep 30

# --- Phase 5: Dairy heavy ---
echo ""
echo "── Phase 5: Dairy heavy ──"
for f in yogurt kefir aged_cheese cottage_cheese butter \
         yogurt kefir aged_cheese yogurt whey_protein; do
    pick "$f" "dairy"
    rpause 1.0 2.0
done
echo "  ── pause 30s: final decay ──"
sleep 30

echo ""
echo "═══════════════════════════════════════════════"
echo "  Done."
echo "═══════════════════════════════════════════════"
echo ""

curl -s "$API/gut-state" | python3 -c "
import sys, json
d = json.load(sys.stdin)
s = d['stableBioScores']
print('Final stable bio-scores:')
for k, v in s.items():
    print(f'  {k:15s}: {v:+.4f}')
print(f'Total selections: {d[\"totalSelections\"]}')
"
