const { start, pw } = require('./lib');
const OUT = process.argv[2], PW = pw(process.argv[3]);
(async () => {
  require('fs').mkdirSync(OUT + '/email', { recursive: true });
  const a = await start(OUT + '/email');
  try {
    await a.login('tmyp.test.a@example.com', PW);
    await a.tap(/Tab 5 of 5/, { wait: 5000 });
    await a.snap('profile_tab');
    const L = await a.labels();
    console.log('EMAIL LABELS:', JSON.stringify(L.filter(x => /@|mail/i.test(x)).slice(0, 6)));
    const span = a.p.locator('flt-semantics span', { hasText: /^Claude$/ });
    // reopen B and check reveal sheet width
    await a.tap(/Tab 1 of 5/, { wait: 4000 });
    const s = a.p.locator('flt-semantics span', { hasText: /^Claude$/ }).first(); const b = await s.boundingBox();
    await a.p.mouse.click(b.x + b.width / 2, b.y + b.height / 2); await a.p.waitForTimeout(5000);
    await a.tap(/Reveal \/ request contact/i, { wait: 7000 });
    await a.snap('reveal_sheet');
  } catch (e) { console.log('ERROR', e.message); await a.snap('error'); }
  await a.browser.close();
})();
