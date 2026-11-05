const { start, pw } = require('./lib');
const fs = require('fs');
const OUT = process.argv[2], PW = pw(process.argv[3]), CODE = fs.readFileSync(process.argv[4], 'utf8').trim();
(async () => {
  fs.mkdirSync(OUT + '/routes', { recursive: true });
  const a = await start(OUT + '/routes');
  const p = a.p;
  try {
    // 1. Open a shared profile link while signed out
    await p.goto(`http://127.0.0.1:8088/#/p/${CODE}`); await p.waitForTimeout(8000);
    console.log('1 signed-out link ->', p.url().replace('http://127.0.0.1:8088', ''));
    await a.snap('link_signed_out');
    // 2. Sign in on that page
    const ph = await p.$('flt-semantics-placeholder'); if (ph) { await ph.evaluate(e => e.click()); await p.waitForTimeout(800); }
    const em = p.locator('flt-semantics input[type=email]').first(); await em.click(); await em.fill('tmyp.test.a@example.com');
    const pwb = p.locator('flt-semantics input[type=password]').first(); await pwb.click(); await pwb.fill(PW);
    await p.waitForTimeout(300);
    await p.locator('flt-semantics [role=button]', { hasText: 'Sign In' }).last().click();
    await p.waitForTimeout(10000);
    console.log('2 after sign-in ->', p.url().replace('http://127.0.0.1:8088', ''));
    const L = await a.labels();
    console.log('  shows profile B:', L.some(x => x.includes('Claude Test B')), '| reveal button:', L.some(x => x.includes('Reveal / request contact')));
    await a.snap('link_after_login');
    // 3. Go to the app and switch tabs
    await p.goto('http://127.0.0.1:8088/#/home'); await p.waitForTimeout(7000);
    const ph2 = await p.$('flt-semantics-placeholder'); if (ph2) { await ph2.evaluate(e => e.click()); await p.waitForTimeout(800); }
    for (const [label, tab] of [['Search', /Tab 3 of 5/], ['Interests', /Tab 4 of 5/], ['Profile', /Tab 5 of 5/], ['Home', /Tab 1 of 5/]]) {
      await a.tap(tab, { wait: 2500 });
      console.log(`3 tap ${label} ->`, p.url().replace('http://127.0.0.1:8088', ''));
    }
    // 4. Open B from Top picks: URL should be the profile link
    const s = p.locator('flt-semantics span', { hasText: /^Claude$/ }).first(); const b = await s.boundingBox();
    await p.mouse.click(b.x + b.width / 2, b.y + b.height / 2); await p.waitForTimeout(4000);
    console.log('4 open profile from card ->', p.url().replace('http://127.0.0.1:8088', ''));
    await p.goBack(); await p.waitForTimeout(3000);
    console.log('5 browser back ->', p.url().replace('http://127.0.0.1:8088', ''));
    await a.snap('back_home');
  } catch (e) { console.log('ERROR', e.message); await a.snap('error'); }
  console.log('NET ERRORS:', a.net.join(' | '));
  await a.browser.close();
})();
