# 🛡️ AEGIS — Crisis Intelligence & Disaster Management Platform

AEGIS is a premium, state-of-the-art emergency response and real-time disaster management application. Designed for safety monitoring, threat prediction, and crisis communication, AEGIS integrates Gemini 2.5 Flash cognitive AI systems, real-time satellite updates, automated localized alerts, geocoding maps, and responsive sequential SOS systems to safeguard human lives.

Developed by the **NextGen Coders** team.

---

## 🌟 Key Features

* **🤖 Cognitive AI Assistant**: Powered by **Gemini 2.5 Flash** with custom emergency system prompts, providing real-time triage guidelines, localized preparedness plans, first aid procedures, and weather/hazard threat assessments.
* **🆘 1-Tap Sequential SOS System**: Fully automated crisis broadcast that transmits live coordinates, addresses, and maps links via WhatsApp or SMS to all emergency contacts simultaneously, and immediately triggers an auto-dialer for immediate response.
* **📍 Safe Zone Maps & Radar**: Real-time integration of safety coordinates, marking active rescue stations, medical shelters, and localized safe havens with one-tap location sharing.
* **📡 AEGIS Satellite Sync Notifications**: Collapsible emergency broadcast simulator and periodic automated live reports synchronized with regional weather satellites.
* **✨ Premium Futuristic Interface**: Built with fluid animations, glowing glassmorphic elements, HSL curated neon accent color palettes, and a premium dark mode layout.

---

## 🛠️ Technology Stack

* **Core**: [Flutter](https://flutter.dev) (Dart SDK `^3.11.5`)
* **State Management**: `provider`
* **Routing**: `go_router`
* **AI Cognitive Systems**: `google_generative_ai` (Gemini 2.5 Flash)
* **Local & GPS Services**: `geolocator`, `geocoding`
* **Mapping**: `google_maps_flutter`
* **Data Layer & Authentication**: `supabase_flutter`
* **Communication & Media Links**: `url_launcher`, `share_plus`
* **Visual Polish**: `flutter_animate`, `shimmer`, `google_fonts`

---

## 🚀 Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your system.
* Android Studio / Xcode configured for Android and iOS execution.
* A valid Gemini API Key and Supabase project initialized.

### Setup Instructions

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/muhammad-umar-studio/disaster_management_app.git
   cd disaster_management_app
   ```

2. **Retrieve Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure API Keys**:
   Create or update API keys inside the `lib/core/services/api_keys.dart` config file:
   ```dart
   class ApiKeys {
     static const String gemini = 'YOUR_GEMINI_API_KEY';
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   }
   ```

4. **Run the Application**:
   ```bash
   flutter run
   ```

5. **Build the Production APK**:
   ```bash
   flutter build apk --release
   ```

---

## 🎨 Brand Design & Assets
AEGIS uses the sleek shield icon assets located at `assets/images/logo.png`. Native launcher icons are managed and generated using `flutter_launcher_icons` and auto-generated across all Android/iOS density scales.

---

## 👥 Developed By
Developed with passion and commitment by the **NextGen Coders** team.
