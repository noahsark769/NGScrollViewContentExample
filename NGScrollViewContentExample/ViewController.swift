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

class ScrollViewZoomObserver: NSObject {
    private var lastValue: CGFloat? = nil
    private var link: CADisplayLink!
    private let scrollView: UIScrollView
    private let contentView: UIView
    private let onTick: (CGFloat, CGPoint) -> Void

    init(scrollView: UIScrollView, contentView: UIView, onTick: @escaping (CGFloat, CGPoint) -> Void) {
        self.scrollView = scrollView
        self.contentView = contentView
        self.onTick = onTick
//        self.contentView.layer.anchorPoint = .zero
        super.init()

        link = CADisplayLink(target: self, selector: #selector(didTick))
        link.add(to: RunLoop.main, forMode: .default)
    }

    @objc private func didTick() {
        let value = contentView.layer.presentation()?.transform.m11
        if lastValue != value {
            self.lastValue = value
//            print("""
//                New value!
//                    frame: \(contentView.layer.presentation()?.frame)
//                    bounds: \(contentView.layer.presentation()?.bounds)
//                    position: \(contentView.layer.presentation()?.position)
//                    anchorPoint: \(contentView.layer.presentation()?.anchorPoint)
//            """)
            self.onTick(value!, contentView.layer.presentation()!.position)
        }
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
    private let metalView = MetalLayerView()
    private let contentView = UIView()
    private var hasSetInitialZoomScale = false
    private var observer: ScrollViewZoomObserver!

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

    var zoomScaleObservation: NSKeyValueObservation?
    var contentSizeObservation: NSKeyValueObservation?

    private lazy var worldView = WorldView(scrollView: self.scrollView)!

    override func loadView() {
        view = UIView()

        view.addSubview(metalView)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: metalView.leadingAnchor).isActive = true
        view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: metalView.trailingAnchor).isActive = true
        view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: metalView.topAnchor).isActive = true
        view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: metalView.bottomAnchor).isActive = true

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
        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true

        scrollView.maximumZoomScale = 5
        scrollView.minimumZoomScale = 1
//        scrollView.setZoomScale(1, animated: true)
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

        view.addSubview(worldView)
        worldView.translatesAutoresizingMaskIntoConstraints = false
        worldView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12).isActive = true
        worldView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12).isActive = true
        worldView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        worldView.widthAnchor.constraint(equalToConstant: 100).isActive = true

//        scrollView.bouncesZoom = false


//        metalView.scale = Float(scrollView.zoomScale)
//        metalView.contentOffset = scrollView.contentOffset
//        metalView.contentSize = scrollView.contentSize
//        scrollView.bouncesZoom = false

//        scrollView.isHidden = true
//        addColButton.isHidden = true
//        addRowButton.isHidden = true

//        zoomScaleObservation = self.observe(\.scrollView.zoomScale, options: [.new, .initial], changeHandler: { [unowned self] object, change in
//            print("Observed zoomScale: \(self.scrollView.zoomScale)")
//            self.metalView.scale = Float(self.scrollView.zoomScale)
//            self.metalView.contentOffset = self.scrollView.contentOffset
//            self.metalView.contentSize = self.scrollView.contentSize
//            self.metalView.contentBounds = self.scrollView.bounds
//        })
//        contentSizeObservation = scrollView.observe(\.contentSize, options: [.new, .initial], changeHandler: { [unowned self] object, change in
//            print("Observed contentSize: \(self.scrollView.contentSize)")
//            self.metalView.scale = Float(self.scrollView.zoomScale)
//            self.metalView.contentOffset = self.scrollView.contentOffset
//            self.metalView.contentSize = self.scrollView.contentSize
//            self.metalView.contentBounds = self.scrollView.bounds
//        })

//        self.listen(to: self.scrollView, keyPath: "zoomScale", selector: #selector(scrollViewUpdated))
//        self.listen(to: self.scrollView, keyPath: "contentOffset", selector: #selector(scrollViewUpdated))
//        observer = ScrollViewZoomObserver(scrollView: scrollView, contentView: contentView) { [unowned self] zoom, position in
//            self.metalView.contentBounds = CGRect(
//                x: self.lastScrollViewPosition.x * ((590 - position.x) / 590),
//                y: self.lastScrollViewPosition.y * ((620 - position.y) / 620),
//                width: self.scrollView.bounds.width,
//                height: self.scrollView.bounds.height
//            )
//            self.metalView.scale = Float(zoom)
//        }

