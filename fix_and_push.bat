@echo off
git fetch origin
git reset --hard origin/main
git add mobile_app/lib/presentation/screens/community/question_detail_screen.dart
git add backend/src/modules/ai/ai.service.ts
git add backend/.env.example
git add mobile_app/lib/presentation/providers/ai_provider.dart
git add mobile_app/lib/presentation/screens/ai_assistant/ai_assistant_screen.dart
git commit -m "fix: community answer sort crash, AgentRouter Claude AI setup"
git push origin main
