# Moving networthify.com to Cloudflare Pages

The new static site is in `site/`.  Tests: `npm test`.  Preview locally:
`npm run serve`, then open http://localhost:8000/ (or http://<your-ip>:8000/
on your phone).

## 1. Before the switch

- [ ] Search Console → Performance: write down last 28 days of clicks, and the
      average position for `/calculator/earlyretirement` (all devices and
      mobile only).  This is the baseline.
- [ ] Find your logins: Namecheap, Cloudflare (or sign up), prgmr.com.

## 2. Deploy to a preview URL

- [ ] Cloudflare dashboard → Workers & Pages → Create → Pages → connect the
      GitHub repo.  Framework preset: none.  Build command: empty.  Output
      directory: `site`.
- [ ] Open the `*.pages.dev` URL on your phone and desktop.  Check:
  - [ ] `/` and `/calculator/earlyretirement` show the calculator
  - [ ] `/calculator/earlyretirement?income=70000&initialBalance=0&expenses=25200&annualPct=5&withdrawalRate=4` shows 10.9 years
  - [ ] `/fi`, `/earlyretirement/`, `/calculator/real-cost` redirect (301), keeping any `?income=...`
  - [ ] `/calculator/recurring-charges` works
  - [ ] `/transactions/view` shows the 404 page
- [ ] Pages project → Metrics → enable Web Analytics.

## 3. Move DNS (aim for early-to-mid November; if it slips past ~Dec 1, wait until February)

- [ ] Cloudflare → Add a site → `networthify.com` → Free plan.  It imports the
      current DNS records.  **Confirm these came across exactly:**
  - [ ] `MX networthify.com → smtp.google.com` (priority 1)
  - [ ] both `TXT google-site-verification=...` records (Search Console needs them)
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
- [ ] Watch Search Console weekly for 4–6 weeks and compare with the baseline.
- [ ] Keep the prgmr VPS running 30 days as a rollback (switch the DNS record
      back to `71.19.156.131`), then cancel it.

## Later

- Fix email (Google Workspace, or Cloudflare Email Routing to Gmail).
- Delete the Perl app from the repo once the new site has been stable for a while.
- Post-launch experiments, one at a time: meta description, show the FIRE
  number, a "how the math works" section and FAQ, monthly contributions,
  the "Next steps" section.
