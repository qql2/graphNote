@echo off
echo Building web assets...
cd assets/web
call npm run build
cd ../..

echo Building Windows application...
flutter build windows --release