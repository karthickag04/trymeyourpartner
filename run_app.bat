@echo off
rem Runs the app in Chrome. Keys are read from .env (copy .env.example to .env first).
cd /d "%~dp0"
flutter run -d chrome --dart-define-from-file=.env
pause
