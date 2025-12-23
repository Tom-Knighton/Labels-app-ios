//
//  CanvasEditor.swift
//  Tomja
//
//  Created by Tom Knighton on 23/12/2025.
//

import SwiftUI
import PencilKit
import PhotosUI

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
    
    @State private var showingStickerPicker = false
    @State private var editingTextID: UUID?
    @State private var editingTextDraft: String = ""
    
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
                    if let bg = backgroundUIImage {
                        Image(uiImage: bg.croppedToAspect(pixelSize.width / pixelSize.height))
                            .resizable()
                            .aspectRatio(pixelSize.width / pixelSize.height, contentMode: .fill)
                            .frame(width: canvasRect.width, height: canvasRect.height)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: canvasRect.width, height: canvasRect.height)
                    }
                    
                    PencilKitViewWithToolPicker(drawing: $drawing)
                        .frame(width: canvasRect.width, height: canvasRect.height)
                        .clipped()
                    
                    ForEach(stickerItems) { item in
                        stickerView(item, in: canvasRect.size)
                            .zIndex(selection == .sticker(item.id) ? 20 : 10)
                    }
                    
                    ForEach(textItems) { item in
                        textView(item, in: canvasRect.size)
                            .zIndex(selection == .text(item.id) ? 21 : 11)
                    }
                    
                    RoundedRectangle(cornerRadius: 12)
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
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: { self.dismiss() }) {
                    Text("Cancel")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    let image = exportUIImage()
                    onComplete(image)
                    dismiss()
                }) {
                    Text("Next")
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
                    await MainActor.run { backgroundUIImage = img }
                }
            }
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
                
                Button("Clear BG") { backgroundUIImage = nil }
                    .buttonStyle(.bordered)
                
                Button("Delete Selected") { deleteSelected() }
                    .buttonStyle(.bordered)
                    .disabled(selection == nil)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Export
    
    private var exportRow: some View {
        HStack {
            Text("Canvas: \(Int(pixelSize.width))×\(Int(pixelSize.height)) px")
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("Export UIImage") {
                let image = exportUIImage()
                print("Exported: \(image.size)")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private func exportUIImage() -> UIImage {
        let exportView = CompositeExportView(
            pixelSize: pixelSize,
            backgroundUIImage: backgroundUIImage,
            drawing: drawing,
            textItems: textItems,
            stickerItems: stickerItems
        )
        
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 1.0
        renderer.proposedSize = .init(pixelSize)
        
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
                },
                onBegin: {},
                onEnd: {}
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
                    },
                    onBegin: {},
                    onEnd: {}
                )
            )
            .onTapGesture { selection = .sticker(item.id) }
    }

    
    private enum OverlayKind { case text, sticker }
    
    /// Drag now follows the finger by using the gesture location (absolute), not accumulating translation.
    private func overlayGestureAbsolute(
        id: UUID,
        kind: OverlayKind,
        canvasSize: CGSize,
        onUpdate: @escaping (_ pos: CGPoint, _ rot: Angle, _ scale: CGFloat) -> Void
    ) -> some Gesture {
        let drag = DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                let newPos = normalize(value.location, in: canvasSize)
                switch kind {
                case .text:
                    if let item = textItems.first(where: { $0.id == id }) {
                        onUpdate(newPos, item.rotation, item.scale)
                    }
                    selection = .text(id)
                case .sticker:
                    if let item = stickerItems.first(where: { $0.id == id }) {
                        onUpdate(newPos, item.rotation, item.scale)
                    }
                    selection = .sticker(id)
                }
                editingTextID = nil
            }
        
        let rot = RotationGesture()
            .onChanged { angle in
                switch kind {
                case .text:
                    if let item = textItems.first(where: { $0.id == id }) {
                        onUpdate(item.position, item.rotation + angle, item.scale)
                    }
                    selection = .text(id)
                case .sticker:
                    if let item = stickerItems.first(where: { $0.id == id }) {
                        onUpdate(item.position, item.rotation + angle, item.scale)
                    }
                    selection = .sticker(id)
                }
                editingTextID = nil
            }
        
        let mag = MagnificationGesture()
            .onChanged { m in
                let clamped = m.clamped(to: 0.2...4.0)
                switch kind {
                case .text:
                    if let item = textItems.first(where: { $0.id == id }) {
                        onUpdate(item.position, item.rotation, (item.scale * clamped).clamped(to: 0.2...4.0))
                    }
                    selection = .text(id)
                case .sticker:
                    if let item = stickerItems.first(where: { $0.id == id }) {
                        onUpdate(item.position, item.rotation, (item.scale * clamped).clamped(to: 0.2...4.0))
                    }
                    selection = .sticker(id)
                }
                editingTextID = nil
            }
        
        return drag.simultaneously(with: rot).simultaneously(with: mag)
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
        textItems[idx].scale = scale
    }
    
    private func updateSticker(itemID: UUID, pos: CGPoint, rot: Angle, scale: CGFloat) {
        guard let idx = stickerItems.firstIndex(where: { $0.id == itemID }) else { return }
        stickerItems[idx].position = clampNormalized(pos)
        stickerItems[idx].rotation = rot
        stickerItems[idx].scale = scale
    }
    
    // MARK: - Geometry helpers
    
    private func normalize(_ point: CGPoint, in canvasSize: CGSize) -> CGPoint {
        CGPoint(
            x: (point.x / max(canvasSize.width, 1)).clamped(to: 0...1),
            y: (point.y / max(canvasSize.height, 1)).clamped(to: 0...1)
        )
    }
    
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

