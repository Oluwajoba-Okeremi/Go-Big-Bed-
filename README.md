Go Big Bed
Overview

Go Big Bed is an iOS application that quantifies and improves sleep behavior through direct HealthKit integration. 
It tracks verified sleep data, assigns point-based rewards, and cycles milestone progress through an automatic credit system. 
The application operates autonomously using motion sensing and Health permissions.

Core Functionality

The app integrates with Apple HealthKit to record and read sleep samples. 
It analyzes accelerometer and motion data to identify actual sleep intervals. Users receive points for every hour of verified sleep. 
Milestone progress advances in repeating cycles, granting credits upon each completion. 
The system ignores external Health sources, processing only data written by Go Big Bed. All results are stored locally within the HealthKit framework and app sandbox.

Technical Stack

The project is written in Swift using SwiftUI and Combine, with minimal UIKit dependencies. 
It requires iOS 17.0 or later and is developed in Xcode. 
The HealthKit framework provides sleep and motion data access. 
No third-party analytics or telemetry libraries are included.

Architecture

HealthKitManager.swift manages authorization, queries, and sample writes to HealthKit. 
RewardManager.swift calculates sleep-based points and total values. 
RewardsView.swift displays milestone progress and credit accumulation. 
AppState.swift connects HealthKit logic to SwiftUI views. 
Theme.swift defines static color constants for visual consistency.

Data Policy

All collected data remains local. 
The app stores no external user information and transmits nothing to servers. 
Health data is accessed only with user consent and written exclusively under the Go Big Bed source identifier.

Setup
Either Download the App in the App Store or:
Clone the repository to a local, non-cloud directory. 
Open the .xcodeproj file in Xcode. 
Enable HealthKit capability in Signing & Capabilities. 
Build and run on a physical device with Health permissions granted.

License

MIT License. All rights reserved by the original developer.
