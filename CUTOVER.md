# Moving networthify.com to Cloudflare Pages

The new static site is in `site/`.  Tests: `npm test`.  Preview locally:
`npm run serve`, then open http://localhost:8000/ (or http://<your-ip>:8000/
on your phone).

## 1. Before the switch

- [ ] Find your logins: Namecheap, Cloudflare (or sign up), prgmr.com.

## 2. Deploy to a preview URL

- [x] Cloudflare dashboard → Workers & Pages → Create application → "Continue
      to Pages" (the Workers screen is the wrong one) → Import an existing Git
      repository.  Production branch: `static-site`.  Framework preset: none.
      Build command: empty.  Output directory: `site`.
      Preview: https://networthify.pages.dev/
- [x] Check the preview:
  - [x] `/` and `/calculator/earlyretirement` show the calculator
  - [x] `/calculator/earlyretirement?income=70000&initialBalance=0&expenses=25200&annualPct=5&withdrawalRate=4` shows 10.9 years
  - [x] `/fi`, `/earlyretirement/`, `/calculator/real-cost` redirect (301), keeping any `?income=...`
  - [x] `/calculator/recurring-charges` works
  - [x] `/transactions/view` shows the 404 page
  - [x] Look at it yourself on your phone
- [x] Pages project → Metrics → enable Web Analytics.
- [x] Search Console → Settings → Ownership verification: verified by DNS
      (Pages turns `/googlebd4e59492976fb15.html` into a redirect, so the
      HTML file method won't work there.  Keep the TXT records.)

## 3. Move DNS (aim for early-to-mid November; if it slips past ~Dec 1, wait until February)

- [ ] Cloudflare → Add a domain → `networthify.com` → Free plan.  It imports the
      current DNS records.  Namecheap had (checked 2026-10-31):

      | Record                      | Value                          | Keep? |
      |-----------------------------|--------------------------------|-------|
      | `@` A                       | `71.19.156.131` (the VM)       | yes for now, DNS only (grey cloud); Pages replaces it |
      | `www` A                     | `71.19.156.131` (the VM)       | yes for now, DNS only (grey cloud); Pages replaces it |
      | `@` MX                      | `1 smtp.google.com`            | **yes, exactly** |
      | `@` TXT ×2                  | `google-site-verification=KB20ukDY…` and `=XNUzmkwa…` | **yes, exactly** (Search Console) |
      | `@` TXT                     | `v=spf1 include:_spf.google.com ~all` | **yes, exactly** (email, added 2026-11-01) |
      | `google._domainkey` TXT     | `v=DKIM1; k=rsa; p=MIIBIjAN…`  | **yes, exactly** (email DKIM, added 2026-11-01) |
      | `_dmarc` TXT                | `v=DMARC1; p=none; rua=…`      | **yes, exactly** (email, added 2026-11-01) |
      | `*` URL redirect            | Namecheap's redirect server    | no: Namecheap-only, won't import |
      | `blog` CNAME                | `kablamo.github.com`           | no: dead, delete if it imports |

  - [ ] `MX networthify.com → smtp.google.com` (priority 1)
  - [ ] both `TXT google-site-verification=...` records (Search Console needs them)
  - [ ] SPF, DKIM and DMARC TXT records (the DKIM value is long; compare the
        start and end, or `dig TXT google._domainkey.networthify.com` after)
- [ ] Namecheap → Domain → Nameservers → Custom DNS → the two Cloudflare
      nameservers.  The domain stays registered at Namecheap.
- [ ] Once Cloudflare says the site is active: Pages project → Custom domains →
      add `networthify.com` and `www.networthify.com`.
- [ ] Cloudflare → SSL/TLS → Edge Certificates → Always Use HTTPS: on.
- [ ] Cloudflare → Rules → Redirect Rules → "Redirect from WWW to root"
      template (301, keep query string).

## 4. After the switch

- [ ] `curl -I https://networthify.com/calculator/earlyretirement` shows Cloudflare, not nginx.
- [ ] `curl -I https://www.networthify.com/` and `http://networthify.com/` → 301 to `https://networthify.com/`.
- [ ] Search Console → Sitemaps → submit `https://networthify.com/sitemap.xml`.
- [ ] Search Console → URL Inspection → `/calculator/earlyretirement` → Request indexing.
- [ ] Keep the VPS running 30 days as a rollback (switch the DNS record
      back to `71.19.156.131`), then cancel it at tornadovps.com (formerly
      prgmr; the service label is probably `kablamo`).  Anything that's only
      on the VM is lost: old Dovecot mail, whatever iijo.org ran (it already
      returns 502), and `backups/`, `csv/`, `networth.db`.
- [ ] When you cancel, remove iijo.org's A record (`71.19.156.131`), and any
      other domain pointing at that IP.  The address goes to another customer,
      and their site would show up on your domain.
- [ ] Search Console → Performance → right-click the chart on the switch day →
      Add annotation: "Moved to Cloudflare Pages".  Search Console keeps 16
      months of history, so there's nothing to write down beforehand.
- [ ] Weekly for 4–6 weeks, watch the average position for
      `/calculator/earlyretirement` (all devices and mobile only), using Compare: the weeks after the switch
      against the weeks before.  Clicks rise every January and are down on
      last year, so position is the fairer test.

## Later

- Email: done 2026-11-01.  networthify.com is a domain on the iijo.org
  Google Workspace, with SPF, DKIM and DMARC at Namecheap (they move with the DNS,
  see step 3).
  DMARC is `p=none` with reports to `dmarc@networthify.com`, and a
  catch-all (Gmail → Default routing) sends every @networthify.com address
  to the same inbox.
  - [ ] In a month, if the DMARC reports show only Google sending as the
        domain, change it to `p=quarantine`.
- Delete the Perl app from the repo once the new site has been stable for a while.
- Post-launch experiments, one at a time: meta description, show the FIRE
  number, a "how the math works" section and FAQ, monthly contributions,
  the "Next steps" section.