//        self.addObserver(self, forKeyPath: "scrollView.zoomScale", options: [.new, .initial], context: nil)
//        self.scrollViewUpdated()
    }


//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//
//        let widthScale = scrollView.bounds.size.width / contentView.bounds.width
//        let heightScale = scrollView.bounds.size.height / contentView.bounds.height
//        let minScale = min(widthScale, heightScale)
//        scrollView.minimumZoomScale = minScale
//
//        if !hasSetInitialZoomScale && !minScale.isInfinite {
//            scrollView.zoomScale = minScale
//            hasSetInitialZoomScale = true
//        }
//    }

    @objc private func scrollViewUpdated() {
        print("Observed update! \(self.scrollView.contentSize)")
        self.metalView.scale = Float(self.scrollView.zoomScale)
//        self.metalView.contentOffset = self.scrollView.contentOffset
//        self.metalView.contentSize = self.scrollView.contentSize
        self.metalView.contentBounds = self.scrollView.bounds
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

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print("HM OBsERVED vALue")
    }

    var lastScrollViewPosition: CGPoint = .zero
}

extension ViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.contentView
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        print("""
//            Scroll view scrolled!
//                contentoffset: \(scrollView.contentOffset),
//                zoomScale: \(scrollView.zoomScale),
//                contentSize: \(scrollView.contentSize),
//                bounds: \(scrollView.bounds),
//                presentationlayer position: \(self.contentView.layer.presentation()?.position),
//                scrollViewAnimationKeys: \(self.contentView.layer.animationKeys())
//        """)

//        metalView.contentOffset = scrollView.contentOffset
//        metalView.contentSize = scrollView.contentSize
//        UIView.animate(withDuration: 2, animations: {
//        if scrollView.zoomScale != 1 {
//        CATransaction.begin()
//        CATransaction.setAnimationDuration(5)
            self.metalView.contentBounds = scrollView.bounds
            self.metalView.scale = Float(scrollView.zoomScale)
//        CATransaction.commit()
//        }
//        })
//        if self.contentView.layer.animationKeys() != nil {
//            self.contentView.layer.removeAllAnimations()
//        }

        worldView.updateWindow()

//        if scrollView.zoomScale != scrollView.minimumZoomScale && scrollView.zoomScale != scrollView.maximumZoomScale {
//            self.lastScrollViewPosition = scrollView.bounds.origin
//        }
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//        print("""
//            Scroll view ended zooming!
//                contentoffset: \(scrollView.contentOffset),
//                zoomScale: \(scrollView.zoomScale),
//                contentSize: \(scrollView.contentSize),
//                bounds: \(scrollView.bounds)
//        """)
//        metalView.scale = Float(scrollView.zoomScale)
//        metalView.contentOffset = scrollView.contentOffset
//        metalView.contentSize = scrollView.contentSize
//        metalView.contentBounds = scrollView.bounds
//        worldView.updateWindow()
//
//        if scrollView.zoomScale > 2 {
////            scrollView.isUserInteractionEnabled = false
//            scrollView.zoom(to: CGRect(x: 0, y: 0, width: 768, height: 1004), animated: true)
//        } else if scrollView.zoomScale < 1 {
//            scrollView.setZoomScale(1, animated: false)
//        }

//        CATransaction.begin()
//        CATransaction.setAnimationDuration(4)
//        CATransaction.setCompletionBlock {
//            print("Transaction...complete!")
//        }
            self.metalView.contentBounds = scrollView.bounds
            self.metalView.scale = Float(scrollView.zoomScale)
//            self.metalView.draw()
//        CATransaction.commit()
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
//        print("""
//            Scroll will begin zooming!
//                contentoffset: \(scrollView.contentOffset),
//                zoomScale: \(scrollView.zoomScale),
//                contentSize: \(scrollView.contentSize),
//                bounds: \(scrollView.bounds)
//        """)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        print("""
//            Scroll view zoomed!
//                contentoffset: \(scrollView.contentOffset),
//                zoomScale: \(scrollView.zoomScale),
//                contentSize: \(scrollView.contentSize),
//                bounds: \(scrollView.bounds)
//        """)
    }

    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
//        print("""
//            Scroll view adjusted content inset!
//                contentoffset: \(scrollView.contentOffset),
//                zoomScale: \(scrollView.zoomScale),
//                contentSize: \(scrollView.contentSize),
//                bounds: \(scrollView.bounds)
//        """)
    }
}

