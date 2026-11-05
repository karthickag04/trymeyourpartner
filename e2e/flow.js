const { start, pw } = require('./lib');
const OUT = process.argv[2], PW = pw(process.argv[3]), step = process.argv[4];
(async () => {
  const a = await start(OUT + '/' + step); require('fs').mkdirSync(OUT + '/' + step, { recursive: true });
  try {
    const me = step === 'b_accepts' ? 'b' : 'a', other = me === 'a' ? 'Claude' : 'Claude';
    await a.login(`tmyp.test.${me}@example.com`, PW);
    await a.snap('home');
    // open the other test member from Top picks / Similar
    const span = a.p.locator('flt-semantics span', { hasText: /^Claude$/ }).first();
    const bb = await span.boundingBox(); await a.p.mouse.click(bb.x + bb.width / 2, bb.y + bb.height / 2); await a.p.waitForTimeout(5000);
    await a.snap('profile');
    await a.tap(/Reveal \/ request contact/i, { wait: 7000 });
    await a.snap('after_tap');
    const L = await a.labels();
    console.log('TAIL:', JSON.stringify(L.slice(-12)));
    if (step === 'b_accepts') {
      const acc = L.find(x => /Accept/i.test(x));
      if (acc) { await a.tap(/Accept/); await a.snap('accepted'); console.log('AFTER ACCEPT:', JSON.stringify((await a.labels()).slice(-8))); }
    }
  } catch (e) { console.log('ERROR', e.message); await a.snap('error'); }
  console.log('NET ERRORS:', a.net.slice(0, 8).join(' | '));
  await a.browser.close();
})();
