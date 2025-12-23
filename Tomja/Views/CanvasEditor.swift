//
//  CanvasEditor.swift
//  Tomja
//
//  Created by Tom Knighton on 23/12/2025.
//

import SwiftUI
import PencilKit
import PhotosUI
import UIKit
import Combine

// MARK: - Models

private enum CanvasSelectable: Equatable {
    case text(UUID)
    case sticker(UUID)
}

private struct CanvasTextItem: Identifiable, Equatable {
    let id: UUID
    var text: String
    var color: Color
    /// Normalized (0...1) within canvas bounds
    var position: CGPoint
    var rotation: Angle
    var scale: CGFloat
    
    init(
        id: UUID = UUID(),
        text: String,
        color: Color = .white,
        position: CGPoint = CGPoint(x: 0.5, y: 0.5),
        rotation: Angle = .zero,
        scale: CGFloat = 1.0
    ) {
        self.id = id
        self.text = text
        self.color = color
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }
}

private struct CanvasStickerItem: Identifiable, Equatable {
    let id: UUID
    var assetName: String
    /// Normalized (0...1) within canvas bounds
    var position: CGPoint
    var rotation: Angle
    var scale: CGFloat
    
    init(
        id: UUID = UUID(),
        assetName: String,
        position: CGPoint = CGPoint(x: 0.5, y: 0.5),
        rotation: Angle = .zero,
        scale: CGFloat = 1.0
    ) {
        self.id = id
        self.assetName = assetName
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }
}

// MARK: - View

public struct PencilKitCanvasEditor: View {
    @Environment(\.dismiss) private var dismiss
    
    public let pixelSize: CGSize
    public let stickerAssets: [String]
    public let onComplete: (UIImage) -> Void
    
    @State private var drawing = PKDrawing()
    
    @State private var textItems: [CanvasTextItem] = []
    @State private var stickerItems: [CanvasStickerItem] = []
    @State private var selection: CanvasSelectable?
    
    @State private var backgroundUIImage: UIImage?
    @State private var backgroundPickerItem: PhotosPickerItem?
    @State private var backgroundCropCenter: CGPoint = CGPoint(x: 0.5, y: 0.5)
    @State private var isMovingBackground = false
    
    @State private var showingStickerPicker = false
    @State private var editingTextID: UUID?
    @State private var editingTextDraft: String = ""
    
    // PencilKit layout / export plumbing
    @State private var pkVisibleContentRect: CGRect = .zero
    @State private var pkCanvasBoundsSize: CGSize = .zero
    
