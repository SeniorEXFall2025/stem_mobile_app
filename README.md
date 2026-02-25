# STEM Ecosystem Mobile Application

## Overview
The STEM Ecosystem Mobile Application is a cross-platform, location-aware mobile app designed to connect students and educators with relevant STEM events, mentors, and organizations across Colorado. The app provides personalized content based on user interests and location, with real-time updates and push notifications.



<p align="center">
  <img src="screenshots/Login Page.png" width="250"/>
  <img src="screenshots/Profile Preferences Page.png" width="250"/>
  <img src="screenshots/Home Page.png" width="250"/>
</p>

### Login Page  
Secure authentication entry point for users.

### Profile Preferences  
Users can configure interests and preferences that influence the events shown in their feed.

### Home Page (Event Feed)  
The home page displays events in a feed-style layout.  
Each event card includes title, date, location, and STEM topic tags.  
The feed dynamically updates based on filtering and distance preferences.

# Event Interaction

<p align="center">
  <img src="screenshots/Event Details Page.png" width="250"/>
  <img src="screenshots/Favorites Page.png" width="250"/>
  <img src="screenshots/Favorites Page Registered.png" width="250"/>
</p>

### Event Details Page  
Displays detailed information about a selected event, including description and location.

### Favorites Page  
Shows events the user has favorited and saved.

### Registered Event View  
Demonstrates how an event appears once the user has registered for it.

# Map Features

<p align="center">
  <img src="screenshots/Maps Page Event View.png" width="280"/>
  <img src="screenshots/MapsPageEventDirectionsDemo.gif" width="280"/>
</p>

### Maps Page – Event View  
Introduces the map interface where events appear as interactive markers.

### Directions Demo  
Demonstrates navigation functionality and how users can access directions for events.


# Distance Filtering

<p align="center">
  <img src="screenshots/Maps Page 10mile View.png" width="250"/>
  <img src="screenshots/Maps Page 15mile View.png" width="250"/>
  <img src="screenshots/EventDistanceSlider.gif" width="250"/>
</p>

### Distance Radius Filtering  
The distance slider dynamically filters events by proximity.  
Adjusting the slider updates both:
- The map markers
- The home page event feed  

This ensures location-based discovery remains intuitive and responsive.

# Mentor Demo

## Create Event Workflow

<p align="center">
  <img src="screenshots/CreateEventPageDemo.gif" width="280"/>
  <img src="screenshots/Create Event Result Maps Page.png" width="280"/>
</p>

**Create Event Demo:**  
This demonstrates the mentor/admin event creation flow.  
After creating an event, it immediately appears on the map and feed as shown in the result preview.

# Settings

<p align="center">
  <img src="screenshots/Settings Page.png" width="280"/>
  <img src="screenshots/Settings Page Dark Mode.png" width="280"/>
</p>

### Settings Page  
Users can manage preferences and app configurations.

### Dark Mode  
Demonstrates full dark mode support for improved accessibility and user experience.
- Favorites and event registration tracking
- Light/Dark mode theming


## Technologies Used
- Flutter (cross-platform mobile development)
- Firebase Authentication
- Firebase Firestore (NoSQL database)
- Firebase Cloud Messaging (push notifications)
- Google Maps API
- Jira (Agile project management)
- Git/GitHub (version control)

## Key Features
- Role-based access control for students and mentors
- Personalized onboarding with interest and location selection
- Real-time event feed backed by Firestore
- Push notifications for nearby or interest-matched events
- Google Maps integration for event locations

## Team
Team Honey Badgers – Senior Capstone Project  
Metropolitan State University of Denver
