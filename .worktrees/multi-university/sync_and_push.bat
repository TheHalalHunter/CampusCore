@echo off
git stash
git fetch origin
git reset --hard origin/main
git stash pop
git add .
git commit -m "fix: community answer sort, AgentRouter Claude AI config"
git push origin main
