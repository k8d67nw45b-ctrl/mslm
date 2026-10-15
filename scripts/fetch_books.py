import json
import os
import re
import urllib.parse
import urllib.request
from html.parser import HTMLParser

API = 'https://ar.wikisource.org/w/api.php'
UA = {'User-Agent': 'RafiqAlMuslimBuild/1.0 (GitHub Actions; personal project)'}
OUT = 'assets/data'
TASH = re.compile('[\u064B-\u0652\u0670\u0640]')

BOOKS = [
    {
        'id': 'usool3',
        'title': 'الأصول الثلاثة وأدلتها',
        'author': 'الإمام محمد بن عبد الوهاب',
        'about': 'متن مختصر في معرفة العبد ربه ودينه ونبيه.',
        'queries': ['الأصول الثلاثة وأدلتها', 'الأصول الثلاثة'],
        'must': ['معرفة العبد'],
        'min': 3000,
    },
    {
        'id': 'qawaid4',
        'title': 'القواعد الأربع',
        'author': 'الإمام محمد بن عبد الوهاب',
        'about': 'رسالة قصيرة في أربع قواعد تتعلق بالتوحيد والشرك.',
        'queries': ['القواعد الأربع'],
        'must': ['القاعدة الأولى'],
        'min': 1500,
    },
    {
        'id': 'kashf',
        'title': 'كشف الشبهات',
        'author': 'الإمام محمد بن عبد الوهاب',
        'about': 'رسالة في الرد على شبهات تتعلق بالتوحيد.',
        'queries': ['كشف الشبهات'],
        'must': ['الشبه'],
        'min': 12000,
    },
    {
        'id': 'tawhid',
        'title': 'كتاب التوحيد',
        'author': 'الإمام محمد بن عبد الوهاب',
        'about': 'كتاب مبوّب في التوحيد بالآيات والأحاديث.',
        'queries': ['كتاب التوحيد الذي هو حق الله على العبيد', 'كتاب التوحيد'],
        'must': ['باب فضل التوحيد'],
        'min': 40000,
    },
    {
        'id': 'wasitiyya',
        'title': 'العقيدة الواسطية',
        'author': 'شيخ الإسلام ابن تيمية',
        'about': 'عقيدة أهل السنة والجماعة مختصرة بالأدلة.',
        'queries': ['العقيدة الواسطية', 'الواسطية'],
        'must': ['الفرقة الناجية'],
        'min': 15000,
    },
]

VOID = {'br', 'img', 'hr', 'meta', 'link', 'input', 'wbr'}
BLOCK = {'p', 'div', 'li', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'tr', 'dd', 'dt', 'blockquote'}
SKIP_CLS = ('noprint', 'mw-editsection', 'ws-noexport', 'navbox',
            'headertemplate', 'metadata', 'reference')


def plain(s):
    return TASH.sub('', s)


def api(params):
    p = dict(params)
    p['format'] = 'json'
    url = API + '?' + urllib.parse.urlencode(p)
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode('utf-8'))


class P(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.out = []
        self.skip = 0
        self.stack = []

    def handle_starttag(self, tag, attrs):
        if tag == 'br':
            if not self.skip:
                self.out.append('\n')
            return
        if tag in VOID:
            return
        cls = dict(attrs).get('class') or ''
        skipit = tag in ('script', 'style', 'sup') or any(k in cls for k in SKIP_CLS)
        self.stack.append(skipit)
        if skipit:
            self.skip += 1
        if tag in BLOCK and not self.skip:
            self.out.append('\n')

    def handle_endtag(self, tag):
        if tag in VOID:
            return
        if self.stack:
            if self.stack.pop():
                self.skip -= 1
        if tag in BLOCK and not self.skip:
            self.out.append('\n')

    def handle_data(self, data):
        if not self.skip:
            self.out.append(data)


def page_lines(title):
    d = api({'action': 'parse', 'page': title, 'prop': 'text',
             'redirects': 1, 'disablelimitreport': 1})
    html = d['parse']['text']['*']
    p = P()
    p.feed(html)
    out = []
    for line in ''.join(p.out).split('\n'):
        line = re.sub(r'\[[^\]]*تحرير[^\]]*\]', '', line)
        line = re.sub(r'\s+', ' ', line).strip()
        if line:
            out.append(line)
    return out


def search(q):
    d = api({'action': 'query', 'list': 'search', 'srsearch': q,
             'srnamespace': 0, 'srlimit': 8})
    return [r['title'] for r in d.get('query', {}).get('search', [])]


def subpages(title):
    d = api({'action': 'query', 'list': 'allpages', 'apprefix': title + '/',
             'aplimit': 200, 'apnamespace': 0})
    names = [r['title'] for r in d.get('query', {}).get('allpages', [])]

    def key(n):
        nums = re.findall(r'\d+', n)
        return [int(x) for x in nums] or [0]

    return sorted(names, key=key)


def ok(lines, b):
    text = ' '.join(lines)
    if len(text) < b['min']:
        return False
    pt = plain(text)
    return all(plain(m) in pt for m in b['must'])


def fetch_book(b):
    tried = []
    for q in b['queries']:
        for t in search(q):
            if len(tried) >= 8:
                break
            if t in tried or 'شرح' in t:
                continue
            tried.append(t)
            try:
                lines = page_lines(t)
            except Exception as e:
                print('  error reading', t, e)
                continue
            print('  candidate', t, 'chars', sum(len(x) for x in lines))
            if ok(lines, b):
                return t, lines
            subs = subpages(t)
            if 0 < len(subs) <= 150:
                allv = list(lines)
                for s in subs:
                    try:
                        allv += page_lines(s)
                    except Exception:
                        pass
                print('  with', len(subs), 'subpages chars', sum(len(x) for x in allv))
                if ok(allv, b):
                    return t, allv
    return None, None


def main():
    os.makedirs(OUT, exist_ok=True)
    ipath = os.path.join(OUT, 'books_index.json')
    index = {}
    if os.path.exists(ipath):
        try:
            for m in json.load(open(ipath, encoding='utf-8')):
                index[m['id']] = m
        except Exception:
            pass
    for b in BOOKS:
        print('==', b['title'])
        try:
            t, lines = fetch_book(b)
        except Exception as e:
            print('  failed:', e)
            t, lines = None, None
        if not lines:
            print('  MISSING', b['id'])
            continue
        with open(os.path.join(OUT, 'book_%s.json' % b['id']), 'w', encoding='utf-8') as f:
            json.dump({'p': lines}, f, ensure_ascii=False, separators=(',', ':'))
        index[b['id']] = {
            'id': b['id'],
            'title': b['title'],
            'author': b['author'],
            'about': b['about'],
            'n': len(lines),
            'source': 'ويكي مصدر: ' + t,
        }
        print('  FOUND', b['id'], '|', t, '|', len(lines), 'lines')
    order = [b['id'] for b in BOOKS]
    out = [index[i] for i in order if i in index]
    with open(ipath, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, separators=(',', ':'))
    print('found', len(out), 'of', len(BOOKS))


main()
