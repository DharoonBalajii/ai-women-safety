<div align="center">

# 🚨 RAKSHA THUNAI
### Next-Gen AI Women’s Safety & Real-Time Emergency Response System
**Built with ❤️ for rapid emergency response by Team Cruise CTRL**

> *“One trigger. One voice. One intelligent, life-saving response.”*

<br/>

[![Status: Active Emergency Grid](https://img.shields.io/badge/EMERGENCY_GRID-LIVE_ACTIVE-dc2626?style=for-the-badge&logo=shield&logoColor=white)](https://github.com)
[![Sarvam AI: 23 Indic Languages](https://img.shields.io/badge/SARVAM_AI-23_INDIC_LANGUAGES_%2B_CODE_SWITCH-6366f1?style=for-the-badge&logo=openai&logoColor=white)](https://sarvam.ai)
[![Team: Cruise CTRL](https://img.shields.io/badge/TEAM-CRUISE_CTRL-0ea5e9?style=for-the-badge&logo=github&logoColor=white)](https://github.com)
[![Flutter: Android & iOS](https://img.shields.io/badge/MOBILE-FLUTTER_3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase: Realtime Sync](https://img.shields.io/badge/DATABASE-SUPABASE_REALTIME-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Clerk: Identity & Auth](https://img.shields.io/badge/SECURITY-CLERK_AUTH-6C47FF?style=for-the-badge&logo=clerk&logoColor=white)](https://clerk.com)
[![MSG91: Emergency SMS/OTP](https://img.shields.io/badge/DISPATCH-MSG91_TELEPHONY-FF5722?style=for-the-badge&logo=twilio&logoColor=white)](https://msg91.com)

<br/>

**[📱 Mobile App](#-mobile-application-flutter)** •
**[🧠 Sarvam AI Engine](#-powered-by-sarvam-ai--real-time-code-switching)** •
**[🚔 Responder CAD](#-emergency-responder-web-cad-dashboard)** •
**[🏗️ Architecture](#️-system-architecture)** •
**[🚀 Quickstart](#-getting-started)**

---

</div>

<br/>

## 🌟 Executive Summary & Technical Innovation

In acute emergency scenarios involving physical restraint, stalking, or imminent threat, **seconds dictate survival**. Conventional emergency frameworks depend on multi-step manual interactions—unlocking handsets, launching standalone apps, typing distress texts, and articulating coordinates—an assumption that fails during active duress or acute panic.

**Raksha Thunai** eliminates this critical latency through an autonomous, voice-activated emergency response grid powered by **Sarvam AI**. By pairing zero-touch hardware gestures with Indic speech-to-intent intelligence, the system converts raw ambient acoustics into real-time threat scores, forensic transcripts, and automated law-enforcement dispatch.

### ⚖️ Architectural Paradigm Shift

| Evaluation Dimension | Conventional Emergency Solutions | Raksha Thunai Autonomous AI Grid |
| :--- | :--- | :--- |
| **Trigger Accessibility** | Multi-touch UI navigation requiring full visual attention and unlocked screens | **Zero-Friction Gesture**: Silent triple-press power button or one-tap lockscreen widget |
| **Linguistic Processing** | Rigid monolingual ASR; fails on panic inflections, shouting, or code-mixing | **23 Indic Languages + Code-Switching**: Real-time parsing of Hinglish, Tamil+Hindi, and Tanglish |
| **Distress Intelligence** | None; dumb audio recordings without automated threat extraction | **Sarvam AI Acoustic NLP**: Sub-second threat scoring (0–100), intent extraction & sentiment analysis |
| **Triage & Dispatch** | Sequential manual phone calls resulting in 3–5 minute triage bottlenecks | **Sub-Second Concurrent Broadcast**: Automated CAD dispatch + encrypted SMS tracking via MSG91 |
| **Network Resilience** | Total failure upon cellular data disconnection | **Hybrid Fail-Safe**: On-device heuristic classifier with SMS bearer fallback |

---

## 🧠 Powered by Sarvam AI & Real-Time Code-Switching

In high-stress situations, **victims never speak in textbook sentences**. They panic, scream, whisper, and naturally mix multiple languages (*code-switching*). 

**Raksha Thunai** leverages **Sarvam AI's Saarika v2 speech-to-text models and acoustic NLP** to understand dialectal code-switches like **English + Hindi (Hinglish)**, **Tamil + Hindi**, **Tamil + English (Tanglish)**, and **23 official Indian languages** with acoustic distress sentiment extraction.

### Multi-Language & Code-Switching Live Inference Showcase

<table>
<tr>
<th width="45%">🗣️ Overheard / Spoken Audio</th>
<th width="10%">➡️</th>
<th width="45%">🧠 Structured Intelligence Output</th>
</tr>

<tr>
<td>

**Code-Switch: English + Hindi (Hinglish)**  
> *"Someone is following me, mujhe bahut dar lag raha hai! Please help!"*

</td>
<td align="center">⚡</td>
<td>

```json
{
  "threatLevel": "CRITICAL",
  "score": 99,
  "category": "Active Pursuit & Stalking",
  "languageMode": "Code-Switch (English + Hindi)",
  "sentiment": "ACUTE_PANIC_AND_DANGER",
  "flaggedTokens": ["following me", "mujhe bahut dar lag raha hai", "help"],
  "dispatchProtocol": "AUTO_PRIORITY_1_DISPATCH"
}
```

</td>
</tr>

<tr>
<td>

**Code-Switch: Tamil + Hindi**  
> *"என்னை காப்பாத்துங்க, koi yahan mere room ka door break kar raha hai!"*

</td>
<td align="center">⚡</td>
<td>

```json
{
  "threatLevel": "CRITICAL",
  "score": 98,
  "category": "Violent Intrusion / Physical Threat",
  "languageMode": "Code-Switch (Tamil + Hindi)",
  "flaggedTokens": ["காப்பாத்துங்க (save me)", "door break", "room"],
  "dispatchProtocol": "AUTO_SILENT_SOS_TRIGGERED"
}
```

</td>
</tr>

<tr>
<td>

**Tamil (தமிழ்):**  
> *"நான் ஒரு அறையில் பூட்டப்பட்டிருக்கிறேன், காப்பாத்துங்க!"*

</td>
<td align="center">⚡</td>
<td>

```json
{
  "threatLevel": "CRITICAL",
  "score": 98,
  "category": "Forcible Confinement / Unlawful Entrapment",
  "languageMode": "Tamil (தமிழ்)",
  "flaggedTokens": ["பூட்டப்பட்டிருக்கிறேன் (locked)", "அறையில் (room)"],
  "dispatchProtocol": "AUTO_SILENT_SOS_TRIGGERED"
}
```

</td>
</tr>

<tr>
<td>

**Bengali (বাংলা):**  
> *"আমাকে একটা ঘরে আটকে রাখা হয়েছে, বাঁচাও!"*

</td>
<td align="center">⚡</td>
<td>

```json
{
  "threatLevel": "CRITICAL",
  "score": 98,
  "category": "Forcible Confinement / Unlawful Entrapment",
  "languageMode": "Bengali (বাংলা)",
  "flaggedTokens": ["ঘরে (room)", "আটকে (confined)", "বাঁচাও (save)"]
}
```

</td>
</tr>

<tr>
<td>

**Urdu (اردو):**  
> *"کوئی میرا پیچھا کر رہا ہے، بچاؤ!"*

</td>
<td align="center">⚡</td>
<td>

```json
{
  "threatLevel": "CRITICAL",
  "score": 98,
  "category": "Extreme Distress / Pursuit Stalking",
  "languageMode": "Urdu (اردو)",
  "flaggedTokens": ["پیچھا (chasing)", "کوئی (someone)"],
  "dispatchProtocol": "AUTO_SILENT_SOS_TRIGGERED"
}
```

</td>
</tr>
</table>

---

## ⚡ Key Capabilities & Feature Matrix

| Feature | Description | Status |
| :--- | :--- | :---: |
| ⚡ **One-Tap / Hardware SOS** | Trigger silent alerts via lock-button triple tap, volume gestures, or lockscreen widget. | ![Active](https://img.shields.io/badge/STATUS-ACTIVE-brightgreen?style=flat-square) |
| 🗣️ **23 Indic Languages** | Native transcription & intent extraction across 23 Indian languages + dialectal transliterations. | ![Active](https://img.shields.io/badge/STATUS-ACTIVE-brightgreen?style=flat-square) |
| 🔄 **Code-Switching Support** | Seamless real-time understanding of mixed speech: English+Hindi, Tamil+Hindi, Tanglish & Hinglish. | ![Active](https://img.shields.io/badge/STATUS-ACTIVE-brightgreen?style=flat-square) |
| 🛡️ **Cross-Semantic Matrix** | Dual-tier spatial-restraint correlation detecting confinement & pursuit even across dialect variations. | ![Active](https://img.shields.io/badge/STATUS-ACTIVE-brightgreen?style=flat-square) |
| 📍 **Live GPS & Drift Tracking** | Continuous sub-5m GPS telemetry with real-time speed, heading, and dead-reckoning support. | ![Active](https://img.shields.io/badge/STATUS-ACTIVE-brightgreen?style=flat-square) |
| 🚔 **Responder CAD Grid** | High-contrast situational awareness dashboard for police & rapid-response patrol teams. | ![Active](https://img.shields.io/badge/STATUS-ACTIVE-brightgreen?style=flat-square) |
| 👥 **MSG91 Dual-Channel Blast** | Immediate SMS dispatch with one-click live tracking web links for family and trusted contacts. | ![Active](https://img.shields.io/badge/STATUS-ACTIVE-brightgreen?style=flat-square) |
| ⏱️ **Active Transit Check-In** | Automated countdown timer for late-night commutes; escalates to CRITICAL if check-in is missed. | ![Active](https://img.shields.io/badge/STATUS-ACTIVE-brightgreen?style=flat-square) |
| 🔒 **Tamper-Proof Audit Store** | Cryptographically signed telemetry and threat logs persisted on Supabase PostgreSQL. | ![Active](https://img.shields.io/badge/STATUS-ACTIVE-brightgreen?style=flat-square) |

---

## 🏗️ System Architecture

```mermaid
flowchart TD
    classDef client fill:#1e293b,stroke:#38bdf8,stroke-width:2px,color:#f8fafc;
    classDef ai fill:#31104b,stroke:#a855f7,stroke-width:2px,color:#f8fafc;
    classDef backend fill:#064e3b,stroke:#34d399,stroke-width:2px,color:#f8fafc;
    classDef dispatch fill:#450a0a,stroke:#f87171,stroke-width:2px,color:#f8fafc;

    subgraph S1 ["1. Client & Sensor Ingestion (Flutter App)"]
        A["🚨 Hardware Gesture / One-Tap Widget"] --> B["📱 Flutter Client Engine"]
        B --> C["📍 High-Precision GPS Telemetry"]
        B --> D["🎙️ Background Audio Streamer"]
        B -.-> E["🔐 Clerk Auth & MSG91 2FA"]
    end

    subgraph S2 ["2. Sarvam AI Intelligence & Code-Switch Layer"]
        D --> F["🧠 Sarvam AI Saarika v2 STT"]
        F --> G["🔄 23 Languages & Code-Switch Engine\n(English+Hindi, Tamil+Hindi, Tanglish)"]
        G --> H["🔍 Damerau-Levenshtein Fuzzy Lexicon"]
        H --> I["🛡️ Cross-Language Threat Matrix\n(Confinement vs. Pursuit Scoring)"]
        D -.->|Offline Fallback| J["⚡ On-Device Heuristic Engine"]
        J --> I
    end

    subgraph S3 ["3. Realtime Cloud Backend (Supabase)"]
        C --> K["☁️ Supabase Realtime Incident Gateway"]
        I -->|Threat Score >= 75| K
        K --> L["🗺️ PostGIS Geofencing & Spatial Routing"]
        K --> M["💾 Encrypted Incident Audio & Event Ledger"]
    end

    subgraph S4 ["4. Emergency Dual-Channel Dispatch"]
        L --> N["🚔 Responder CAD Web Dashboard (React + Vite)"]
        M --> O["👥 Trusted Contacts Blast (MSG91 SMS + Live Map)"]
        N --> P["🚨 Automated First-Responder Patrol Intercept"]
    end

    class A,B,C,D,E client;
    class F,G,H,I,J ai;
    class K,L,M backend;
    class N,O,P dispatch;
```

---

## 📱 Mobile Application (Flutter)

Crafted with **Flutter** for instant startup, native platform channel bindings, and background audio persistence:

```
apps/mobile_app/
├── lib/
│   ├── core/
│   │   ├── audio/           # Background microphone & audio streaming
│   │   ├── location/        # High-accuracy GPS telemetry & geofencing
│   │   └── security/        # Clerk token cache & biometric checks
│   ├── features/
│   │   ├── sos/             # One-tap panic trigger & transit safety timer
│   │   ├── incidents/       # Real-time incident timeline & updates
│   │   └── contacts/        # Trusted contacts management
│   └── main.dart
```

### Hardware Trigger Setup
- **Power Button Triple-Click**: Registered via Android Accessibility Service / iOS Accessibility Shortcuts.
- **Volume Rocker Long-Press**: Configurable threshold for silent activation inside bags or pockets.

---

## 🚔 Emergency Responder Web CAD Dashboard

For dispatchers and patrol units, a dedicated high-contrast dashboard built with **React + Vite** provides instant situational awareness:

```
website demo/
├── src/
│   ├── components/
│   │   ├── AudioMonitor.jsx       # Real-time audio waveform visualizer
│   │   ├── ThreatGauge.jsx        # SVG radial threat gauge (0-100)
│   │   ├── EmergencyBanner.jsx    # Audio siren alarm & protocol abort
│   │   ├── TranscriptFeed.jsx     # Multilingual live stream & SOS overrides
│   │   └── IntelligenceReport.jsx # Forensic AI rationale breakdown
│   ├── services/
│   │   ├── sarvamService.js       # 23-Language & Code-Switching Engine
│   │   └── audioEngine.js         # Web Audio API visualizer & synth
│   └── App.jsx
```

---

## 🛠️ Technology Stack Breakdown

<div align="center">

| Domain | Technology | Purpose |
| :--- | :--- | :--- |
| **Mobile Core** | ![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white) | Cross-platform client for iOS & Android |
| **AI Intelligence** | ![Sarvam AI](https://img.shields.io/badge/Sarvam_AI-6366f1?logo=openai&logoColor=white) | Indic STT (23 Languages), Code-Switching & Acoustic Threat NLP |
| **Auth & Identity** | ![Clerk](https://img.shields.io/badge/Clerk-6C47FF?logo=clerk&logoColor=white) | Secure user authentication and session management |
| **Telephony / SMS** | ![MSG91](https://img.shields.io/badge/MSG91-FF5722?logo=twilio&logoColor=white) | Instant transactional emergency SMS & OTP |
| **Database & Realtime** | ![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?logo=supabase&logoColor=white) | PostgreSQL, Realtime WebSocket sync & PostGIS spatial queries |
| **Responder Web** | ![React](https://img.shields.io/badge/React_18-61DAFB?logo=react&logoColor=black) ![Vite](https://img.shields.io/badge/Vite_8-646CFF?logo=vite&logoColor=white) | High-speed dispatcher CAD dashboard |
| **Styling** | ![CSS3](https://img.shields.io/badge/Vanilla_CSS3-1572B6?logo=css3&logoColor=white) | High-contrast glassmorphic design system |

</div>

---

## 🚀 Getting Started

### Prerequisites
- **Node.js**: v18.0 or higher
- **Flutter SDK**: v3.16+ (for mobile app)
- **Supabase Account** & API Keys
- **Sarvam AI Subscription Key**

---

### 1. Responder Web Dashboard (React + Vite)

```bash
# Clone the repository
git clone https://github.com/Cruise-CTRL/raksha-thunai.git
cd "raksha-thunai/website demo"

# Install dependencies
npm install

# Configure environment variables
cp .env.example .env

# Launch development server
npm run dev
```

Visit `http://localhost:5173` to view the live dashboard.

---

### 2. Mobile Application (Flutter)

```bash
cd apps/mobile_app

# Fetch Flutter dependencies
flutter pub get

# Run on connected Android / iOS device
flutter run
```

---

## 🧪 Comprehensive Multilingual Verification

To ensure universal reliability across all 23 Indian languages and mixed code-switching scenarios, an automated regression test suite runs on every build:

```bash
node test_all_languages.mjs
```

---

## 🔒 Privacy, Ethics & Security

- **Zero Ambient Eavesdropping**: Continuous recording only activates when the SOS trigger is armed, or via periodic local acoustic sampling that never uploads unless distress is flagged.
- **End-to-End Location Encryption**: Live coordinates are transmitted through encrypted WebSockets directly to authorized contacts and certified response nodes.
- **Law-Enforcement Protocols**: Built in compliance with international emergency dispatch (E911/112) telemetry standards.

---

<div align="center">

### 🚨 Raksha Thunai — Built for Safety by Team Cruise CTRL
*Powered by Sarvam AI for Women's Safety & Rapid Emergency Response across India.*

</div>
