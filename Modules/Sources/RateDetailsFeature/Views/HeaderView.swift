import SwiftUI

public struct HeaderView: View {
  let text: String
  
  public init(text: String) {
    self.text = text
  }
  
  public var body: some View {
    HStack {
      Text(text.uppercased())
        .foregroundColor(.gray)
        .font(.headline)
        .padding()
      Spacer()
    }
  }
}


struct HeaderView_Previews: PreviewProvider {
  static var previews: some View {
    HeaderView(
      text: "HeaderView_Previews"
    )
  }
}
