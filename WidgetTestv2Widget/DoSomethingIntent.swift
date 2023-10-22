//
//  DoSomethingIntent.swift
//  WidgetTestv2
//
//  Created by Chris Golding on 10/12/23.
//

import Foundation
import AppIntents
import WidgetKit
import ActivityKit
import SwiftUI

struct DoSomethingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Do Something"
    
//    @MainActor
    func perform() async throws -> some IntentResult {
        print("Did something")
        var current = UserDefaults.standard.integer(forKey: "value")
        
        current += 1
        
        UserDefaults.standard.set(current, forKey: "value")
        
        WidgetCenter.shared.reloadAllTimelines()
        
        let dateRange = Date.now ... Date.now.addingTimeInterval(TimeInterval(1500))
        
        let widgetAttributes = ContadinoWidgetAttributes()
        let widgetState = ContadinoWidgetAttributes.PomodoroStatus(
            numCompleted: 0,
            numInterrupted: 1,
            estimatedCompletedTime: dateRange,
            progressBarEstimatedCompletionTime: dateRange,
            numOfPomodorosCompletedInSession: 0
        )

        let activityStaleTime = widgetState.estimatedCompletedTime.upperBound.addingTimeInterval(2)

        let activityContent = ActivityContent(
            state: widgetState,
            staleDate: activityStaleTime
        )

        do {
            _ = try Activity<ContadinoWidgetAttributes>.request(
                attributes: widgetAttributes,
                content: activityContent,
                pushType: nil
            )
        } catch {
            print("Error: \(error.localizedDescription)")
            throw error
        }
        
        return .result()
    }
    
}


import ActivityKit
import Foundation

public struct ContadinoWidgetAttributes: ActivityAttributes {
    public typealias PomodoroStatus = ContentState

    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        public var numCompleted: Int
        public var numInterrupted: Int
        public var estimatedCompletedTime: ClosedRange<Date>
        public var progressBarEstimatedCompletionTime: ClosedRange<Date>
        public var numOfPomodorosCompletedInSession: Int

        public init(
            numCompleted: Int,
            numInterrupted: Int,
            estimatedCompletedTime: ClosedRange<Date>,
            progressBarEstimatedCompletionTime: ClosedRange<Date>,
            numOfPomodorosCompletedInSession: Int
        ) {
            self.numCompleted = numCompleted
            self.numInterrupted = numInterrupted
            self.estimatedCompletedTime = estimatedCompletedTime
            self.progressBarEstimatedCompletionTime = progressBarEstimatedCompletionTime
            self.numOfPomodorosCompletedInSession = numOfPomodorosCompletedInSession
        }
    }

    // Fixed non-changing properties about your activity go here!

    public init() {}
}


import ActivityKit
import SwiftUI
import WidgetKit

struct ContadinoWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ContadinoWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            LockScreenLiveActivityView(context: context)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.center) {
                    CountdownSummaryView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {}
                DynamicIslandExpandedRegion(.bottom) {}
            } compactLeading: {
                if context.isStale {
                    ProgressView(value: 1) {} currentValueLabel: {
                        Image(systemName: "checkmark")
                    }
                    .progressViewStyle(.circular)
                    .tint(Color.green)
                } else {
                    ProgressView(
                        timerInterval: context.state.progressBarEstimatedCompletionTime,
                        countsDown: false,
                        label: {},
                        currentValueLabel: {}
                    )
                    .progressViewStyle(.circular)
                    .tint(Color.green)
                }
            } compactTrailing: {
                let completedAtLeastOne = context.state.numOfPomodorosCompletedInSession > 0
                HStack(spacing: 0) {
                    if context.state.numOfPomodorosCompletedInSession > 0 {
                        Text("-")
                    }
                    Text(
                        timerInterval: context.state.estimatedCompletedTime,
                        countsDown: completedAtLeastOne == false
                    )
                    .frame(width: 50)
                    .monospacedDigit()
                }
            } minimal: {
                HStack {
                    if context.isStale {
                        ProgressView(value: 1) {} currentValueLabel: {
                            Image(systemName: "checkmark")
                        }
                        .progressViewStyle(.circular)
                        .tint(Color.green)
                    } else {
                        ProgressView(
                            timerInterval: context.state.progressBarEstimatedCompletionTime,
                            countsDown: false,
                            label: {},
                            currentValueLabel: {
                                Text("C")
                            }
                        )
                        .progressViewStyle(.circular)
                        .tint(Color.green)
                    }
                }
            }
        }
    }
}

import SwiftUI
import WidgetKit

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<ContadinoWidgetAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text("Contadino")
                .font(.headline)
                .padding(.horizontal)
                .padding(.vertical, 6.0)
                .foregroundColor(Color("AccentColor"))
            Divider()
                .overlay(Color("AccentColor"))
                .padding(.bottom, 4)
            CountdownSummaryView(context: context)
        }
        .padding(.bottom)
        .background(Color.black)
    }
}

import ActivityKit
import SwiftUI
import WidgetKit

struct CountdownSummaryView: View {
    let context: ActivityViewContext<ContadinoWidgetAttributes>
    let completedAtLeastOne: Bool

    init(context: ActivityViewContext<ContadinoWidgetAttributes>) {
        self.context = context
        completedAtLeastOne = context.state.numOfPomodorosCompletedInSession > 0
    }

    var body: some View {
        HStack {
            if context.isStale {
                VStack {
                    ProgressView(value: 1) {} currentValueLabel: {
                        Image(systemName: "checkmark")
                    }
                    .progressViewStyle(.circular)
                    .tint(Color.green)

                    Text("Still Running")
                }
                .padding(.leading, 8)
                .padding(.top, 8)
                .frame(maxWidth: .infinity)
            } else {
                ProgressView(
                    timerInterval: context.state.progressBarEstimatedCompletionTime,
                    countsDown: false,
                    label: {},
                    currentValueLabel: {
                        HStack(spacing: 0) {
                            Spacer(minLength: 12)
                            HStack(alignment: .center, spacing: 0) {
                                Text(completedAtLeastOne ? "-" : "")
                                    + Text(
                                        timerInterval: context.state.estimatedCompletedTime,
                                        pauseTime: nil,
                                        countsDown: completedAtLeastOne == false,
                                        showsHours: true
                                    )
                            }
                            .monospacedDigit()
                            .minimumScaleFactor(0.01)
                            Spacer(minLength: 12)
                        }
                        .foregroundColor(Color(uiColor: .label))
                        .font(.title2)
                    }
                )
                .progressViewStyle(.circular)
                .tint(Color.green)
                .frame(maxWidth: .infinity)
            }

            VStack {
                HStack {
                    HStack {
                        Image(systemName: "check")
                            .imageScale(.large)

                        Text("\(context.state.numCompleted + (context.isStale ? 1 : 0))")
                            .font(.title2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(8)
                    .background(.black.opacity(0.80))
                    .cornerRadius(8.0)
                    .foregroundColor(Color.green)

                    HStack {
                        Image(systemName: "x")
                            .imageScale(.large)
                        Text("\(context.state.numInterrupted)")
                            .font(.title3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(8)
                    .background(.black.opacity(0.80))
                    .cornerRadius(8.0)
                    .foregroundColor(Color.red)
                }

                Button(intent: DoSomethingIntent()) {
                    Label("Stop", systemImage: "stop.fill")
                        .foregroundColor(Color.green)
                }
                .tint(.white.opacity(0.5))
            }
            .padding(.trailing, 16)
        }
    }
}
