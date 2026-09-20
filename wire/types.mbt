///|
pub(all) struct Field {
  source_line : Int
  head : String
  name : String
  value : String
} derive(Eq, Debug)

///|
pub(all) struct Card {
  opened_at : Int
  fields : Array[Field]
} derive(Eq, Debug)

///|
pub(all) struct Issue {
  line : Int
  detail : String
} derive(Eq, Debug)

///|
pub(all) struct Book {
  cards : Array[Card]
  issues : Array[Issue]
} derive(Eq, Debug)

///|
pub extend Field with Eq::{not_equal, equal}

///|
pub extend Field with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Card with Eq::{not_equal, equal}

///|
pub extend Card with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Issue with Eq::{not_equal, equal}

///|
pub extend Issue with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Book with Eq::{not_equal, equal}

///|
pub extend Book with @moonbitlang/core/debug.Debug::{to_repr}
