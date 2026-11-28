// The list for the iPhone, on /get (tool/site/chrome.py writes the form): an
// email, to be told once, the day Astute is on the App Store. It goes
// straight into Firestore, through its REST API, as one new document in
// waitlist/ holding the address, the page's language and the day, which
// the server stamps itself (REQUEST_TIME) — and nothing else: no account,
// no device, nothing about the visit. firestore.rules lets a page create
// exactly such a document, and nobody read one back; the owner reads the
// list in the Firebase console. The project is the one the site's account
// page names (keys.js); with no web key yet, the request goes without one,
// as Firestore allows, and the rules decide alone.
import { FIREBASE } from './keys.js';

const form = document.querySelector('[data-notify]');
// The shape the rules hold an address to, so that what the page lets
// through, the rules take: something, an @, something, a dot, something.
const SHAPE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const MAX = 254;

// A document's name as Firestore's own clients make one: twenty letters and
// digits, drawn at random.
const name = () => {
  const abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const bytes = crypto.getRandomValues(new Uint8Array(20));
  return Array.from(bytes, b => abc[b % abc.length]).join('');
};

export function body(project, id, email, lang) {
  return {
    writes: [{
      update: {
        name: `projects/${project}/databases/(default)/documents/waitlist/${id}`,
        fields: { email: { stringValue: email }, lang: { stringValue: lang } },
      },
      updateTransforms: [{ fieldPath: 'at', setToServerValue: 'REQUEST_TIME' }],
      currentDocument: { exists: false },
    }],
  };
}

if (form && FIREBASE.projectId) {
  const input = form.querySelector('input[type="email"]');
  const button = form.querySelector('button[type="submit"]');
  const error = form.querySelector('[data-notify-error]');
  const done = form.parentElement.querySelector('[data-notify-done]');
  const lang = /^[a-z]{2}$/.test(form.dataset.lang || '') ? form.dataset.lang : 'en';
  const project = FIREBASE.projectId;
  const url = `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(project)}/databases/(default)/documents:commit`
    + (FIREBASE.apiKey ? `?key=${encodeURIComponent(FIREBASE.apiKey)}` : '');
  const label = button.textContent;
  const say = message => {
    error.textContent = message;
    error.hidden = !message;
    input.setAttribute('aria-invalid', String(!!message && message === form.dataset.bad));
  };
  form.hidden = false;
  input.addEventListener('input', () => { if (!error.hidden) say(''); });
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const email = input.value.trim();
    if (!SHAPE.test(email) || email.length > MAX) { say(form.dataset.bad); input.focus(); return; }
    say('');
    button.disabled = true;
    button.textContent = form.dataset.sending;
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body(project, name(), email, lang)),
      });
      if (!res.ok) throw new Error(String(res.status));
      form.hidden = true;
      done.hidden = false;
      done.focus();
    } catch (err) {
      button.disabled = false;
      button.textContent = label;
      say(form.dataset.fail);
    }
  });
}
