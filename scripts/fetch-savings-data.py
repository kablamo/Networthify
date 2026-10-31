#!/usr/bin/env python3
"""Download household saving rates from the OECD and write site/data/household-saving.json.

Run once a year or so:  npm run data:savings
After changing the table markup:  python3 scripts/fetch-savings-data.py --page-only

Two OECD datasets and one US survey, all free to republish:

  rates      Net saving of households and NPISH, % of net disposable income.
             National Accounts at a Glance, chapter 5 (DSD_NAAG@DF_NAAG_V).
  quintiles  Gross saving / gross disposable income by income fifth.
             Experimental distributional accounts (DSD_EGDNA_INC_INC@DF_INC_INC).
  US tenths  BLS Consumer Expenditure Survey, via FRED: income after taxes
             minus spending.  The OECD has no US spending by income.
  US ages    The same survey, by age.

Disposable income is income after taxes, the same thing the calculator calls
"after tax income".
"""
import csv
import datetime
import io
import json
import os
import sys
import urllib.request

API = 'https://sdmx.oecd.org/public/rest/data/OECD.SDD.NAD,{flow},/all?dimensionAtObservation=AllDimensions'
SITE = os.path.join(os.path.dirname(__file__), '..', 'site')
OUT = os.path.join(SITE, 'data', 'household-saving.json')
PAGE = os.path.join(SITE, 'savings-rate-by-country.html')

# areas with no recent data, or that repeat another line
SKIP = {'EA', 'CRI', 'RUS'}
NAMES = {'CHN': 'China', 'EU': 'European Union', 'KOR': 'South Korea', 'SVK': 'Slovakia'}


def fetch(flow):
    req = urllib.request.Request(API.format(flow=flow), headers={
        'Accept': 'application/vnd.sdmx.data+csv; charset=utf-8; labels=both',
        'User-Agent': 'networthify.com data script',
    })
    with urllib.request.urlopen(req, timeout=300) as res:
        return list(csv.DictReader(io.StringIO(res.read().decode('utf-8'))))


def code(cell):
    return cell.split(':')[0].strip()


def name(cell):
    c = code(cell)
    return NAMES.get(c, cell.split(':', 1)[1].strip())


def col(row, prefix):
    return next(v for k, v in row.items() if k.startswith(prefix + ':'))


def rates():
    years = {}
    names = {}
    for row in fetch('DSD_NAAG@DF_NAAG_V'):
        if code(col(row, 'MEASURE')) != 'B8NS1M' or not row['OBS_VALUE']:
            continue
        area = code(col(row, 'REF_AREA'))
        if area in SKIP:
            continue
        names[area] = name(col(row, 'REF_AREA'))
        years.setdefault(area, {})[int(col(row, 'TIME_PERIOD'))] = round(float(row['OBS_VALUE']), 1)

    out = []
    for area, ys in years.items():
        if max(ys) < 2020:
            continue
        first, last = min(ys), max(ys)
        out.append({'code': area, 'name': names[area], 'start': first,
                    'values': [ys.get(y) for y in range(first, last + 1)]})
    return sorted(out, key=lambda c: c['name'])


def quintiles():
    # {(area, year, group): {'B6G': income, 'B8G': saving}}
    cells = {}
    names = {}
    for row in fetch('DSD_EGDNA_INC_INC@DF_INC_INC'):
        tx = code(col(row, 'TRANSACTION'))
        if tx not in ('B6G', 'B8G') or not row['OBS_VALUE'] or code(col(row, 'UNIT_MEASURE')) != 'XDC':
            continue
        # totals only: every household type, age, source of income...
        if any(code(col(row, d)) not in ('_T', '_Z') for d in
               ('HOUSEHOLD_TYPE', 'MAIN_INCOME_SOURCE', 'HOUSEHOLD_OWNERSHIP', 'AGE', 'SEX', 'ATTAINMENT_LEV')):
            continue
        area = code(col(row, 'REF_AREA'))
        names[area] = name(col(row, 'REF_AREA'))
        key = (area, int(col(row, 'TIME_PERIOD')), code(col(row, 'INCOME_GROUP')))
        cells.setdefault(key, {})[tx] = float(row['OBS_VALUE'])

    def rate(area, year, group):
        c = cells.get((area, year, group), {})
        return round(100 * c['B8G'] / c['B6G']) if c.get('B6G') and 'B8G' in c else None

    out = []
    for area in names:
        years = sorted({y for (a, y, g) in cells if a == area}, reverse=True)
        for year in years:
            values = [rate(area, year, 'QG%d' % q) for q in range(1, 6)]
            if None in values:
                continue
            # experimental numbers.  a country where the poor out-save the
            # rich (Sweden, as published) is a data problem, not a finding.
            if values[4] > values[0] and year >= 2015:
                out.append({'code': area, 'name': names[area], 'year': year, 'values': values, 'source': 'OECD'})
            break
    return sorted(out, key=lambda c: c['name'])


# US Consumer Expenditure Survey by tenth of income before taxes, from FRED.
# LB1502 is the lowest tenth, LB1511 the highest.
FRED = 'https://fred.stlouisfed.org/graph/fredgraph.csv?id={series}'
US_INCOME = 'CXUINCAFTTXLB15{q:02d}M'    # income after taxes
US_SPENDING = 'CXUTOTALEXPLB15{q:02d}M'  # average annual expenditures


