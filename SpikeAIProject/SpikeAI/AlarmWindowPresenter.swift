//
//  AlarmWindowPresenter.swift
//  Spike AI
//
//  Presents the fallback alarm overlay in its own UIWindow above everything
//  else the app is showing. A `.fullScreenCover` cannot cover a sheet that is
//  already on screen, so a ringing alarm could end up hidden behind the Add or
//  Edit Goal sheet. A window at `.alert + 1` always wins.
//
//  On iOS 26 AlarmKit owns the alerting UI (including over the Lock Screen and
//  over other apps), so this presenter only runs on the legacy path.
//

import SwiftUI
import UIKit

@MainActor
final class AlarmWindowPresenter {
    static let shared = AlarmWindowPresenter()

    private var window: UIWindow?
    private(set) var presentedTaskId: String?

    private init() {}

    var isPresenting: Bool { window != nil }

    func present(taskId: String, title: String, localization: AppLocalization,
                 onStop: @escaping (String) -> Void) {
        // Already ringing for this task — don't stack a second window.
        guard presentedTaskId != taskId else { return }
        dismiss()

        guard let scene = activeScene() else { return }

        let overlay = AlarmOverlayView(title: title) { [weak self] in
            self?.dismiss()
            onStop(taskId)
        }
        .environment(localization)

        let host = UIHostingController(rootView: overlay)
        host.view.backgroundColor = .clear
        host.modalPresentationCapturesStatusBarAppearance = true

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.rootViewController = host
        window.isHidden = false
        window.makeKeyAndVisible()

        self.window = window
        self.presentedTaskId = taskId
    }

    func dismiss() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
        presentedTaskId = nil
    }

    private func activeScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}
