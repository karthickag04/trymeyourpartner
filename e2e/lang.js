const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  for (const [name, prefs] of [['tamil', { 'flutter.prefs.locale': '"ta"' }], ['dark', { 'flutter.prefs.themeMode': '"dark"' }]]) {
    const opts = {};
    const ctx = await b.newContext({ viewport: { width: 420, height: 860 }, ...opts });
    const p = await ctx.newPage();
    await p.addInitScript(kv => { for (const [k, v] of Object.entries(kv)) localStorage.setItem(k, v); }, prefs);
    await p.goto('http://127.0.0.1:8088/'); await p.waitForTimeout(10000);
    const ph = await p.$('flt-semantics-placeholder'); if (ph) { await ph.evaluate(e => e.click()); await p.waitForTimeout(800); }
    const L = await p.$$eval('flt-semantics [aria-label], flt-semantics span, flt-semantics [role=tab]', els => [...new Set(els.map(e => (e.getAttribute('aria-label') || e.textContent || '').trim()))].filter(Boolean));
    console.log(name, JSON.stringify(L.slice(0, 6)));
    await p.screenshot({ path: `${process.argv[2]}/${name}.png` });
    await ctx.close();
  }
  await b.close();
})();