def fred(series):
    req = urllib.request.Request(FRED.format(series=series), headers={'User-Agent': 'networthify.com data script'})
    with urllib.request.urlopen(req, timeout=60) as res:
        text = res.read().decode('utf-8')
    if not text.startswith('observation_date'):
        raise RuntimeError('FRED did not send data for ' + series)
    return {int(r['observation_date'][:4]): float(r[series])
            for r in csv.DictReader(io.StringIO(text)) if r[series] not in ('', '.')}


def us_deciles():
    """the OECD has no US spending by income, so use the BLS survey, which
    has tenths too.  it counts pension contributions as spending, so it
    reads a little low."""
    income = [fred(US_INCOME.format(q=q)) for q in range(2, 12)]
    spending = [fred(US_SPENDING.format(q=q)) for q in range(2, 12)]
    year = max(set.intersection(*(set(d) for d in income + spending)))
    values = [round(100 * (i[year] - s[year]) / i[year]) for i, s in zip(income, spending)]
    return {'code': 'USA', 'name': 'United States', 'year': year, 'values': values, 'source': 'BLS'}


# the same survey by age of the household's reference person.  LB0407 is
# everyone 65 and over, which double counts the two groups after it.
US_AGES = [('02', 'Under 25'), ('03', '25 to 34'), ('04', '35 to 44'), ('05', '45 to 54'),
           ('06', '55 to 64'), ('08', '65 to 74'), ('09', '75 and over')]


def us_by_age():
    income = [fred('CXUINCAFTTXLB04%sM' % n) for n, _ in US_AGES]
    spending = [fred('CXUTOTALEXPLB04%sM' % n) for n, _ in US_AGES]
    year = max(set.intersection(*(set(d) for d in income + spending)))
    return {'code': 'USA', 'name': 'United States', 'year': year, 'source': 'BLS',
            'groups': [{'label': label, 'value': round(100 * (i[year] - s[year]) / i[year])}
                       for (_, label), i, s in zip(US_AGES, income, spending)]}


def latest(country):
    """the last year with a number"""
    for i in range(len(country['values']) - 1, -1, -1):
        if country['values'][i] is not None:
            return country['start'] + i, country['values'][i]


def bar(v, lo, hi):
    """left and width of a bar, in % of the row, with zero at the same place in every row.
    js/savings-trends.js does the same when you add your own rate."""
    span = hi - lo
    zero = -lo / span * 100
    width = abs(v) / span * 100
    return (zero if v >= 0 else zero - width), width


def write_page(data):
    """put the latest numbers in the page itself, for search engines and no-JS readers"""
    rows = sorted((latest(c) + (c['name'], c['code']) for c in data['rates']['countries']),
                  key=lambda r: -r[1])
    lo = min(0, min(r[1] for r in rows))
    hi = max(0, max(r[1] for r in rows))
    html = ''
    for y, v, n, code in rows:
        left, width = bar(v, lo, hi)
        html += ('            <tr data-code="{code}"><td>{n}</td><td class="year">{y}</td><td><span class="rate">'
                 '<span class="track"><span class="bar{neg}" style="left:{l:.1f}%;width:{w:.1f}%"></span></span>'
                 '<span class="v">{v:.1f}%</span></span></td></tr>\n'
                 .format(n=n, code=code, y=y, v=v, l=left, w=width, neg=' neg' if v < 0 else ''))
    with open(PAGE) as f:
        page = f.read()
    page = replace_between(page, 'latest', '\n' + html)
    page = replace_between(page, 'updated', 'Updated ' + data['fetched'] + '.')
    with open(PAGE, 'w') as f:
        f.write(page)


def replace_between(page, name, text):
    start = page.index('<!-- %s:start' % name)
    start = page.index('-->', start) + 3
    end = page.index('<!-- %s:end -->' % name)
    return page[:start] + text + page[end:]


def main():
    if sys.argv[1:] == ['--page-only']:
        # rewrite the table from the data we already have
        with open(OUT) as f:
            write_page(json.load(f))
        print('wrote', os.path.normpath(PAGE))
        return
    data = {
        'fetched': datetime.date.today().isoformat(),
        'source': 'OECD',
        'rates': {
            'title': 'Net saving of households, % of net disposable income',
            'dataset': 'https://data-explorer.oecd.org/vis?df[ag]=OECD.SDD.NAD&df[id]=DSD_NAAG%40DF_NAAG_V',
            'countries': rates(),
        },
        'age': {
            'title': 'Income after taxes minus spending, % of income after taxes, by age.  '
                     'BLS Consumer Expenditure Survey',
            'dataset': 'https://www.bls.gov/cex/',
            'countries': [us_by_age()],
        },
        'quintiles': {
            'title': 'Gross saving, % of gross disposable income, by income fifth (experimental).  '
                     'United States: income after taxes minus spending, by tenth of income before taxes, '
                     'BLS Consumer Expenditure Survey',
            'dataset': 'https://data-explorer.oecd.org/vis?df[ag]=OECD.SDD.NAD&df[id]=DSD_EGDNA_INC_INC%40DF_INC_INC',
            'countries': sorted(quintiles() + [us_deciles()], key=lambda c: c['name']),
        },
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w') as f:
        json.dump(data, f, separators=(',', ':'), ensure_ascii=False)
        f.write('\n')
    write_page(data)
    print('wrote', os.path.normpath(OUT), 'and', os.path.normpath(PAGE), len(data['rates']['countries']), 'countries,',
          len(data['quintiles']['countries']), 'with income fifths')


if __name__ == '__main__':
    main()
