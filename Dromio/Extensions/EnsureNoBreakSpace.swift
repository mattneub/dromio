import Foundation

/*
 Replace an empty/zero or nil value with a no-break space.

 We have a problem with layout of cells that display a visual representation of a response type.
 We want string text in labels to have some invisible value always, so that the labels have
 size under autolayout.
 Unfortunately in some situations where the server has no useful value to provide for a property,
 it provides an empty/zero value as a placeholder rather than just omitting that property.
 So our solution is to characterize these as Optional and then unwrap / coerce them with these computed
 properties.
 */

extension Optional where Wrapped == String {
    var ensureNoBreakSpace: String {
        self.flatMap { $0.isEmpty ? " " : $0} ?? " "
    }
}

extension Optional where Wrapped == Int {
    var ensureNoBreakSpace: String {
        self.flatMap { $0 == 0 ? " " : String($0) } ?? " "
    }
}
