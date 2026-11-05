const { chromium } = require('playwright');
const fs = require('fs');
async function start(out) {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 420, height: 860 } });
  const p = await ctx.newPage();
  const net = [];
  p.on('response', r => { if (r.url().includes('supabase.co') && r.status() >= 400) net.push(r.status() + ' ' + r.url().replace(/^https:\/\/[^/]+/, '').slice(0, 80)); });
  let shot = 0;
  const api = {
    p, net, browser,
    async snap(name) { shot++; await p.screenshot({ path: `${out}/${String(shot).padStart(2, '0')}_${name}.png` }); },
    async labels() { return p.$$eval('flt-semantics [aria-label], flt-semantics input, flt-semantics [role=button], flt-semantics span', els => [...new Set(els.map(e => (e.getAttribute('role') || e.tagName) + ':' + (e.getAttribute('aria-label') || e.textContent || '').trim().replace(/\s+/g, ' ').slice(0, 60)))].filter(x => !x.endsWith(':'))); },
    async tap(re, opts = {}) {
      const sel = opts.any ? 'flt-semantics *' : 'flt-semantics [role=button]';
      for (let i = 0; i < 12; i++) {
        const el = opts.label ? p.locator(`flt-semantics [aria-label*="${opts.label}"]`).last() : p.locator(sel, { hasText: re }).last();
        if (await el.count()) {
          const b = await el.boundingBox();
          if (b && b.y >= 0 && b.y + b.height <= 860) { await p.waitForTimeout(700); const b2 = await el.boundingBox(); const bx = b2 || b; await p.mouse.click(bx.x + bx.width / 2, bx.y + bx.height / 2); await p.waitForTimeout(opts.wait || 3500); return true; }
          if (false) { await p.mouse.click(b.x + b.width / 2, b.y + b.height / 2); await p.waitForTimeout(opts.wait || 3500); return true; }
          await p.mouse.move(210, 500); await p.mouse.wheel(0, b && b.y < 0 ? -400 : 400); await p.waitForTimeout(600);
        } else { await p.waitForTimeout(800); }
      }
      throw new Error('not found/visible: ' + re);
    },
    async login(email, pw) {
      await p.goto('http://127.0.0.1:8088/'); await p.waitForTimeout(9000);
      const ph = await p.$('flt-semantics-placeholder'); if (ph) { await ph.evaluate(e => e.click()); await p.waitForTimeout(800); }
      // Select fields by type: the sign-in form now also has a language switcher.
      const emailBox = p.locator('flt-semantics input[type=email]').first();
      await emailBox.click(); await emailBox.fill(email);
      const pwBox = p.locator('flt-semantics input[type=password]').first();
      await pwBox.click(); await pwBox.fill(pw);
      await p.waitForTimeout(300);
      await p.locator('flt-semantics [role=button]', { hasText: /^Sign In$/ }).last().click();
      await p.waitForTimeout(11000);
    },
  };
  return api;
}
module.exports = { start, pw: f => fs.readFileSync(f, 'utf8').trim() };
