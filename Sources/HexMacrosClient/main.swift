import HexMacros
import Foundation
let a = 17
let b = 25

let (result, code) = #stringify(a + b)

@Identifiable()
struct SomeStruct {
    let id: Int
    var someProperty: Int
}


struct OtherStruct {
    var id:UUID
}



print("The value \(result) was produced by the code \"\(code)\"")

struct SomeTruct {
  var id = UUID()
}
