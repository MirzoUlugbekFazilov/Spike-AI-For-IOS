//
//  ScreenTimeOnboardingView.swift
//  Spike AI
//
//  Full-screen onboarding that requests Screen Time (Family Controls)
//  permission right after login — similar to how PushScroll works.
//

import SwiftUI

#if os(iOS)
import FamilyControls
#endif

struct ScreenTimeOnboardingView: View {
    @Environment(AuthorizationManager.self) var stAuth
    @Environment(FocusModeViewModel.self)   var focusVM
    @Environment(AppLocalization.self)      private var loc

    @State private var isRequesting  = false
    @State private var didDeny       = false
    @State private var hasCompleted  = false

    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // Content constrained for iPad readability
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(white: 0.2), Color(white: 0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 120)
                    Image(systemName: "hourglass.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.white)
                }
                Text(loc["screen_time_access"])
                    .font(.largeTitle).fontWeight(.bold)
                Text(loc["screen_time_permission_desc"])
                    .font(.body).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer().frame(height: 40)

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "shield.lefthalf.filled", color: .orange,
                           title: loc["ask_before_opening"],
                           subtitle: loc["focus_desc"])
                featureRow(icon: "lock.shield", color: .red,
                           title: loc["block_apps_completely"],
                           subtitle: loc["lock_in_desc"])
                featureRow(icon: "chart.bar.fill", color: .white,
                           title: loc["stay_accountable"],
                           subtitle: loc["stay_accountable_desc"])
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    requestAccess()
                } label: {
                    HStack(spacing: 8) {
                        if isRequesting { ProgressView().tint(.white) }
                        Image(systemName: "lock.shield")
                        Text(loc["allow_screen_time"]).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.white).foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isRequesting)

                if didDeny {
                    VStack(spacing: 8) {
                        Text(loc["screen_time_denied"])
                            .font(.caption).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            stAuth.openSettings()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "gear")
                                Text(loc["open_settings"])
                            }
                            .font(.subheadline).fontWeight(.medium)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Color.spikeCard).foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                Button { finishOnce() } label: {
                    Text(loc["skip_for_now"]).font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24).padding(.bottom, 40)
        }
        .iPadReadable(maxWidth: 500)
        .onAppear {
            stAuth.refreshStatus()
            if stAuth.status == .approved { finishOnce() }
        }
        .onChange(of: stAuth.status) {
            if stAuth.status == .approved { finishOnce() }
        }
    }

    /// Completes onboarding exactly once. All approval paths (onAppear, onChange,
    /// the request callback, and Skip) funnel through here so `onComplete()` can
    /// never fire twice and drive the view swap twice.
    private func finishOnce() {
        guard !hasCompleted else { return }
        hasCompleted = true
        onComplete()
    }

    private func requestAccess() {
        isRequesting = true; didDeny = false
        Task {
            await stAuth.requestAuthorization()
            isRequesting = false
            if stAuth.status == .approved {
                finishOnce()
            } else if stAuth.status == .denied {
                didDeny = true
            }
        }
    }

    private func featureRow(icon: String, color: Color,
                            title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3).foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.semibold)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
