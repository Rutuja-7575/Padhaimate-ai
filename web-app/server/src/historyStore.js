import { promises as fs } from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, "..", "data");
const HISTORY_FILE = path.join(DATA_DIR, "history.json");

/**
 * Makes sure the data folder + history file exist before we try to read/write them.
 */
async function ensureStore() {
  await fs.mkdir(DATA_DIR, { recursive: true });
  try {
    await fs.access(HISTORY_FILE);
  } catch {
    await fs.writeFile(HISTORY_FILE, JSON.stringify([], null, 2));
  }
}

/**
 * Returns every saved Q&A entry, most recent first.
 */
export async function getHistory() {
  await ensureStore();
  const raw = await fs.readFile(HISTORY_FILE, "utf-8");
  const entries = JSON.parse(raw);
  return entries.slice().reverse();
}

/**
 * Appends a new Q&A entry to the history file.
 */
export async function addHistoryEntry({ question, answer, sources }) {
  await ensureStore();
  const raw = await fs.readFile(HISTORY_FILE, "utf-8");
  const entries = JSON.parse(raw);

  const entry = {
    id: Date.now().toString(36) + Math.random().toString(36).slice(2, 8),
    question,
    answer,
    sources: sources || [],
    timestamp: new Date().toISOString(),
  };

  entries.push(entry);
  await fs.writeFile(HISTORY_FILE, JSON.stringify(entries, null, 2));
  return entry;
}

/**
 * Clears all saved history.
 */
export async function clearHistory() {
  await ensureStore();
  await fs.writeFile(HISTORY_FILE, JSON.stringify([], null, 2));
}