// MARK: - PencilKit Wrapper (FIXED tool picker)

struct PencilKitViewWithToolPicker: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.delegate = context.coordinator
        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false
        
        canvas.tool = PKInkingTool(.pen, color: .black, width: 8)
        
        // Attach once the view has a window/scene. This reliably shows the system tool picker.
        DispatchQueue.main.async { [weak canvas] in
            guard let canvas else { return }
            canvas.becomeFirstResponder()
            context.coordinator.attachToolPicker(to: canvas)
        }
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        
        // If SwiftUI re-parents / window becomes available later, ensure picker is attached.
        context.coordinator.attachToolPicker(to: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }
    
    final class Coordinator: NSObject, PKCanvasViewDelegate, PKToolPickerObserver {
        @Binding var drawing: PKDrawing
        private weak var attachedCanvas: PKCanvasView?
        private var toolPicker: PKToolPicker?
        
        init(drawing: Binding<PKDrawing>) {
            _drawing = drawing
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
        }
        
        func attachToolPicker(to canvas: PKCanvasView) {
            guard canvas.window != nil else { return }
//            guard let windowScene = canvas.window?.window else { return }
            
            let picker = PKToolPicker()
            toolPicker = picker
            attachedCanvas = canvas
            
            picker.setVisible(true, forFirstResponder: canvas)
            picker.addObserver(canvas)
            picker.addObserver(self)
            
            canvas.becomeFirstResponder()
        }
    }
}

// MARK: - Export Composite View

private struct CompositeExportView: View {
    let pixelSize: CGSize
    let backgroundUIImage: UIImage?
    let drawing: PKDrawing
    let textItems: [CanvasTextItem]
    let stickerItems: [CanvasStickerItem]
    
    var body: some View {
        ZStack {
            if let bg = backgroundUIImage {
                Image(uiImage: bg.croppedToAspect(pixelSize.width / pixelSize.height))
                    .resizable()
                    .aspectRatio(pixelSize.width / pixelSize.height, contentMode: .fill)
                    .frame(width: pixelSize.width, height: pixelSize.height)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: pixelSize.width, height: pixelSize.height)
            }
            
            Image(uiImage: drawing.image(from: CGRect(origin: .zero, size: pixelSize), scale: 1.0))
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

private extension UIImage {
    func croppedToAspect(_ aspect: CGFloat) -> UIImage {
        guard size.width > 0, size.height > 0 else { return self }
        
        let imgAspect = size.width / size.height
        let cropRect: CGRect
        
        if imgAspect > aspect {
            let newWidth = size.height * aspect
            let x = (size.width - newWidth) / 2
            cropRect = CGRect(x: x, y: 0, width: newWidth, height: size.height)
        } else {
            let newHeight = size.width / aspect
            let y = (size.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: y, width: size.width, height: newHeight)
        }
        
        guard
            let cg = cgImage,
            let cropped = cg.cropping(to: cropRect.applying(
                CGAffineTransform(
                    scaleX: CGFloat(cg.width) / size.width,
                    y: CGFloat(cg.height) / size.height
                )
            ))
        else { return self }
        
        return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
    }
}

private struct TransformGestureView: UIViewRepresentable {
    struct State: Equatable {
        var position: CGPoint   // normalized 0...1
        var rotation: Angle
        var scale: CGFloat
    }
    
    let canvasSize: CGSize
    @Binding var state: State
    let onSelect: () -> Void
    let onBegin: () -> Void
    let onEnd: () -> Void
    
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
        context.coordinator.onBegin = onBegin
        context.coordinator.onEnd = onEnd
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var canvasSize: CGSize = .zero
        var state: Binding<State>?
        var onSelect: (() -> Void)?
        var onBegin: (() -> Void)?
        var onEnd: (() -> Void)?
        
        private var base: State?
        private var accumulatedRotation: CGFloat = 0
        private var accumulatedScale: CGFloat = 1
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
        
        private func beginIfNeeded(_ recognizer: UIGestureRecognizer) {
            guard recognizer.state == .began else { return }
            onSelect?()
            onBegin?()
            guard let current = state?.wrappedValue else { return }
            base = current
            accumulatedRotation = 0
            accumulatedScale = 1
        }
        
        private func endIfNeeded(_ recognizer: UIGestureRecognizer) {
            guard recognizer.state == .ended || recognizer.state == .cancelled || recognizer.state == .failed else { return }
            base = nil
            onEnd?()
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
            // UIPinch gives cumulative scale since began; apply relative to base.
            let raw = base.scale * recognizer.scale
            let nextScale = min(max(raw, 0.2), 4.0)
            
            var next = binding.wrappedValue
            next.scale = nextScale
            binding.wrappedValue = next
        }
        
        @objc func handleRotate(_ recognizer: UIRotationGestureRecognizer) {
            beginIfNeeded(recognizer)
            defer { endIfNeeded(recognizer) }
            
            guard let base, let binding = state else { return }
            // recognizer.rotation is radians since began.
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
    
    /// Lets touches pass through except the gesture recognizers.
    private final class PassthroughView: UIView {
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            true
        }
    }
}


// MARK: - Preview

#Preview {
    PencilKitCanvasEditor(
        pixelSize: CGSize(width: 400, height: 300),
        stickerAssets: ["sticker_star", "sticker_heart", "sticker_bolt"]
    ) { image in
        print("Exported image: \(image.size)")
    }
}
