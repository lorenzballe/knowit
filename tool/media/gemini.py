#!/usr/bin/env python3
"""Images, clips and narration for the cards from one Google key (Gemini API).

The key comes from the environment: GEMINI_API_KEY (set it in the cloud environment's
secrets, or in a local .env that is never committed). Google's API is reachable from the
cloud sandbox, so nothing else has to be allowed.

    python3 tool/media/gemini.py models [filter]          what this key can use
    python3 tool/media/gemini.py image "prompt" out.png [--ref style.png ...] [--model M]
    python3 tool/media/gemini.py video "prompt" out.mp4 [--ratio 9:16] [--image first.png] [--model M]
    python3 tool/media/gemini.py voice "text" out.wav [--voice Kore] [--model M]

Model names change; `models` lists what exists today, and --model picks one.
Rules for what generated media may do in a card: docs/cards/HIGGSFIELD.md (no facts, no text).
"""
import argparse, base64, json, mimetypes, os, struct, sys, time, urllib.error, urllib.request

API = 'https://generativelanguage.googleapis.com/v1beta'
DEFAULTS = {'image': 'gemini-3-pro-image-preview', 'video': 'veo-3.1-fast-generate-preview', 'voice': 'gemini-2.5-flash-preview-tts'}


def key():
    k = os.environ.get('GEMINI_API_KEY') or os.environ.get('GOOGLE_API_KEY')
    if not k and os.path.exists('.env'):
        for line in open('.env'):
            if line.startswith(('GEMINI_API_KEY=', 'GOOGLE_API_KEY=')):
                k = line.split('=', 1)[1].strip().strip('"\'')
    if not k:
        sys.exit('No GEMINI_API_KEY. Create one at https://aistudio.google.com/apikey and add it to the environment secrets.')
    return k


def call(method, path, body=None, raw=False):
    url = path if path.startswith('http') else f'{API}/{path}'
    req = urllib.request.Request(url, method=method, data=json.dumps(body).encode() if body is not None else None,
                                 headers={'x-goog-api-key': key(), 'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            data = r.read()
    except urllib.error.HTTPError as e:
        sys.exit(f'{e.code} from Google: {e.read().decode()[:600]}')
    return data if raw else json.loads(data)


def inline(path):
    return {'inlineData': {'mimeType': mimetypes.guess_type(path)[0] or 'image/png', 'data': base64.b64encode(open(path, 'rb').read()).decode()}}


def models(flt):
    page = ''
    while True:
        r = call('GET', f'models?pageSize=200{page}')
        for m in r.get('models', []):
            name = m['name'].split('/', 1)[1]
            if not flt or flt in name:
                print(f"{name:48} {', '.join(m.get('supportedGenerationMethods', []))}")
        if not r.get('nextPageToken'):
            break
        page = '&pageToken=' + r['nextPageToken']


def image(a):
    parts = [inline(p) for p in a.ref] + [{'text': a.prompt}]
    r = call('POST', f'models/{a.model or DEFAULTS["image"]}:generateContent',
             {'contents': [{'parts': parts}], 'generationConfig': {'responseModalities': ['IMAGE']}})
    for c in r.get('candidates', []):
        for p in c.get('content', {}).get('parts', []):
            if 'inlineData' in p:
                open(a.out, 'wb').write(base64.b64decode(p['inlineData']['data']))
                return print(a.out)
    sys.exit('No image came back: ' + json.dumps(r)[:600])


def video(a):
    inst = {'prompt': a.prompt}
    if a.image:
        d = inline(a.image)['inlineData']
        inst['image'] = {'bytesBase64Encoded': d['data'], 'mimeType': d['mimeType']}
    op = call('POST', f'models/{a.model or DEFAULTS["video"]}:predictLongRunning',
              {'instances': [inst], 'parameters': {'aspectRatio': a.ratio}})
    while not op.get('done'):
        time.sleep(10)
        op = call('GET', op['name'])
        print('…', file=sys.stderr)
    if 'error' in op:
        sys.exit('Video failed: ' + json.dumps(op['error'])[:600])
    samples = op['response'].get('generateVideoResponse', {}).get('generatedSamples', [])
    if not samples:
        sys.exit('No video came back: ' + json.dumps(op)[:600])
    open(a.out, 'wb').write(call('GET', samples[0]['video']['uri'], raw=True))
    print(a.out)


def voice(a):
    r = call('POST', f'models/{a.model or DEFAULTS["voice"]}:generateContent', {
        'contents': [{'parts': [{'text': a.text}]}],
        'generationConfig': {'responseModalities': ['AUDIO'], 'speechConfig': {'voiceConfig': {'prebuiltVoiceConfig': {'voiceName': a.voice}}}}})
    pcm = base64.b64decode(r['candidates'][0]['content']['parts'][0]['inlineData']['data'])
    rate = 24000  # Gemini TTS returns 16-bit mono PCM at 24 kHz
    with open(a.out, 'wb') as f:
        f.write(b'RIFF' + struct.pack('<I', 36 + len(pcm)) + b'WAVEfmt ' + struct.pack('<IHHIIHH', 16, 1, 1, rate, rate * 2, 2, 16) + b'data' + struct.pack('<I', len(pcm)) + pcm)
    print(a.out)


p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
sub = p.add_subparsers(dest='cmd', required=True)
s = sub.add_parser('models'); s.add_argument('filter', nargs='?')
s = sub.add_parser('image'); s.add_argument('prompt'); s.add_argument('out'); s.add_argument('--ref', action='append', default=[]); s.add_argument('--model')
s = sub.add_parser('video'); s.add_argument('prompt'); s.add_argument('out'); s.add_argument('--ratio', default='9:16'); s.add_argument('--image'); s.add_argument('--model')
s = sub.add_parser('voice'); s.add_argument('text'); s.add_argument('out'); s.add_argument('--voice', default='Kore'); s.add_argument('--model')
a = p.parse_args()
{'models': lambda: models(a.filter), 'image': lambda: image(a), 'video': lambda: video(a), 'voice': lambda: voice(a)}[a.cmd]()
