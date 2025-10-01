import gleam/dict
import gleam/result

pub opaque type Counter(a) {
  Counter(dict: dict.Dict(a, Int))
}

pub fn new() -> Counter(a) {
  Counter(dict: dict.new())
}

/// Increments the count of `element`.
/// 
/// If `elemented` has never been incremented before, then it will be set to 1.
pub fn increment(counter counter: Counter(a), element element: a) -> Counter(a) {
  let new_count = get(counter:, element:) + 1
  let new_dict = dict.insert(counter.dict, element, new_count)
  Counter(dict: new_dict)
}

/// Gets the count of `element`.
/// 
/// Returns 0, if `element` has never been incremented before.
pub fn get(counter counter: Counter(a), element element: a) -> Int {
  counter.dict
  |> dict.get(element)
  |> result.unwrap(0)
}
