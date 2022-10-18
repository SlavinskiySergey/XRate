import Models
import SwiftUI

struct BaseCurrencyView: View {
  let currency: Currency
  
  var body: some View {
    VStack(alignment: .leading, spacing: .zero) {
      HStack {
        Text(currency.code)
          .font(.title2)
        Image(systemName: "chevron.down")
          .resizable()
          .frame(width: 12, height: 8)
      }
      .foregroundColor(.black)
      
      Text("baseCurrency")
        .font(.subheadline)
        .foregroundColor(.gray)
    }
  }
}

struct BaseCurrencyView_Previews: PreviewProvider {
  static var previews: some View {
    BaseCurrencyView(
      currency: Currency(
        code: "USD"
      )
    )
  }
}
