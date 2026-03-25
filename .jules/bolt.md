## 2024-03-25 - AppSnapshot Getter Optimization
**Learning:** In Dart/Flutter, computing values inside getters of an immutable state class (like `AppSnapshot`) causes them to be recalculated every time the getter is accessed, which can happen frequently during widget rebuilds.
**Action:** Use `late final` fields initialized with IIFEs for complex computed properties to memoize their results on immutable objects. Note that doing so requires removing the `const` keyword from the class constructors, which in turn requires updating all instantiation sites to remove `const`.
