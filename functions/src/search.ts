// The search over the whole pool, as the phone did it (searchPills): the
// question, the answer, the subject, the move and the keywords, the query
// contained in them, case aside. On the server so a phone need not hold
// the whole bank to ask it a question — and never written down: what a
// reader typed is theirs (the trace keeps only how long it was and how
// many it found).

import { Bank, Card } from './bank.js';

export function search(bank: Bank, query: string, limit = 30): Card[] {
  const q = query.trim().toLowerCase();
  if (!q) return [];
  const out: Card[] = [];
  for (const c of bank.live) {
    const hay = `${c.question} ${c.answer} ${c.topic} ${c.move ?? ''} ${(c.keywords ?? []).join(' ')}`.toLowerCase();
    if (hay.includes(q)) {
      out.push(c);
      if (out.length >= limit) break;
    }
  }
  return out;
}
