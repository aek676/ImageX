import CoreML
import SwiftUI

struct ContentView: View {

    @State private var selectedImage: UIImage? = nil
    @State private var resultText: String = "Tap image to select"
    @State private var mostrarImagePicker: Bool = false
    @State private var isAnalyzing: Bool = false  // Indicador para el progreso de análisis

    var body: some View {
        VStack {
            // Imagen de la foto seleccionada o por defecto
            Image(uiImage: selectedImage ?? UIImage(named: "Default_image")!)
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 300)
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding()
                .onTapGesture {
                    // Mostrar el Image Picker cuando el usuario toque la imagen
                    mostrarImagePicker.toggle()
                }
                .sheet(isPresented: $mostrarImagePicker) {
                    ImagePicker(sourceType: .photoLibrary) {
                        imageSeleccionada in
                        selectedImage = imageSeleccionada  // Asigna la imagen seleccionada al state
                    }
                }

            // Resultados de la predicción
            VStack {
                if isAnalyzing {
                    ProgressView("Analyzing...")
                        .progressViewStyle(
                            CircularProgressViewStyle(tint: .blue)
                        )
                        .padding(.top, 20)
                } else {
                    Text(resultText)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(
                            resultText.contains("failed") ? .red : .green
                        )
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    resultText.contains("failed")
                                        ? Color.red : Color.green, lineWidth: 2)
                        )
                        .padding()
                }
            }

            Spacer()
        }
        .padding()
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                // Iniciar el análisis cuando se selecciona una nueva imagen
                analyzeImage(image)
            }
        }
    }

    // Función para analizar la imagen
    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true  // Mostrar el indicador de progreso
        resultText = "Analyzing image..."  // Cambiar el texto mientras se procesa

        // Intentar redimensionar la imagen y convertirla en un CVPixelBuffer
        guard
            let buffer = image.resize(size: CGSize(width: 224, height: 224))?
                .getCVPixelBuffer()
        else {
            resultText = "Image resize failed"
            isAnalyzing = false
            return
        }

        // Realizar la predicción con CoreML
        do {
            let config = MLModelConfiguration()
            let model = try GoogLeNetPlaces(configuration: config)
            let input = GoogLeNetPlacesInput(sceneImage: buffer)
            let output = try model.prediction(input: input)
            resultText =
                "Result: \(output.sceneLabel.replacingOccurrences(of: "_", with: " "))"  // Mostrar el resultado
        } catch {
            resultText = "Analysis failed"  // En caso de error en el análisis
            print(error.localizedDescription)
        }

        // Finalizar el análisis
        isAnalyzing = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
