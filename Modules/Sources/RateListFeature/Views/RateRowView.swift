import Models
import SwiftUI

struct RateRowView: View {
  let rate: Rate
  
  var body: some View {
    HStack(alignment: .bottom) {
      Text(rate.code).bold()
      Text(" · ").bold()
      Text("\(rate.value.formatted())")
      Spacer()
    }
    .padding([.leading, .trailing, .bottom])
  }
}

struct RateRowView_Previews: PreviewProvider {
  static var previews: some View {
    RateRowView(
      rate: Rate(
        code: "$",
        value: 2.55
      )
    )
  }
}
