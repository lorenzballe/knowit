// The two public keys the account page needs, and where each comes from.
// Neither is a secret: Firebase's identifies the project, and what a
// signed-in reader may read or write is decided by firestore.rules;
// RevenueCat's is a public SDK key, meant to ship in a client. With either
// left empty the page says accounts on the site are not connected yet, and
// does nothing else.
//
// Firebase: console → project astuto-3d398 → Project settings → Your apps
// → the Web app (add one, named "Astute site", if there is none yet).
export const FIREBASE = {
  apiKey: '',
  authDomain: 'astuto-3d398.firebaseapp.com',
  projectId: 'astuto-3d398',
  appId: '',
};

// RevenueCat: project Astute → the Web Billing app → API keys → Public API
// key. A sandbox key (rcb_sb_…) charges Stripe's test cards and the page
// says so; the production key (rcb_…) charges real ones.
export const REVENUECAT_WEB_KEY = '';
