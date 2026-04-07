import { FoodGrid } from "./FoodGrid/index.js";
import { useSelection } from "../hooks/useSelection.js";
import styles from "./App.module.css";

export function App() {
  const { select } = useSelection();

  return (
    <div className={styles.app}>
      <p className={styles.banner}>tap items to feed the microbiome</p>
      <FoodGrid onSelect={select} />
    </div>
  );
}
