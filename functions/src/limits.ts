// What the AI may spend, in US dollars, for every call to the model together:
// the morning's news, the questions about a card and the coach's notes
// (budget.ts keeps the count). The owner's credit is $100 a month: the month
// stops at $90, and no day may spend more than $3. Once either is spent, the
// news keeps the paper it has and the rest say "not available right now".

/** The most a calendar month (UTC) may spend. */
export const MONTH_BUDGET_USD = 90;

/** The most a day (UTC) may spend. */
export const DAY_BUDGET_USD = 3;

// What the voice may read, in characters, for Listen (listen.ts): the day's
// five read aloud by ElevenLabs, which charges by the character, $0.08 for a
// thousand on Eleven v4. Each card is read once for everybody and kept, so
// what is spent is new cards, not readers. The plan the owner buys includes
// so many characters a month (Creator: 275,000): the month stops short of
// them, so the plan is never overdrawn, and no day may spend more than a
// tenth of it. Once either is spent nothing new is read until it turns; what
// was read before still plays. A plan with more characters is a bigger
// number here, and nothing else.

/** The most a calendar month (UTC) may have read aloud. */
export const LISTEN_MONTH_CHARS = 250_000;

/** The most a day (UTC) may have read aloud. */
export const LISTEN_DAY_CHARS = 25_000;

/** The most cards one reader may have read aloud in a day: today's five,
 * tomorrow's, and a few more. What bounds a phone that lies about its plan. */
export const LISTEN_CARDS_PER_DAY = 15;
