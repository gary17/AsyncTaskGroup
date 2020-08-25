# AsyncTaskGroup

## Purpose

This repository is meant as an educational resource on the subject of using software design patterns in iOS apps written in Swift.

## Problem

Updating mobile app UI with data available over the network often requires performing multiple steps, not only for data acquisition (thus connecting to potentially multiple JSON API endpoints to download data), but also for UI operations (displaying an activity indicator, showing download progress of large data chunks, hiding the activity indicator, updating app UI with downloaded data, etc.) All such steps have to occur synchronously (in a predictable order), but some of those steps might be asynchronous in nature (e.g., a network request over `URLSession`). Moreover, in iOS, any lengthy operation has to be performed on a background thread in order not to block the main UI thread, keeping the app UI responsive. Finally, a group of steps must be cancelable, in order for an app to be able to allow a user to abandon one particular screen and move on to another.

## Solution

AsyncTaskGroup is a small, sample utility library based on Swift Grand Central Dispatch (GCD) that allows for synchronous execution of a group of asynchronous tasks with cancellation capability.

## Components

|         | File | Purpose |
----------|------|----------
:octocat: | [AsyncTaskGroup.swift](AsyncTaskGroup.playground/Sources/AsyncTaskGroup.swift) | a sample utility library for synchronous execution of a group of asynchronous tasks
:octocat: | [Contents.swift](AsyncTaskGroup.playground/Contents.swift) | a sample Xcode playground with usage samples
