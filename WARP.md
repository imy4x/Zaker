# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Zaker is a Flutter-based educational application that helps students summarize PDF files, extract text from images, and create flashcards and quizzes using AI. The app supports both Arabic and English content and is designed specifically for Arabic users (RTL layout).

**Key Features:**
- PDF and image text extraction 
- AI-powered content summarization with configurable depth levels
- Flashcard generation for memorization
- Quiz creation with difficulty levels
- Study session management with lists/categories
- Daily usage limits and API key rotation
- Local storage with SharedPreferences

## Common Development Commands

### Build and Run
```bash
# Get dependencies
flutter pub get

# Run on connected device
flutter run

# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release

# Clean build cache
flutter clean
```

### Testing and Analysis
```bash
# Run all tests
flutter test

# Run static analysis
flutter analyze

# Format code
dart format lib/ test/
```

### Development Tools
```bash
# Run a single test file
flutter test test/widget_test.dart

# Hot reload during development (in debug mode)
# Press 'r' in terminal or use IDE hot reload

# Generate launcher icons
flutter packages pub run flutter_launcher_icons:main
```

## Architecture Overview

### State Management
- **Provider Pattern**: Uses `provider` package for state management
- **StudyProvider**: Central state controller managing sessions, lists, and API interactions
- **AppState enum**: Tracks loading states (idle, loading, success, error)

### Core Services Architecture
```
lib/
├── providers/study_provider.dart     # Main state management
├── api/gemini_service.dart          # AI integration with API key rotation
├── services/
│   ├── text_extraction_service.dart # PDF/image text extraction
│   ├── storage_service.dart         # Local data persistence
│   └── usage_service.dart           # Daily usage tracking
└── models/                          # Data models (StudySession, Flashcard, etc.)
```

### AI Integration
- **Google Generative AI (Gemini)**: Primary AI service for content analysis
- **API Key Rotation**: Automatic failover between multiple API keys
- **Model Selection**: Uses gemini-2.5-pro for complex tasks, gemini-2.5-flash for simple ones
- **Content Validation**: AI validates if uploaded content is educational before processing

### Text Extraction Pipeline
1. **Multi-format Support**: PDF (Syncfusion), Images (Gemini Vision)
2. **Batch Processing**: Handles multiple files in single session
3. **Text Validation**: Ensures extracted content is meaningful
4. **Usage Tracking**: Counts processed files against daily limits

### Data Models
- **StudySession**: Contains summary, flashcards, quiz questions, and metadata
- **StudyList**: Organizational containers for grouping sessions
- **Flashcard**: Question-answer pairs for memorization
- **QuizQuestion**: Multiple-choice questions with difficulty levels

## Configuration Requirements

### API Keys Setup
Edit `lib/constants/api_keys.dart`:
- Add valid Gemini API keys to `geminiApiKeys` array
- Configure Supabase credentials if using cloud storage
- **Security Note**: Keep API keys out of version control in production

### Analysis Depth Levels
- **Deep**: University-level explanations with examples and analogies
- **Medium**: Balanced analysis with core concepts
- **Light**: Quick summaries focusing on key points

### Usage Limits
Default daily limits are enforced to prevent API quota exhaustion. Modify in `usage_service.dart`.

## Development Guidelines

### Localization
- App uses Arabic as primary language (RTL layout)
- English content support for international materials
- All UI text should be in Arabic
- Use `Directionality(textDirection: TextDirection.rtl)` wrapper

### Error Handling
- Implement comprehensive try-catch blocks for AI API calls
- Provide Arabic error messages to users
- Use API key rotation for quota-exceeded errors
- Validate content before expensive AI operations

### File Processing
- Support PDF and image formats (JPG, PNG, WebP)
- Implement progress tracking for multi-step operations
- Validate file content before AI processing
- Handle large files appropriately

### UI Patterns
- Use ExpansionTiles for collapsible content sections
- Implement FloatingActionButtons for primary actions
- Show loading states during AI processing
- Use cards for grouped content display

## Testing Strategy

- Widget tests for UI components
- Unit tests for service classes
- Integration tests for AI service with mock responses
- Test file processing with sample PDFs and images

## Platform-Specific Notes

### Android
- MinSDK: Check `android/app/build.gradle` 
- Uses Kotlin Gradle files (.kts)
- Requires file access permissions for PDF reading

### iOS
- Configure Info.plist for file access permissions
- Test thoroughly on different iOS versions

### Windows/Linux/macOS
- Desktop support available through Flutter's desktop implementations
- File picker behavior may vary across platforms