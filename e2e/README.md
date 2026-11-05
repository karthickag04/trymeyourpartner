# Browser end-to-end tests

Drive the Flutter web build in headless Chromium (Playwright) against the Supabase
project, signed in as the test members `tmyp.test.a@example.com` / `tmyp.test.b@example.com`.

```bash
flutter build web --dart-define-from-file=.env --no-web-resources-cdn
(cd build/web && python3 -m http.server 8088 &)
node e2e/flow.js <output-dir> <file-with-test-password> a_requests   # A sends a contact request
node e2e/flow.js <output-dir> <file-with-test-password> b_accepts    # B accepts it
node e2e/flow.js <output-dir> <file-with-test-password> a_reveals    # A sees B's phone/WhatsApp
```

Screenshots for each step are written to `<output-dir>/<step>/`. The test password is not
stored in the repo. Phase 1 turns these into CI-run tests.
