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
    private let scrollView = UIScrollView()
    private let metalView = MetalView()
    private let contentView = UIView()
    private var hasSetInitialZoomScale = false

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

        view.addSubview(metalView)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: metalView.leadingAnchor).isActive = true
        view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: metalView.trailingAnchor).isActive = true
        view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: metalView.topAnchor).isActive = true
        view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: metalView.bottomAnchor).isActive = true

        view.addSubview(scrollView)
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
        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true

        scrollView.maximumZoomScale = 20
        scrollView.minimumZoomScale = 0.1
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

        for _ in 0..<8 {
            self.addColumn()
        }
        for _ in 0..<8 {
            self.addRow()
        }

        scrollView.isHidden = true
        addColButton.isHidden = true
        addRowButton.isHidden = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let widthScale = scrollView.bounds.size.width / contentView.bounds.width
        let heightScale = scrollView.bounds.size.height / contentView.bounds.height
        let minScale = min(widthScale, heightScale)
        scrollView.minimumZoomScale = minScale

        if !hasSetInitialZoomScale && !minScale.isInfinite {
            scrollView.zoomScale = minScale
            hasSetInitialZoomScale = true
        }
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
}

extension ViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.contentView
    }
}

