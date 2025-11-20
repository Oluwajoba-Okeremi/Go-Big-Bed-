# Go Big Bed

Start: September 2025 | First public release: Early October 2025  | End: Late October 2025
Built for the Congressional App Challenge

Disclaimer: All private keys, configuration files, and personal HealthKit data have been removed from this repository.

## About

Go Big Bed is an iOS sleep-tracking and motivation app that turns healthy sleep into a point-based game.  
The app connects to Apple Health, tracks sleep duration, converts your last night of sleep into points, and shows how consistent you have been over the past week.

The design goal is simple: make “going big” on sleep feel as rewarding and visible as grinding in a game.

## Lessons Learned

ABOVE ALL: Success in community service means helping 1 person
- A stopwatch alone is not reliable on iOS because the app can be suspended while the screen is locked. Storing the start time and recomputing elapsed time on resume is more robust.
- Motion-based auto-stop reduces cheating and accidental overcounting, but requires tuning motion thresholds to avoid false positives.
- HealthKit requires clear user messaging. The app has to handle denied permissions, no recent sleep data, and the first-run experience where Health data may not exist yet.
- Simple, large numbers and short text are easier for users to process than dense analytics. A single “last night” number plus a weekly total is often enough.

## How It’s Made

Tech used: Swift, SwiftUI, HealthKit, Core Motion, Swift Charts, Xcode

Main components:

- `HealthKitManager`
  - Requests and manages HealthKit permissions for sleep analysis.
  - Reads the last 7 days of sleep from Apple Health and aggregates nightly totals.
  - Supports writing custom sleep samples when using the in-app stopwatch.

- `SleepSessionStore`
  - In-app stopwatch for recording sleep sessions.
  - Persists the start `Date`, reconstructs elapsed time after iOS suspends the app, and enforces a minimum sleep duration before crediting a session.
  - Uses Core Motion to stop the timer when the phone is lifted at wake-up to prevent cheating.

- Rewards and motivation models
  - Convert hours slept last night into a numeric score (for example, 8.2 hours → 82 points).
  - Track cumulative points and basic progress toward milestones.
  - Map last night’s sleep duration into simple states such as “rested” versus “tired” for the Motivation tab.

- SwiftUI views
  - Sleep Data
  - Sleep Tracking
  - Rewards
  - Motivation
  - Instructions

## Features

### Sleep Tracking

- Start and stop a sleep session with a stopwatch-style interface.
- Stores the start time and recomputes elapsed time when the app is reopened, so a locked screen or suspended app does not break tracking.
- Enforces a minimum session length (for example, 30 minutes) before adding the time to points or weekly totals.
- Uses motion detection to auto-stop the timer when the phone moves significantly after sleep.

### Health Integration

- Reads sleep data directly from Apple Health (sleep analysis category).
- Aggregates the last 7 days of sleep into per-night values.
- Uses the “last recorded night of sleep” as the main source of truth for the Motivation and Rewards tabs.

### Rewards System

- Converts last night’s hours slept into points.
- Shows points earned for the most recent night.
- Provides a base for streaks, levels, and other reward mechanics.

### Motivation Tab

- Displays a short motivation quote at the top of the screen.
- "Get Motivated" button allows the user to cycle through dozens of motivational quotes targeted at high schoolers.
- Uses a lion mascot and a simple message such as “He’s Rested! Keep it up!” based on the last recorded night of sleep.

### Sleep Data Visualization

- Line chart of the last 7 nights of sleep using Swift Charts.
- Horizontal guideline indicating target sleep (for example, 8 hours).
- Displays weekly total such as “Hours Slept in The Past 7 Days: 51.9 hrs”.

### Privacy

- All sleep data stays on-device in Apple Health and local storage.
- No external servers or analytics are required.
- Users stay in control of HealthKit permissions.

### UI
- Simple Red and Black

## Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/<your-username>/GoBigBed.git
   cd GoBigBed

It's also available on the App Store!
# Go Big Bed

**SCREENSHOTS**

MOTIVATION VIEW

<img width="293" height="633" alt="IMG_2998" src="https://github.com/user-attachments/assets/991001b5-7f6b-429a-81c1-5580e2b1e990" />


SLEEP VIEW

<img width="293" height="633" alt="IMG_2999" src="https://github.com/user-attachments/assets/7cd3a1ee-84dc-4d8c-8cfe-1fd499695ad6" />
