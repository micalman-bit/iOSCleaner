//
//  LottieView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 05.12.2024.
//

import Lottie
import SwiftUI

struct LottieView: UIViewRepresentable {
    var name: String
    var contentMode: UIView.ContentMode = .scaleAspectFill
    var isActive: Bool
    var loopMode: LottieLoopMode = .playOnce
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = contentMode
        animationView.loopMode = loopMode

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        context.coordinator.animationView = animationView
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if isActive {
            context.coordinator.animationView?.play()
        } else {
            context.coordinator.animationView?.stop()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var animationView: LottieAnimationView?
    }
}
