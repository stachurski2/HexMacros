HexMacros

Two Swift Macros 

`@autoId` - expands class or structure with attribute `let id = UUID()` 
example usage:
```
@autoId()
struct SomeStruct { }
```
after expansion it looks like:
```
@autoId()
sturct SomeStruct{
let id = UUID()
}
```


`@Identifiable` - it adds to class/struct confromance to protocol `Identifiable` with property `id` if it is declared:
example usages:
1. With declared id 
```
@Identifiable()
struct SomeStruct {
  let id = UUID()
}
```
after expansion it looks like:
```
@Identifiable()
struct SomeStruct {
  let id = UUID()
}
extension SomeStruct: Identifiable {} 
```
2. With  property `identifier`, which we want to identify :
```
@Identifiable("identifier")
struct SomeStruct {
  let identifier:Int
}
```
after expansion it looks like:
```
@Identifiable("identifier")
struct SomeStruct {
  let identifier:Int
}
extension SomeStruct: Identifiable {
  var id: Int {
    identifier
  }
} 
```

It's also possible to combine two macros like: 

```
@autoId()
@Identifiable()
struct SomeStruct { }
```











