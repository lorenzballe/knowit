#!/usr/bin/env python3
"""Makes a card page self-contained for publishing: local stylesheets, scripts, videos and
images are put inside the HTML; CDN links stay as they are.

    python3 tool/cards/inline_page.py docs/cards/prototipi/giro-4.html out.html
"""
import base64, mimetypes, os, re, sys

src, out = sys.argv[1], sys.argv[2]
base = os.path.dirname(os.path.abspath(src))
html = open(src, encoding='utf-8').read()
local = lambda u: not re.match(r'^(https?:|data:|//)', u)
read = lambda u: open(os.path.join(base, u), 'rb').read()

def css(m):
    return f'<style>\n{read(m.group(1)).decode()}\n</style>' if local(m.group(1)) else m.group(0)

def js(m):
    return f'<script>\n{read(m.group(1)).decode()}\n</script>' if local(m.group(1)) else m.group(0)

def media(m):
    attr, u = m.group(1), m.group(2)
    if not local(u):
        return m.group(0)
    kind = mimetypes.guess_type(u)[0] or 'application/octet-stream'
    return f'{attr}="data:{kind};base64,{base64.b64encode(read(u)).decode()}"'

html = re.sub(r'<link rel="stylesheet" href="([^"]+)">', css, html)
html = re.sub(r'<script src="([^"]+)"></script>', js, html)
html = re.sub(r'\b(src|poster)="([^"]+\.(?:mp4|webm|jpg|jpeg|png|svg|webp))"', media, html)
open(out, 'w', encoding='utf-8').write(html)
print(f'{out}: {os.path.getsize(out) // 1024} KB')