    // Preview
    @State private var previewUIImage: UIImage?
    @State private var showTools: Bool = true
    private let previewTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    @State private var bgDragBaseCenter: CGPoint?

    
    public init(pixelSize: CGSize, stickerAssets: [String], onComplete: @escaping (UIImage) -> Void) {
        self.pixelSize = pixelSize
        self.stickerAssets = stickerAssets
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            controls
            
            GeometryReader { geo in
                let canvasRect = canvasRect(in: geo.size, targetAspect: pixelSize.width / pixelSize.height)
                
                ZStack {
                    backgroundLayer(canvasSize: canvasRect.size)
                    
                    PencilKitViewWithToolPicker(
                        drawing: $drawing,
                        visibleContentRect: $pkVisibleContentRect,
                        canvasBoundsSize: $pkCanvasBoundsSize,
                        isInteractive: !isMovingBackground,
                        toolPickerShows: $showTools
                    )
                    .frame(width: canvasRect.width, height: canvasRect.height)
                    .clipped()
                    
                    ForEach(stickerItems) { item in
                        stickerView(item, in: canvasRect.size)
                            .zIndex(selection == .sticker(item.id) ? 20 : 10)
                            .allowsHitTesting(!isMovingBackground)
                    }
                    
                    ForEach(textItems) { item in
                        textView(item, in: canvasRect.size)
                            .zIndex(selection == .text(item.id) ? 21 : 11)
                            .allowsHitTesting(!isMovingBackground)
                    }
                    
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.15), lineWidth: 1)
                        .frame(width: canvasRect.width, height: canvasRect.height)
                }
                .frame(width: canvasRect.width, height: canvasRect.height)
                .position(x: canvasRect.midX, y: canvasRect.midY)
                .contentShape(Rectangle())
                .onTapGesture {
                    selection = nil
                    editingTextID = nil
                }
            }
            .padding(.horizontal)
            
            previewSection
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Next") {
                    let image = exportUIImage()
                    onComplete(image)
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingStickerPicker) {
            StickerPicker(assets: stickerAssets) { picked in
                addSticker(named: picked)
                showingStickerPicker = false
            }
            .presentationDetents([.medium])
        }
        .onChange(of: backgroundPickerItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    await MainActor.run {
                        backgroundUIImage = img
                        backgroundCropCenter = CGPoint(x: 0.5, y: 0.5)
                        isMovingBackground = false
                    }
                }
            }
        }
        .onReceive(previewTimer) { _ in
            previewUIImage = exportUIImage()
        }
    }
    
    // MARK: - Controls
    
    private var controls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button("Add Text") { addText() }
                    .buttonStyle(.bordered)
                
                Button("Add Sticker") { showingStickerPicker = true }
                    .buttonStyle(.bordered)
                
                PhotosPicker(selection: $backgroundPickerItem, matching: .images) {
                    Text("Background")
                }
                .buttonStyle(.bordered)
                
                Button(isMovingBackground ? "Done BG" : "Move BG") {
                    isMovingBackground.toggle()
                    if isMovingBackground {
                        selection = nil
                        editingTextID = nil
                    }
                }
                .buttonStyle(.bordered)
                .disabled(backgroundUIImage == nil)
                
                Button("Clear BG") {
                    backgroundUIImage = nil
                    backgroundCropCenter = CGPoint(x: 0.5, y: 0.5)
                    isMovingBackground = false
                }
                .buttonStyle(.bordered)
                
                Button("Delete Selected") { deleteSelected() }
                    .buttonStyle(.bordered)
                    .disabled(selection == nil || isMovingBackground)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private func backgroundLayer(canvasSize: CGSize) -> some View {
        if let bg = backgroundUIImage {
            Image(uiImage: bg.croppedToAspect(pixelSize.width / pixelSize.height, center: backgroundCropCenter))
                .resizable()
                .aspectRatio(pixelSize.width / pixelSize.height, contentMode: .fill)
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipped()
                .contentShape(Rectangle())
                .if(isMovingBackground) { view in
                    view.gesture(backgroundDragGesture(canvasSize: canvasSize))
                }
                .overlay(alignment: .topLeading) {
                    if isMovingBackground {
                        Text("Drag to position background")
                            .font(.footnote)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.35))
                            .clipShape(Capsule())
                            .padding(10)
                    }
                }
        } else {
            Rectangle()
                .fill(Color.white)
                .frame(width: canvasSize.width, height: canvasSize.height)
        }
    }
    
    private func backgroundDragGesture(canvasSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let bg = backgroundUIImage else { return }
                
                let aspect = pixelSize.width / pixelSize.height
                let limits = bg.cropCenterLimits(forAspect: aspect)
                
                if bgDragBaseCenter == nil {
                    bgDragBaseCenter = backgroundCropCenter
                }
                guard let base = bgDragBaseCenter else { return }
                
                let dx = value.translation.width / max(canvasSize.width, 1)
                let dy = value.translation.height / max(canvasSize.height, 1)
                
                var newCenter = base
                newCenter.x = (newCenter.x - dx).clamped(to: limits.xRange)
                newCenter.y = (newCenter.y - dy).clamped(to: limits.yRange)
                
                backgroundCropCenter = newCenter
            }
            .onEnded { _ in
                bgDragBaseCenter = nil
            }
    }

    
    // MARK: - Preview
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Export preview (updates every 1s)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let img = previewUIImage, let cg = img.cgImage {
                    Text("\(cg.width)×\(cg.height) px")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            
            Group {
                if let img = previewUIImage {
                    Image(uiImage: img)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(pixelSize.width / pixelSize.height, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.thinMaterial)
                        .frame(height: 140)
                        .overlay(
                            Text("No preview yet")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        )
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }
    
    // MARK: - Export (ImageRenderer)
    
    private func exportUIImage() -> UIImage {
        let aspect = pixelSize.width / pixelSize.height
        
        let rect: CGRect = {
            if !pkVisibleContentRect.isEmpty { return pkVisibleContentRect }
            if pkCanvasBoundsSize != .zero { return CGRect(origin: .zero, size: pkCanvasBoundsSize) }
            return CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        }()
        
        // points -> pixels scale based on visible rect
        let scaleX = pixelSize.width / max(rect.width, 1)
        let scaleY = pixelSize.height / max(rect.height, 1)
        let drawScale = min(scaleX, scaleY)
        
        let drawingImage = drawing.image(from: rect, scale: drawScale)
        
        let exportView = CompositeExportView(
            pixelSize: pixelSize,
            aspect: aspect,
            backgroundUIImage: backgroundUIImage,
            backgroundCropCenter: backgroundCropCenter,
            drawingImage: drawingImage,
            textItems: textItems,
            stickerItems: stickerItems
        )
        
        let renderer = ImageRenderer(content: exportView)
        renderer.proposedSize = .init(pixelSize)
        renderer.scale = 1.0
        
        return renderer.uiImage ?? UIImage()
    }
    
    // MARK: - Overlays
    
    private func textView(_ item: CanvasTextItem, in canvasSize: CGSize) -> some View {
        let isSelected = selection == .text(item.id)
        
        let binding = Binding<TransformGestureView.State>(
            get: { .init(position: item.position, rotation: item.rotation, scale: item.scale) },
            set: { newState in
                updateText(itemID: item.id, pos: newState.position, rot: newState.rotation, scale: newState.scale)
            }
        )
        
        return ZStack {
            if editingTextID == item.id {
                TextField("", text: $editingTextDraft)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
                    .onSubmit { commitTextEdit(itemID: item.id) }
            } else {
                Text(item.text)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(item.color)
                    .padding(8)
                    .background(isSelected ? Color.black.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .scaleEffect(item.scale)
        .rotationEffect(item.rotation)
        .position(denormalize(item.position, in: canvasSize))
        .overlay(
            TransformGestureView(
                canvasSize: canvasSize,
                state: binding,
                onSelect: {
                    selection = .text(item.id)
                    editingTextID = nil
                }
            )
        )
        .onTapGesture { selection = .text(item.id) }
        .onLongPressGesture(minimumDuration: 0.25) {
            selection = .text(item.id)
            beginTextEdit(item)
        }
    }
    
    private func stickerView(_ item: CanvasStickerItem, in canvasSize: CGSize) -> some View {
        let isSelected = selection == .sticker(item.id)
        
        let binding = Binding<TransformGestureView.State>(
            get: { .init(position: item.position, rotation: item.rotation, scale: item.scale) },
            set: { newState in
                updateSticker(itemID: item.id, pos: newState.position, rot: newState.rotation, scale: newState.scale)
            }
        )
        
        return Image(item.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: 110, height: 110)
            .padding(8)
            .background(isSelected ? Color.black.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(item.scale)
            .rotationEffect(item.rotation)
            .position(denormalize(item.position, in: canvasSize))
            .overlay(
                TransformGestureView(
                    canvasSize: canvasSize,
                    state: binding,
                    onSelect: {
                        selection = .sticker(item.id)
                        editingTextID = nil
                    }
                )
            )
            .onTapGesture { selection = .sticker(item.id) }
    }
    
    // MARK: - Actions
    
    private func addText() {
        let item = CanvasTextItem(text: "Tap to edit")
        textItems.append(item)
        selection = .text(item.id)
        beginTextEdit(item)
    }
    
    private func addSticker(named asset: String) {
        let item = CanvasStickerItem(assetName: asset)
        stickerItems.append(item)
        selection = .sticker(item.id)
        editingTextID = nil
    }
    
    private func deleteSelected() {
        guard let selection else { return }
        switch selection {
        case .text(let id):
            textItems.removeAll { $0.id == id }
        case .sticker(let id):
            stickerItems.removeAll { $0.id == id }
        }
        self.selection = nil
        editingTextID = nil
    }
    
    private func beginTextEdit(_ item: CanvasTextItem) {
        editingTextID = item.id
        editingTextDraft = item.text
    }
    
    private func commitTextEdit(itemID: UUID) {
        guard let idx = textItems.firstIndex(where: { $0.id == itemID }) else { return }
        textItems[idx].text = editingTextDraft.isEmpty ? " " : editingTextDraft
        editingTextID = nil
    }
    
    private func updateText(itemID: UUID, pos: CGPoint, rot: Angle, scale: CGFloat) {
        guard let idx = textItems.firstIndex(where: { $0.id == itemID }) else { return }
        textItems[idx].position = clampNormalized(pos)
        textItems[idx].rotation = rot
        textItems[idx].scale = scale.clamped(to: 0.2...4.0)
    }
    
    private func updateSticker(itemID: UUID, pos: CGPoint, rot: Angle, scale: CGFloat) {
        guard let idx = stickerItems.firstIndex(where: { $0.id == itemID }) else { return }
        stickerItems[idx].position = clampNormalized(pos)
        stickerItems[idx].rotation = rot
        stickerItems[idx].scale = scale.clamped(to: 0.2...4.0)
    }
    
    // MARK: - Geometry helpers
    
    private func denormalize(_ point: CGPoint, in canvasSize: CGSize) -> CGPoint {
        CGPoint(x: point.x * canvasSize.width, y: point.y * canvasSize.height)
    }
    
    private func clampNormalized(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x.clamped(to: 0...1), y: p.y.clamped(to: 0...1))
    }
    
    // MARK: - Layout
    
    private func canvasRect(in container: CGSize, targetAspect: CGFloat) -> CGRect {
        let maxW = container.width
        let maxH = container.height
        
        let candidateH = maxW / targetAspect
        if candidateH <= maxH {
            let size = CGSize(width: maxW, height: candidateH)
            return CGRect(origin: .zero, size: size).centered(in: CGRect(origin: .zero, size: container))
        } else {
            let candidateW = maxH * targetAspect
            let size = CGSize(width: candidateW, height: maxH)
            return CGRect(origin: .zero, size: size).centered(in: CGRect(origin: .zero, size: container))
        }
    }
}

// MARK: - PencilKit Wrapper

struct PencilKitViewWithToolPicker: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var visibleContentRect: CGRect
    @Binding var canvasBoundsSize: CGSize
    let isInteractive: Bool
    
    @Binding var toolPickerShows: Bool
    
    private let toolPicker = PKToolPicker()
    @State var canvas: PKCanvasView = PKCanvasView()

    
    func makeUIView(context: Context) -> PKCanvasView {
        self.canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.delegate = context.coordinator
        
        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false
        canvas.bounces = false
        canvas.contentInsetAdjustmentBehavior = .never
        canvas.contentInset = .zero
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        canvas.zoomScale = 1
        
        canvas.tool = PKInkingTool(.pen, color: .black, width: 8)
        toolPicker.setVisible(toolPickerShows, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()

        DispatchQueue.main.async { [weak canvas] in
            guard let canvas else { return }
            
            
            
            context.coordinator.publish(from: canvas)
        }
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.isUserInteractionEnabled = isInteractive
        
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        
        // Keep “top-left visible” stable for scroll view semantics
        let inset = uiView.adjustedContentInset
        let desired = CGPoint(x: -inset.left, y: -inset.top)
        if uiView.contentOffset != desired {
            uiView.contentOffset = desired
        }
        
        toolPicker.addObserver(context.coordinator)
        DispatchQueue.main.async {
            toolPicker.setVisible(true, forFirstResponder: uiView)
        }
        uiView.becomeFirstResponder()
        
        DispatchQueue.main.async {
            toolPicker.setVisible(toolPickerShows, forFirstResponder: uiView)
            context.coordinator.publish(from: uiView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self, drawing: $drawing, visibleContentRect: $visibleContentRect, canvasBoundsSize: $canvasBoundsSize)
        toolPicker.addObserver(coordinator)
        canvas.delegate = coordinator
        return coordinator
    }
    
    final class Coordinator: NSObject, PKCanvasViewDelegate, PKToolPickerObserver {
        @Binding var drawing: PKDrawing
        @Binding var visibleContentRect: CGRect
        @Binding var canvasBoundsSize: CGSize
        var parent: PencilKitViewWithToolPicker
        
        private var didAttach = false
        
        init(
            _ parent: PencilKitViewWithToolPicker,
            drawing: Binding<PKDrawing>,
            visibleContentRect: Binding<CGRect>,
            canvasBoundsSize: Binding<CGSize>
        ) {
            self.parent = parent
            _drawing = drawing
            _visibleContentRect = visibleContentRect
            _canvasBoundsSize = canvasBoundsSize
        }
        
        func toolPickerSelectedToolItemDidChange(_ toolPicker: PKToolPicker) {
            parent.canvas.tool = toolPicker.selectedTool
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
            publish(from: canvasView)
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard let canvas = scrollView as? PKCanvasView else { return }
            publish(from: canvas)
        }
        
        func publish(from canvas: PKCanvasView) {
            canvasBoundsSize = canvas.bounds.size
            
            let inset = canvas.adjustedContentInset
            let rect = CGRect(
                x: canvas.contentOffset.x + inset.left,
                y: canvas.contentOffset.y + inset.top,
                width: canvas.bounds.width,
                height: canvas.bounds.height
            )
            visibleContentRect = rect
        }
    }
}

// MARK: - Export Composite View (SwiftUI-only for ImageRenderer)

private struct CompositeExportView: View {
    let pixelSize: CGSize
    let aspect: CGFloat
    let backgroundUIImage: UIImage?
    let backgroundCropCenter: CGPoint
    let drawingImage: UIImage
    let textItems: [CanvasTextItem]
    let stickerItems: [CanvasStickerItem]
    
    var body: some View {
        ZStack {
            if let bg = backgroundUIImage {
                Image(uiImage: bg.croppedToAspect(aspect, center: backgroundCropCenter))
                    .resizable()
                    .aspectRatio(aspect, contentMode: .fill)
                    .frame(width: pixelSize.width, height: pixelSize.height)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: pixelSize.width, height: pixelSize.height)
            }
            
            Image(uiImage: drawingImage)
                .resizable()
                .frame(width: pixelSize.width, height: pixelSize.height)
                .clipped()
            
            ForEach(stickerItems) { item in
                let p = CGPoint(x: item.position.x * pixelSize.width, y: item.position.y * pixelSize.height)
                Image(item.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)
                    .scaleEffect(item.scale)
                    .rotationEffect(item.rotation)
                    .position(p)
            }
            
            ForEach(textItems) { item in
                let p = CGPoint(x: item.position.x * pixelSize.width, y: item.position.y * pixelSize.height)
                Text(item.text)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(item.color)
                    .scaleEffect(item.scale)
                    .rotationEffect(item.rotation)
                    .position(p)
            }
        }
        .frame(width: pixelSize.width, height: pixelSize.height)
        .clipped()
    }
}

// MARK: - Sticker Picker

private struct StickerPicker: View {
    let assets: [String]
    let onPick: (String) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                    spacing: 12
                ) {
                    ForEach(assets, id: \.self) { asset in
                        Button { onPick(asset) } label: {
                            Image(asset)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 90)
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Stickers")
        }
    }
}

// MARK: - Transform Gestures (UIKit recognizers for stable simultaneous pan/pinch/rotate)

private struct TransformGestureView: UIViewRepresentable {
    struct State: Equatable {
        var position: CGPoint   // normalized 0...1
        var rotation: Angle
        var scale: CGFloat
    }
    
    let canvasSize: CGSize
    @Binding var state: State
    let onSelect: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = PassthroughView()
        view.backgroundColor = .clear
        
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        let rotate = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotate(_:)))
        
        pan.delegate = context.coordinator
        pinch.delegate = context.coordinator
        rotate.delegate = context.coordinator
        
        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(rotate)
        
        context.coordinator.canvasSize = canvasSize
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.canvasSize = canvasSize
        context.coordinator.state = $state
        context.coordinator.onSelect = onSelect
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var canvasSize: CGSize = .zero
        var state: Binding<State>?
        var onSelect: (() -> Void)?
        
        private var base: State?
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
        
        private func beginIfNeeded(_ recognizer: UIGestureRecognizer) {
            guard recognizer.state == .began else { return }
            onSelect?()
            base = state?.wrappedValue
        }
        
        private func endIfNeeded(_ recognizer: UIGestureRecognizer) {
            guard recognizer.state == .ended || recognizer.state == .cancelled || recognizer.state == .failed else { return }
            base = nil
        }
        
        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            beginIfNeeded(recognizer)
            defer { endIfNeeded(recognizer) }
            
            guard let base, let binding = state else { return }
            let t = recognizer.translation(in: recognizer.view)
            let dx = t.x / max(canvasSize.width, 1)
            let dy = t.y / max(canvasSize.height, 1)
            
            var next = binding.wrappedValue
            next.position = clamp(CGPoint(x: base.position.x + dx, y: base.position.y + dy))
            binding.wrappedValue = next
        }
        
        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            beginIfNeeded(recognizer)
            defer { endIfNeeded(recognizer) }
            
            guard let base, let binding = state else { return }
            var next = binding.wrappedValue
            next.scale = (base.scale * recognizer.scale).clamped(to: 0.2...4.0)
            binding.wrappedValue = next
        }
        
        @objc func handleRotate(_ recognizer: UIRotationGestureRecognizer) {
            beginIfNeeded(recognizer)
            defer { endIfNeeded(recognizer) }
            
            guard let base, let binding = state else { return }
            var next = binding.wrappedValue
            next.rotation = base.rotation + Angle(radians: Double(recognizer.rotation))
            binding.wrappedValue = next
        }
        
        private func clamp(_ p: CGPoint) -> CGPoint {
            CGPoint(
                x: min(max(p.x, 0), 1),
                y: min(max(p.y, 0), 1)
            )
        }
    }
    
    private final class PassthroughView: UIView {
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { true }
    }
}

