public typealias BBRender<K: Hashable, V, R> = @Sendable (BBNode, [K: V]?) -> R
