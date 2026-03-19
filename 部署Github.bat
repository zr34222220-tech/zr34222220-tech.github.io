@echo off
cd .\public
git add .
git commit -m "deploy"
git config user.name
git config user.email
git push origin main
echo Success deploy
pause
