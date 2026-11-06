const { start } = require('./lib');
(async () => {
  const a = await start(process.argv[2]);
  await a.p.goto('http://127.0.0.1:8088/'); await a.p.waitForTimeout(9000);
  const ph = await a.p.$('flt-semantics-placeholder'); if (ph) { await ph.evaluate(e => e.click()); await a.p.waitForTimeout(800); }
  console.log(process.argv[3], JSON.stringify((await a.labels()).slice(0, 6)));
  await a.snap(process.argv[3]);
  await a.browser.close();
})();
