///|
pub(all) struct CardRef {
  index : Int
  name : String
} derive(Eq, Debug)

///|
pub(all) struct ContactReview {
  source : CardRef
  target : CardRef
  key : @ledger.MatchKey
  findings : Array[@ledger.Finding]
} derive(Eq, Debug)

///|
pub(all) struct Audit {
  matched : Array[ContactReview]
  removed : Array[CardRef]
  added : Array[CardRef]
  source_issues : Array[@wire.Issue]
  target_issues : Array[@wire.Issue]
} derive(Eq, Debug)

///|
pub extend CardRef with Eq::{not_equal, equal}

///|
pub extend CardRef with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ContactReview with Eq::{not_equal, equal}

///|
pub extend ContactReview with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Audit with Eq::{not_equal, equal}

///|
pub extend Audit with @moonbitlang/core/debug.Debug::{to_repr}

///|
fn display_name(card : @wire.Card) -> String {
  for field in card.fields {
    if field.name == "FN" && field.value.length() > 0 {
      return field.value
    }
  }
  "(unnamed)"
}

///|
fn card_ref(index : Int, cards : Array[@wire.Card]) -> CardRef {
  { index, name: display_name(cards[index]), }
}

///|
pub fn audit(source : @wire.Book, target : @wire.Book) -> Audit {
  let alignment = @ledger.align(source, target)
  let matched : Array[ContactReview] = []
  for pair in alignment.pairs {
    matched.push({
      source: card_ref(pair.before_index, source.cards),
      target: card_ref(pair.after_index, target.cards),
      key: pair.key,
      findings: @ledger.compare(
        source.cards[pair.before_index],
        target.cards[pair.after_index],
      ),
    })
  }
  let removed : Array[CardRef] = []
  for index in alignment.removed {
    removed.push(card_ref(index, source.cards))
  }
  let added : Array[CardRef] = []
  for index in alignment.added {
    added.push(card_ref(index, target.cards))
  }
  {
    matched,
    removed,
    added,
    source_issues: source.issues.copy(),
    target_issues: target.issues.copy(),
  }
}

///|
pub fn Audit::is_clean(self : Audit) -> Bool {
  if self.removed.length() > 0 ||
    self.added.length() > 0 ||
    self.source_issues.length() > 0 ||
    self.target_issues.length() > 0 {
    return false
  }
  for contact in self.matched {
    if contact.findings.length() > 0 {
      return false
    }
  }
  true
}

///|
fn key_text(key : @ledger.MatchKey) -> String {
  match key {
    @ledger.Uid(value) => "UID \{value}"
    @ledger.Email(value) => "EMAIL \{value}"
    @ledger.Telephone(value) => "TEL \{value}"
  }
}

///|
pub fn Audit::render(self : Audit) -> String {
  let out = StringBuilder()
  out.write_string(
    "matched \{self.matched.length()}, removed \{self.removed.length()}, added \{self.added.length()}\n",
  )
  for contact in self.matched {
    out.write_string(
      "contact \{contact.source.name} -> \{contact.target.name} [\{key_text(contact.key)}]\n",
    )
    for finding in contact.findings {
      out.write_string("  \{finding.describe()}\n")
    }
  }
  for contact in self.removed {
    out.write_string("removed #\{contact.index + 1}: \{contact.name}\n")
  }
  for contact in self.added {
    out.write_string("added #\{contact.index + 1}: \{contact.name}\n")
  }
  for issue in self.source_issues {
    out.write_string("source line \{issue.line}: \{issue.detail}\n")
  }
  for issue in self.target_issues {
    out.write_string("target line \{issue.line}: \{issue.detail}\n")
  }
  out.to_string()
}
