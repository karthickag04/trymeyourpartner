const { start, pw } = require('./lib');
const { execSync } = require('child_process');
const OUT = process.argv[2], PW = pw(process.argv[3]), Q = process.argv[4], PA = process.argv[5];
(async () => {
  require('fs').mkdirSync(OUT, { recursive: true });
  const a = await start(OUT);
  try {
    await a.login('tmyp.test.a@example.com', PW);
    await a.p.waitForTimeout(4000); // let the subscription connect
    execSync(`${Q} "insert into public.notifications(profile_id,type,payload) values ('${PA}','interest_sent','{}')"`);
    let seen = false;
    for (let i = 0; i < 20 && !seen; i++) {
      await a.p.waitForTimeout(500);
      seen = (await a.labels()).some(x => x.includes('You received a new interest'));
    }
    console.log('realtime toast shown:', seen);
    await a.snap('toast');
  } catch (e) { console.log('ERROR', e.message); }
  await a.browser.close();
})();
