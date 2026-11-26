// What the AI may spend, in US dollars, for every call to the model together:
// the morning's news, the questions about a card and the coach's notes
// (budget.ts keeps the count). The owner's credit is $100 a month: the month
// stops at $90, and no day may spend more than $3. Once either is spent, the
// news keeps the paper it has and the rest say "not available right now".

/** The most a calendar month (UTC) may spend. */
export const MONTH_BUDGET_USD = 90;

/** The most a day (UTC) may spend. */
export const DAY_BUDGET_USD = 3;
