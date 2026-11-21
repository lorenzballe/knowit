// node build.cjs src-en.html film-en.html: the scene with GSAP and the kit's
// fonts inlined, so the page stands alone (then render.cjs sets it frame by
// frame).
const fs = require('fs'), path = require('path');
const KIT = path.join(__dirname, '../../kit');
const b64 = f => fs.readFileSync(path.join(KIT, 'fonts', f)).toString('base64');
const [src, out] = process.argv.slice(2);
let html = fs.readFileSync(path.join(__dirname, src), 'utf8');
html = html
  .replace('%%FRAUNCES%%', () => b64('Fraunces.woff2'))
  .replace('%%FRAUNCES_I%%', () => b64('FrauncesItalic-latin.woff2'))
  .replace('%%FIGTREE%%', () => b64('Figtree.woff2'))
  .replace('%%GSAP%%', () => fs.readFileSync(path.join(KIT, 'vendor/gsap.min.js'), 'utf8'));
fs.writeFileSync(path.join(__dirname, out), html);
console.log(out, (html.length / 1024).toFixed(0), 'KB');
