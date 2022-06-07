//
//  RGBSlider.swift
//  Bismush
//
//  Created by mzp on 5/15/22.
//
import BismushKit
import SwiftUI

struct NumberStepper: View {
    @Binding var value: Float

    var body: some View {
        HStack(spacing: 0) {
            Stepper(label: {
                Text(value, format: .number.precision(.fractionLength(2)))
            }, onIncrement: {
                value = round(100 * value) / 100 + 0.01
            }, onDecrement: {
                value = round(100 * value) / 100 - 0.01
            })
        }
        .frame(width: 50)
    }
}

struct RGBSlider: View {
    @EnvironmentObject var model: RGBColorViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Color(nsColor: model.color).frame(width: 16, height: 16)
            HStack(alignment: .center) {
                ColorComponentSlider(startColor: .black, endColor: .red, value: $model.red)
                    .makeAlignmentGuide()
                NumberStepper(value: $model.red)
            }
            .accessibilityLabel("Red")
            HStack {
                ColorComponentSlider(startColor: .black, endColor: .green, value: $model.green)
                    .makeAlignmentGuide()
                NumberStepper(value: $model.green)
            }
            .accessibilityLabel("Green")
            HStack {
                ColorComponentSlider(startColor: .black, endColor: .blue, value: $model.blue)
                    .makeAlignmentGuide()
                NumberStepper(value: $model.blue)
            }
            .accessibilityLabel("Blue")
            HStack {
                ColorComponentSlider(startColor: .white, endColor: .black, value: $model.alpha)
                    .makeAlignmentGuide()
                NumberStepper(value: $model.alpha)
            }
            .accessibilityLabel("Alpha")
        }
    }
}

struct RGBSlider_Previews: PreviewProvider {
    static var previews: some View {
        SampleViewModel {
            RGBSlider()
        }
    }
}
