// Numbers that are the same everywhere.
//
// Two of the hashes here are the phone's own, bit for bit: `unit`, which
// seeds the launch crowd under Explore's top list (lib/sync/tally.dart),
// and `keyed`, which turns the shelves over day by day
// (lib/data/pills_repository.dart). A server and a phone that disagreed
// about either would show two different Explores. The third is a small
// seeded generator for the dealer, where the server's choice only has to
// agree with itself.

/** FNV-1a over UTF-16 code units, then the murmur finaliser: [0, 1). */
export function unit(text: string): number {
  let h = 0x811c9dc5;
  for (let i = 0; i < text.length; i++) {
    h = Math.imul(h ^ text.charCodeAt(i), 0x01000193) >>> 0;
  }
  // Every step back to an unsigned 32-bit number: a xor in JavaScript is
  // signed, and a negative fraction is not a fraction.
  h = (h ^ (h >>> 16)) >>> 0;
  h = Math.imul(h, 0x85ebca6b) >>> 0;
  h = (h ^ (h >>> 13)) >>> 0;
  h = Math.imul(h, 0xc2b2ae35) >>> 0;
  h = (h ^ (h >>> 16)) >>> 0;
  return h / 0x100000000;
}

/** The shelves' order key: `hash = (hash * 31 + unit) & 0x1FFFFFFF` over the text. */
export function keyed(text: string): number {
  // Not Math.imul: the phone multiplies without wrapping and masks after,
  // and hash * 31 is under 2^34, which a double holds exactly.
  let hash = 0;
  for (let i = 0; i < text.length; i++) {
    hash = (hash * 31 + text.charCodeAt(i)) & 0x1fffffff;
  }
  return hash;
}

/** A 32-bit seed from a string. */
export function seedOf(text: string): number {
  return Math.floor(unit(`seed:${text}`) * 0x100000000) >>> 0;
}

/** mulberry32: small, fast, and the same on every machine. */
export function rng(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Fisher–Yates with a seeded source, in place. */
export function shuffle<T>(items: T[], next: () => number): T[] {
  for (let i = items.length - 1; i > 0; i--) {
    const j = Math.floor(next() * (i + 1));
    [items[i], items[j]] = [items[j], items[i]];
  }
  return items;
}
