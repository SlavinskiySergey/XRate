import Models
import SwiftUI

struct RateDetailsRowView: View {
  let rateDetails: RateDetails
  
  var body: some View {
    HStack(alignment: .bottom) {
      Text(rateDetails.date).bold()
      Text(" · ").bold()
      Text("\(rateDetails.value.formatted())")
      Spacer()
    }
    .padding([.leading, .trailing, .bottom])
  }
}

struct RateDetailsRowView_Previews: PreviewProvider {
  static var previews: some View {
    RateDetailsRowView(
      rateDetails: RateDetails(
        date: "2022-05-07",
        value: 2.33
      )
    )
  }
}
