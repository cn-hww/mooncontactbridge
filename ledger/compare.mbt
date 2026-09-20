///|
pub(all) enum Finding {
  Missing(String, String)
  Changed(String, String, String)
  ParametersChanged(String, String, String)
} derive(Eq, Debug)

///|
pub extend Finding with Eq::{not_equal, equal}

///|
pub extend Finding with @moonbitlang/core/debug.Debug::{to_repr}

///|
fn fields_for(card : @wire.Card, name : String) -> Array[@wire.Field] {
  let fields : Array[@wire.Field] = []
  for field in card.fields {
    if field.name == name {
      fields.push(field)
    }
  }
  fields
}

///|
pub fn compare(before : @wire.Card, after : @wire.Card) -> Array[Finding] {
  let findings : Array[Finding] = []
  for field in before.fields {
    if field.name == "VERSION" {
      continue
    }
    let candidates = fields_for(after, field.name)
    if candidates.length() == 0 {
      findings.push(Missing(field.name, field.value))
      continue
    }
    let mut exact = false
    let mut same_value : @wire.Field? = None
    for candidate in candidates {
      if candidate.head == field.head && candidate.value == field.value {
        exact = true
      } else if candidate.value == field.value {
        same_value = Some(candidate)
      }
    }
    if exact {
      continue
    }
    match same_value {
      Some(candidate) =>
        findings.push(ParametersChanged(field.name, field.head, candidate.head))
      None =>
        findings.push(Changed(field.name, field.value, candidates[0].value))
    }
  }
  findings
}

///|
pub fn Finding::describe(self : Finding) -> String {
  match self {
    Missing(name, value) => "missing \{name}: \{value}"
    Changed(name, old, current) => "changed \{name}: \{old} -> \{current}"
    ParametersChanged(name, old, current) =>
      "changed parameters for \{name}: \{old} -> \{current}"
  }
}
