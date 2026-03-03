import SwiftUI
import PencilKit

struct PencilKitCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var tool: PKTool
    
    func makeUIView(context: Context) -> PKCanvasView {
        
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.tool = tool
        canvas.delegate = context.coordinator
        
        // Evitar comportamiento de scroll raro
        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false
        canvas.bounces = false
        
        // Importante: vamos a manejar el zoom nosotros
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        canvas.zoomScale = 1
        
        canvas.overrideUserInterfaceStyle = .light
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Ajustar zoom (visual) cuando cambie el tamaño visible (ej: teclado)
        context.coordinator.zoomToFitIfNeeded(for: uiView)
        
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        uiView.tool = tool
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }
    
    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        
        private var baseCanvasSize: CGSize = .zero
        private var lastBoundsSize: CGSize = .zero
        private var isApplyingZoom = false
        
        init(drawing: Binding<PKDrawing>) {
            _drawing = drawing
        }
        
        func zoomToFitIfNeeded(for canvasView: PKCanvasView) {
            guard !isApplyingZoom else { return }
            
            let newSize = canvasView.bounds.size
            guard newSize.width > 1, newSize.height > 1 else { return }
            
            // Inicializar tamaño lógico base una sola vez (cuando ya hay bounds reales)
            if baseCanvasSize == .zero {
                baseCanvasSize = newSize
                canvasView.contentSize = baseCanvasSize
                lastBoundsSize = newSize
                applyZoomToFit(canvasView)
                return
            }
            
            // Ignorar cambios mínimos para no “vibrar”
            let dw = abs(newSize.width - lastBoundsSize.width)
            let dh = abs(newSize.height - lastBoundsSize.height)
            guard dw > 1 || dh > 1 else { return }
            
            lastBoundsSize = newSize
            applyZoomToFit(canvasView)
        }
        
        private func applyZoomToFit(_ canvasView: PKCanvasView) {
            guard baseCanvasSize.width > 1, baseCanvasSize.height > 1 else { return }
            
            let visible = canvasView.bounds.size
            let sx = visible.width / baseCanvasSize.width
            let sy = visible.height / baseCanvasSize.height
            let scale = min(sx, sy)
            
            // Bloqueamos zoom para que sea estable (sin pinch zoom)
            isApplyingZoom = true
            canvasView.minimumZoomScale = scale
            canvasView.maximumZoomScale = scale
            canvasView.setZoomScale(scale, animated: false)
            
            // Centrar contenido para que quede prolijo si sobra espacio
            let contentW = baseCanvasSize.width * scale
            let contentH = baseCanvasSize.height * scale
            let insetX = max((visible.width - contentW) / 2, 0)
            let insetY = max((visible.height - contentH) / 2, 0)
            canvasView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
            
            isApplyingZoom = false
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Esto corre al dibujar; no hacemos trabajo pesado acá.
            DispatchQueue.main.async {
                self.drawing = canvasView.drawing
            }
        }
    }
}
