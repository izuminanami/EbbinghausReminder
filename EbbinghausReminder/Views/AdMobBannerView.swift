//
//  AdMobBannerView.swift
//  EbbinghausReminder
//
//  Created by 泉七海 on 2025/05/01.
//

import SwiftUI
import UIKit
import GoogleMobileAds

struct AdMobBannerView: View {
    let width: CGFloat

    private var adSize: AdSize {
        currentOrientationAnchoredAdaptiveBanner(width: max(floor(width), 1))
    }

    private var adHeight: CGFloat {
        cgSize(for: adSize).height
    }

    var body: some View {
        AdMobBannerRepresentable(adSize: adSize)
            .frame(width: width, height: adHeight)
            .frame(height: adHeight)
            .accessibilityLabel("広告")
    }
}

private struct AdMobBannerRepresentable: UIViewRepresentable {
    let adSize: AdSize

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)

        #if DEBUG
        banner.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        #else
        banner.adUnitID = "ca-app-pub-3453173920554262/8424824503"
        #endif

        loadIfPossible(banner, coordinator: context.coordinator)
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        if context.coordinator.loadedAdSizeDescription != string(for: adSize) {
            uiView.adSize = adSize
            context.coordinator.hasLoaded = false
        }
        loadIfPossible(uiView, coordinator: context.coordinator)
    }

    private func loadIfPossible(_ banner: BannerView, coordinator: Coordinator) {
        guard !coordinator.isLoading else { return }
        coordinator.isLoading = true

        DispatchQueue.main.async {
            guard let rootViewController = UIApplication.shared.adRootViewController else {
                coordinator.isLoading = false
                return
            }
            banner.rootViewController = rootViewController

            guard !coordinator.hasLoaded else {
                coordinator.isLoading = false
                return
            }

            banner.load(Request())
            coordinator.hasLoaded = true
            coordinator.isLoading = false
            coordinator.loadedAdSizeDescription = string(for: banner.adSize)
        }
    }

    final class Coordinator {
        var hasLoaded = false
        var isLoading = false
        var loadedAdSizeDescription = ""
    }
}

private extension UIApplication {
    var adRootViewController: UIViewController? {
        let window = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
            ?? connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first

        return topViewController(from: window?.rootViewController)
    }

    func topViewController(from viewController: UIViewController?) -> UIViewController? {
        if let navigationController = viewController as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }
        if let tabBarController = viewController as? UITabBarController {
            return topViewController(from: tabBarController.selectedViewController)
        }
        if let presentedViewController = viewController?.presentedViewController {
            return topViewController(from: presentedViewController)
        }
        return viewController
    }
}
