//
//  ViewController.swift
//  NGScrollViewContentExample
//
//  Created by Noah Gilmore on 1/31/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import UIKit

extension CGRect {
    var x: CGFloat { return self.origin.x }
    var y: CGFloat { return self.origin.y }
    var width: CGFloat { return self.size.width }
    var height: CGFloat { return self.size.height }
}

extension CGFloat {
    func clamped(min: CGFloat, max: CGFloat) -> CGFloat {
        if self > max {
            return max
        } else if self < min {
            return min
        } else {
            return self
        }
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(hue: CGFloat(drand48()), saturation: 0.7, brightness: 1, alpha: 1)
    }
}

class ViewController: UIViewController {
    private let verticalStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20
        return view
    }()
    @objc dynamic private let scrollView = UIScrollView()
    private let metalView = MetalView()
    private let contentView = UIView()

    private let addRowButton: UIButton = {
        let button = UIButton()
        button.setTitle("Add Row", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.red, for: .normal)
        return button
    }()

    private let addColButton: UIButton = {
        let button = UIButton()
        button.setTitle("Add Column", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.red, for: .normal)
        return button
    }()

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white

        contentView.addSubview(metalView)
        metalView.frame = CGRect(x: 0, y: 0, width: 10, height: 10)

        view.addSubview(scrollView)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true

        scrollView.backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(verticalStackView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.leadingAnchor.constraint(equalTo: verticalStackView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: verticalStackView.trailingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: verticalStackView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: verticalStackView.bottomAnchor).isActive = true

        scrollView.addSubview(contentView)

        // pin content size
        contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
//        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
//        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true

        scrollView.maximumZoomScale = 5
        scrollView.minimumZoomScale = 1
        scrollView.delegate = self

        view.addSubview(addRowButton)
        addRowButton.translatesAutoresizingMaskIntoConstraints = false
        view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: addRowButton.leadingAnchor).isActive = true
        view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: addRowButton.topAnchor).isActive = true
        addRowButton.addTarget(self, action: #selector(addRow), for: .touchUpInside)

        view.addSubview(addColButton)
        addColButton.translatesAutoresizingMaskIntoConstraints = false
        view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: addColButton.leadingAnchor).isActive = true
        addColButton.topAnchor.constraint(equalTo: addRowButton.bottomAnchor).isActive = true
        addColButton.addTarget(self, action: #selector(addColumn), for: .touchUpInside)

        for _ in 0..<20 {
            self.addColumn()
        }

        for _ in 0..<20 {
            self.addRow()
        }

        self.metalView.scale = 1
//        self.scrollView.bounces = false
    }

    @objc private func addColumn() {
        if verticalStackView.arrangedSubviews.isEmpty {
            let newStackView = UIStackView()
            newStackView.axis = .horizontal
            newStackView.spacing = 20
            verticalStackView.addArrangedSubview(newStackView)
        }
        for stackView in verticalStackView.arrangedSubviews {
            guard let stackView = stackView as? UIStackView else { continue }
            stackView.addArrangedSubview(self.newColorView())
        }
    }

    @objc private func addRow() {
        let numViewsToAdd = (verticalStackView.arrangedSubviews[0] as? UIStackView)?.arrangedSubviews.count ?? 0
        let newStackView = UIStackView()
        newStackView.axis = .horizontal
        newStackView.spacing = 20
        for _ in 0..<numViewsToAdd {
            newStackView.addArrangedSubview(self.newColorView())
        }
        verticalStackView.addArrangedSubview(newStackView)
    }

    private func newColorView() -> UIView {
        let colorView = UIView()
        colorView.backgroundColor = UIColor.random()
        colorView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        colorView.widthAnchor.constraint(equalToConstant: 40).isActive = true
//        colorView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        return colorView
    }

    var isDisabledForAnimation: Bool = false
    var wasZoomingOnLastScroll: Bool = false
}

extension ViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.contentView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        self.isDisabledForAnimation = false
//        self.forceUpdateMetalView()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.isDisabledForAnimation = false
        self.forceUpdateMetalView()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.isDisabledForAnimation = false
        self.forceUpdateMetalView()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visibleRect = scrollView.convert(scrollView.bounds, to: contentView)
//        if visibleRect.maxX <= contentView.bounds.width {
//            CATransaction.setCompletionBlock {
//                print("OKYA YOU'RE GOOD GEEZ")
//                self.isDisabledForAnimation = false
//                self.forceUpdateMetalView()
//            }
//        }

        if (!scrollView.isZoomBouncing) {
            if (scrollView.isZooming) {
                self.wasZoomingOnLastScroll = true
            } else if self.wasZoomingOnLastScroll {

                    // If we were zooming on last scroll but not anymore, cancel everything
                    print("THAT'S IT HOLD EVERYTHING")
        //            self.scrollView.isUserInteractionEnabled = false
        //            CATransaction.setCompletionBlock {
        //                self.scrollView.isUserInteractionEnabled = true
        //            }
        //            self.scrollView.bounces = false
                    self.isDisabledForAnimation = true
            }
            if !scrollView.isZoomBouncing && !self.isDisabledForAnimation {
                self.forceUpdateMetalView()
            }
        }
    }

    private func forceUpdateMetalView() {
        let visibleRect = scrollView.convert(scrollView.bounds, to: contentView)
        let metalViewScaleMultiplier: CGFloat = 2 // = CGFloat(max(1, Int(scrollView.zoomScale)))

        let effectiveRectSize = CGSize(
            width: visibleRect.width * metalViewScaleMultiplier,
            height: visibleRect.height * metalViewScaleMultiplier
        )
        let effectiveRect = CGRect(
            x: max(visibleRect.x, 0) - (metalViewScaleMultiplier == 1 ? 0 : (effectiveRectSize.width - visibleRect.size.width) / 2),
            y: max(visibleRect.y, 0) - (metalViewScaleMultiplier == 1 ? 0 : (effectiveRectSize.height - visibleRect.size.width) / 2),
            width: effectiveRectSize.width,
            height: effectiveRectSize.height
        )

        self.metalView.frame = effectiveRect
        self.metalView.contentBounds = effectiveRect
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        metalView.layer.contentsScale = scale
//        self.isDisabledForAnimation = false
        self.wasZoomingOnLastScroll = false
//        self.scrollView.isUserInteractionEnabled = true
//        print("END ZOOMING")
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//        print("END ANIMATIONNNNNNNN")
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        print("YE END DECELLERATE")
    }
}

