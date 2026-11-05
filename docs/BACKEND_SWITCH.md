Backend switch guide

- BACKEND_MODE dart-define controls runtime implementation: 'supabase' (default) or 'http'.
- Service interfaces live in lib/core/services/.
- Supabase implementations live in lib/data/supabase/.
- HTTP stubs live in lib/data/http/.
- DI service locator: lib/app/di/service_locator.dart

HTTP endpoints expected (stubs):
- POST   /auth/login
- POST   /auth/logout
- POST   /auth/signup
- GET    /profiles/me
- GET    /profiles/{id}
- PUT    /profiles/me
- POST   /profiles/{id}/contact
- GET    /matches/suggestions
- GET    /matches/mutual
- POST   /messages/send
- GET    /messages/{conversationId}
- GET    /notifications
- POST   /storage/upload
- DELETE /storage/delete

Build examples:
- flutter run -d chrome --dart-define=BACKEND_MODE=supabase
- flutter run -d chrome --dart-define=BACKEND_MODE=http --dart-define=API_BASE_URL=http://localhost:8080
