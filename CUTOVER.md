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
- [ ] Keep the prgmr VPS running 30 days as a rollback (switch the DNS record
      back to `71.19.156.131`), then cancel it.
- [ ] Search Console → Performance → right-click the chart on the switch day →
      Add annotation: "Moved to Cloudflare Pages".  Search Console keeps 16
      months of history, so there's nothing to write down beforehand.
- [ ] Weekly for 4–6 weeks, watch the average position for
      `/calculator/earlyretirement` (all devices and mobile only), using Compare: the weeks after the switch
      against the weeks before.  Clicks rise every January and are down on
      last year, so position is the fairer test.

## Later

- Fix email (Google Workspace, or Cloudflare Email Routing to Gmail).
- Delete the Perl app from the repo once the new site has been stable for a while.
- Post-launch experiments, one at a time: meta description, show the FIRE
  number, a "how the math works" section and FAQ, monthly contributions,
  the "Next steps" section.
