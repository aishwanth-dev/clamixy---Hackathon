# Stardust Soul - AI Wellness Companion Architecture

## Overview
Stardust Soul is a holistic AI wellness companion designed for youth, featuring empathetic chat, unique "Emotion Galaxy" visual mood tracking, gamified challenges, and comprehensive progress tracking.

## Core Features & Implementation Plan

### 1. AI Chat Companion (Core)
- **Tech**: OpenAI GPT-4o integration with specialized wellness prompting
- **Roles**: Three distinct AI personas (Listener 🌸, Motivator ⚡, Coach 🎯)
- **Features**: 
  - Daily check-ins with contextual mood detection
  - Integrated coping techniques (breathing exercises, affirmations, journaling prompts)
  - Crisis detection with helpline resources for Indian context
  - Conversation history with mood insights

### 2. Emotion Galaxy (Memory System) 🌌  
- **Tech**: Custom Canvas painting with animation
- **Concept**: Personal galaxy where each day adds a colored star based on mood
  - Happy = Golden star with sparkle animation
  - Sad = Blue star with gentle pulse  
  - Angry = Red star with intensity flicker
  - Calm = Soft white/purple glowing star
  - Anxious = Orange/yellow flickering star
- **Features**:
  - Interactive star tapping reveals AI-generated reflection from that day
  - Galaxy grows over time with smooth transitions
  - Weekly/monthly galaxy zoom levels

### 3. Wellness Challenges + Gamification 🎮
- **Tech**: Local storage for progress, OpenAI for challenge generation
- **System**: 
  - Weekly AI-generated personalized wellness challenges
  - Point system with streak multipliers
  - Unlockable rewards (motivational content, new star effects)
  - Achievement badges with meaningful titles
- **Challenges Examples**:
  - "Complete 3 gratitude reflections this week"
  - "Try 2 breathing sessions daily"
  - "Write a daily 2-line poem about your day"

### 4. Progress Tracker 📈
- **Tech**: Chart visualization with local data storage
- **Dashboard Elements**:
  - Mood trend graphs (7-day, 30-day views)
  - Streak counters and challenge completion rates
  - Galaxy expansion metrics (total stars, mood distribution)
  - Wellness milestone celebrations

## Technical Architecture

### Data Models
- **MoodEntry**: date, emotion, intensity, note, aiReflection
- **ChatMessage**: content, role, timestamp, moodContext
- **Challenge**: id, title, description, points, deadline, completed
- **UserProgress**: streaks, totalPoints, unlockedRewards, galaxyStats

### File Structure (10 files total)
1. **main.dart** - App entry point with routing
2. **home_page.dart** - Main dashboard with navigation
3. **chat_page.dart** - AI companion interface  
4. **galaxy_page.dart** - Emotion galaxy visualization
5. **challenges_page.dart** - Wellness challenges and progress
6. **progress_page.dart** - Analytics and insights dashboard
7. **models.dart** - Data models and structures
8. **services.dart** - Local storage and data management
9. **openai/openai_config.dart** - AI integration
10. **components.dart** - Reusable UI widgets

### Key Technologies
- **AI**: OpenAI GPT-4o for empathetic conversations and content generation
- **Storage**: SharedPreferences for local data persistence
- **UI**: Custom animations with Hero transitions and smooth Canvas painting
- **Charts**: Basic chart widgets for progress visualization

### Design Philosophy
- **Youth-focused**: Vibrant but calming color palette with space/galaxy theme
- **Gamified wellness**: Make mental health engaging without trivializing it
- **Cultural sensitivity**: Indian context for crisis resources and cultural references
- **Privacy-first**: All sensitive data stored locally, only anonymous interactions with AI

## Implementation Priority
1. Basic navigation and UI structure
2. AI chat integration with role-based personas
3. Mood tracking and local storage
4. Emotion galaxy visualization
5. Challenges system and gamification
6. Progress tracking and insights
7. Polish, animations, and crisis detection

## Success Metrics
- Daily active users engaging with chat
- Mood tracking consistency (7+ days/month)
- Challenge completion rates
- Galaxy growth (emotional data collection)
- User retention and wellness improvement trends