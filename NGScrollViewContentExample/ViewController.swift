//
//  ViewController.swift
//  NGScrollViewContentExample
//
//  Created by Noah Gilmore on 1/31/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import UIKit

extension UIColor {
    static func random() -> UIColor {
        return UIColor(hue: CGFloat(drand48()), saturation: 1, brightness: 1, alpha: 1)
    }
}

class ViewController: UIViewController {
    private let verticalStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20
        return view
    }()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var hasSetInitialZoomScale = false

    override func loadView() {
        view = scrollView
        scrollView.backgroundColor = .white
        contentView.backgroundColor = .white
        contentView.addSubview(verticalStackView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.leadingAnchor.constraint(equalTo: verticalStackView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: verticalStackView.trailingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: verticalStackView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: verticalStackView.bottomAnchor).isActive = true

        scrollView.addSubview(contentView)

        scrollView.maximumZoomScale = 20
        scrollView.minimumZoomScale = 0.1
        scrollView.delegate = self

        for _ in 0..<12 {
            self.addColumn()
        }
        for _ in 0..<12 {
            self.addRow()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let widthScale = view.bounds.size.width / contentView.bounds.width
        let heightScale = view.bounds.size.height / contentView.bounds.height
        let minScale = min(widthScale, heightScale)
        scrollView.minimumZoomScale = minScale

        if !hasSetInitialZoomScale {
            scrollView.zoomScale = minScale
            hasSetInitialZoomScale = true
        }
    }

    private func addColumn() {
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

    private func addRow() {
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
}

extension ViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.contentView
    }
}

