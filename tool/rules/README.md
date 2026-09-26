# Firestore rules, tested

`firestore.rules` run against the Firestore emulator: what a reader may do
to their own record, a friend's board and the day's counts, and — the part
worth a test — everything they may not. Needs Node and Java.

    cd tool/rules && npm install && npm test

The counts are the one place a stranger's write lands on a shared document,
so every way of moving one by more than one, or moving two, or taking one
back, or writing into a week that is over, is tried and has to fail.
