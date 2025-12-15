// MARK: - Transformable

protocol Transformable {
    /// A function that allows _inline_ transformation of a type, 
    /// enabling inline chaining.
    func transform(_ transformer: (Self) -> Self) -> Self
}