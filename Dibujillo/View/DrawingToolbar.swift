//
//  DrawingToolbar.swift
//  Dibujillo Game
//

import SwiftUI

struct DrawingToolbar: View {
    @ObservedObject var vm: GameViewModel
    @State private var showColorPicker = false
    @State private var showWidthSlider = false
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        VStack(spacing: DSSpacing.sm) {
            // Fila principal: herramientas + acciones
            HStack(spacing: DSSpacing.sm) {
                toolButtons
                Spacer()
                colorButton
                widthButton
                Spacer()
                actionButtons
            }
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .background(DSColors.surface)
            .cornerRadius(DSRadius.lg)
            .modifier(DSShadow.soft())

            // Paleta de colores expandible
            if showColorPicker {
                colorPalette
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Slider de grosor expandible
            if showWidthSlider {
                widthSliderRow
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showColorPicker)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showWidthSlider)
    }

    // MARK: - Tool Buttons

    private var toolButtons: some View {
        HStack(spacing: 6) {
            ForEach(GameViewModel.ToolMode.allCases) { mode in
                ToolButton(
                    emoji: mode.rawValue,
                    isSelected: vm.toolMode == mode,
                    tooltip: mode.label
                ) {
                    vm.toolMode = mode
                    // Cerrar paneles al cambiar tool
                    showColorPicker = false
                    showWidthSlider = false
                }
            }
        }
    }

    // MARK: - Color Button

    private var colorButton: some View {
        Button {
            showColorPicker.toggle()
            showWidthSlider = false
        } label: {
            Circle()
                .fill(vm.inkColor)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(DSColors.border, lineWidth: 2)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                        .padding(1)
                )
        }
    }

    // MARK: - Width Button

    private var widthButton: some View {
        Button {
            showWidthSlider.toggle()
            showColorPicker = false
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(showWidthSlider ? DSColors.primary.opacity(0.1) : DSColors.surfaceAlt)
                    .frame(width: 36, height: 36)

                Circle()
                    .fill(DSColors.textPrimary)
                    .frame(width: max(4, vm.lineWidth * 0.7), height: max(4, vm.lineWidth * 0.7))
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 6) {
            SmallActionButton(icon: "arrow.uturn.backward", color: DSColors.textSecondary) {
                undoManager?.undo()
            }
            .disabled(!(undoManager?.canUndo ?? false))

            SmallActionButton(icon: "arrow.uturn.forward", color: DSColors.textSecondary) {
                undoManager?.redo()
            }
            .disabled(!(undoManager?.canRedo ?? false))

            SmallActionButton(icon: "trash", color: DSColors.error) {
                vm.clearDrawing()
            }
        }
    }

    // MARK: - Color Palette

    private var colorPalette: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
            ForEach(GameViewModel.palette, id: \.self) { color in
                Button {
                    vm.inkColor = color
                    if vm.toolMode == .eraser { vm.toolMode = .pen }
                } label: {
                    Circle()
                        .fill(color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(
                                    vm.inkColor == color ? DSColors.primary : Color.clear,
                                    lineWidth: 2.5
                                )
                                .padding(-2)
                        )
                        .overlay(
                            Circle()
                                .stroke(color == .white ? DSColors.border : Color.clear, lineWidth: 1)
                        )
                }
            }
        }
        .padding(DSSpacing.md)
        .background(DSColors.surface)
        .cornerRadius(DSRadius.md)
        .modifier(DSShadow.soft())
    }

    // MARK: - Width Slider

    private var widthSliderRow: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: "circle.fill")
                .font(.system(size: 4))
                .foregroundColor(DSColors.textSecondary)

            Slider(value: $vm.lineWidth, in: 1...30, step: 1)
                .tint(DSColors.primary)

            Image(systemName: "circle.fill")
                .font(.system(size: 14))
                .foregroundColor(DSColors.textSecondary)

            Text("\(Int(vm.lineWidth))")
                .font(DSFont.mono(12))
                .foregroundColor(DSColors.textSecondary)
                .frame(width: 26, alignment: .trailing)
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(DSColors.surface)
        .cornerRadius(DSRadius.md)
        .modifier(DSShadow.soft())
    }
}

// MARK: - Tool Button Component

private struct ToolButton: View {
    let emoji: String
    let isSelected: Bool
    let tooltip: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 38, height: 38)
                .background(isSelected ? DSColors.primary.opacity(0.15) : Color.clear)
                .cornerRadius(DSRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.sm)
                        .stroke(isSelected ? DSColors.primary.opacity(0.4) : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tooltip)
    }
}

// MARK: - Small Action Button

private struct SmallActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isEnabled ? color : color.opacity(0.3))
                .frame(width: 34, height: 34)
                .background(DSColors.surfaceAlt)
                .cornerRadius(DSRadius.sm)
        }
        .buttonStyle(.plain)
    }
}