// MARK: - Helpers

private extension CGRect {
    func centered(in container: CGRect) -> CGRect {
        CGRect(
            x: container.midX - width / 2,
            y: container.midY - height / 2,
            width: width,
            height: height
        )
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

private extension UIImage {
    func croppedToAspect(_ aspect: CGFloat, center: CGPoint) -> UIImage {
        guard size.width > 0, size.height > 0, let cg = cgImage else { return self }
        
        let pixelW = CGFloat(cg.width)
        let pixelH = CGFloat(cg.height)
        let imgAspect = pixelW / pixelH
        
        let cropW: CGFloat
        let cropH: CGFloat
        
        if imgAspect > aspect {
            cropH = pixelH
            cropW = pixelH * aspect
        } else {
            cropW = pixelW
            cropH = pixelW / aspect
        }
        
        let halfW = cropW / 2
        let halfH = cropH / 2
        
        let minCenterX = halfW
        let maxCenterX = pixelW - halfW
        let minCenterY = halfH
        let maxCenterY = pixelH - halfH
        
        let clampedCenterX = (center.x * pixelW).clamped(to: minCenterX...maxCenterX)
        let clampedCenterY = (center.y * pixelH).clamped(to: minCenterY...maxCenterY)
        
        let originX = clampedCenterX - halfW
        let originY = clampedCenterY - halfH
        
        let rect = CGRect(x: originX, y: originY, width: cropW, height: cropH).integral
        
        guard let cropped = cg.cropping(to: rect) else { return self }
        return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
    }
    
    func cropCenterLimits(forAspect aspect: CGFloat) -> (xRange: ClosedRange<CGFloat>, yRange: ClosedRange<CGFloat>) {
        guard let cg = cgImage else { return (0...1, 0...1) }
        
        let pixelW = CGFloat(cg.width)
        let pixelH = CGFloat(cg.height)
        let imgAspect = pixelW / pixelH
        
        let cropW: CGFloat
        let cropH: CGFloat
        if imgAspect > aspect {
            cropH = pixelH
            cropW = pixelH * aspect
        } else {
            cropW = pixelW
            cropH = pixelW / aspect
        }
        
        let halfW = cropW / 2
        let halfH = cropH / 2
        
        let minCenterX = halfW / pixelW
        let maxCenterX = 1 - (halfW / pixelW)
        let minCenterY = halfH / pixelH
        let maxCenterY = 1 - (halfH / pixelH)
        
        return (minCenterX...maxCenterX, minCenterY...maxCenterY)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PencilKitCanvasEditor(
            pixelSize: CGSize(width: 296, height: 128),
            stickerAssets: ["sticker_star"]
        ) { image in
            print("Exported:", image.cgImage?.width as Any, image.cgImage?.height as Any)
        }
        .navigationTitle("Editor")
    }
}
