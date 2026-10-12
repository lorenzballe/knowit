// The search over the whole pool, as the phone did it (searchPills): the
// question, the answer, the subject, the move and the keywords, the query
// contained in them, case aside. On the server so a phone need not hold
// the whole bank to ask it a question — and never written down: what a
// reader typed is theirs (the trace keeps only how long it was and how
// many it found).
//
// A card about a place is found only by a reader who lives there, the same
// rule as everywhere it could be dealt (docs/PLACES.md §5): searching for
// "Modena" from Palermo finds nothing that was written for Modena.

import { Bank, Card, isPlaceCard } from './bank.js';
import { Place, cardPlaceFromJson, placeFit } from './place.js';

export function search(bank: Bank, query: string, limit = 30, place: Place | null = null): Card[] {
  const q = query.trim().toLowerCase();
  if (!q) return [];
  const out: Card[] = [];
  // The bank's own order, cards about a place where they stand in it, so a
  // reader with no place finds exactly what they always found.
  for (const c of bank.cards) {
    if (c.disabled) continue;
    if (isPlaceCard(c) && placeFit(cardPlaceFromJson(c.place), place) === 'none') continue;
    const hay = `${c.question} ${c.answer} ${c.topic} ${c.move ?? ''} ${(c.keywords ?? []).join(' ')}`.toLowerCase();
    if (hay.includes(q)) {
      out.push(c);
      if (out.length >= limit) break;
    }
  }
  return out;
}
