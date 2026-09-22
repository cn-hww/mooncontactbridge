///|
pub(all) enum MatchKey {
  Uid(String)
  Email(String)
  Telephone(String)
} derive(Eq, Debug)

///|
pub(all) struct Pairing {
  before_index : Int
  after_index : Int
  key : MatchKey
} derive(Eq, Debug)

///|
pub(all) struct Alignment {
  pairs : Array[Pairing]
  removed : Array[Int]
  added : Array[Int]
} derive(Eq, Debug)

///|
pub extend MatchKey with Eq::{not_equal, equal}

///|
pub extend MatchKey with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Pairing with Eq::{not_equal, equal}

///|
pub extend Pairing with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Alignment with Eq::{not_equal, equal}

///|
pub extend Alignment with @moonbitlang/core/debug.Debug::{to_repr}

///|
fn card_has(card : @wire.Card, name : String, identity : String) -> Bool {
  for field in card.fields {
    if field.name == name && identity_value(name, field.value) == identity {
      return true
    }
  }
  false
}

///|
fn locate_unique(
  source : @wire.Card,
  sources : Array[@wire.Card],
  targets : Array[@wire.Card],
  claimed : Array[Bool],
  name : String,
) -> (Int, String)? {
  for field in source.fields {
    let identity = identity_value(name, field.value)
    if field.name != name || identity.length() == 0 {
      continue
    }
    let mut source_count = 0
    for card in sources {
      if card_has(card, name, identity) {
        source_count += 1
      }
    }
    if source_count != 1 {
      continue
    }
    let mut found = -1
    let mut count = 0
    for index = 0; index < targets.length(); index = index + 1 {
      if card_has(targets[index], name, identity) {
        found = index
        count += 1
      }
    }
    if count == 1 && !claimed[found] {
      return Some((found, field.value))
    }
  }
  None
}

///|
fn choose_pair(
  source : @wire.Card,
  sources : Array[@wire.Card],
  targets : Array[@wire.Card],
  claimed : Array[Bool],
) -> (Int, MatchKey)? {
  match locate_unique(source, sources, targets, claimed, "UID") {
    Some((index, value)) => Some((index, Uid(value)))
    None =>
      match locate_unique(source, sources, targets, claimed, "EMAIL") {
        Some((index, value)) => Some((index, Email(value)))
        None =>
          match locate_unique(source, sources, targets, claimed, "TEL") {
            Some((index, value)) => Some((index, Telephone(value)))
            None => None
          }
      }
  }
}

///|
pub fn align(before : @wire.Book, after : @wire.Book) -> Alignment {
  let claimed : Array[Bool] = []
  for _ in after.cards {
    claimed.push(false)
  }
  let pairs : Array[Pairing] = []
  let removed : Array[Int] = []
  for before_index = 0
      before_index < before.cards.length()
      before_index = before_index + 1 {
    match
      choose_pair(
        before.cards[before_index],
        before.cards,
        after.cards,
        claimed,
      ) {
      Some((after_index, key)) => {
        claimed[after_index] = true
        pairs.push({ before_index, after_index, key, })
      }
      None => removed.push(before_index)
    }
  }
  let added : Array[Int] = []
  for after_index = 0
      after_index < after.cards.length()
      after_index = after_index + 1 {
    if !claimed[after_index] {
      added.push(after_index)
    }
  }
  { pairs, removed, added, }
}
