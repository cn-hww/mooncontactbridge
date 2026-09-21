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
pub fn compare(before : @wire.Card, after : @wire.Card) -> Array[Finding] {
  let source_claimed = Array::make(before.fields.length(), false)
  let target_claimed = Array::make(after.fields.length(), false)
  let by_source : Array[Finding?] = Array::make(before.fields.length(), None)
  for source_index = 0
      source_index < before.fields.length()
      source_index = source_index + 1 {
    let source = before.fields[source_index]
    if source.name == "VERSION" {
      source_claimed[source_index] = true
      continue
    }
    for target_index = 0
        target_index < after.fields.length()
        target_index = target_index + 1 {
      let target = after.fields[target_index]
      if !target_claimed[target_index] &&
        target.name == source.name &&
        target.head == source.head &&
        target.value == source.value {
        source_claimed[source_index] = true
        target_claimed[target_index] = true
        break
      }
    }
  }
  for source_index = 0
      source_index < before.fields.length()
      source_index = source_index + 1 {
    if source_claimed[source_index] {
      continue
    }
    let source = before.fields[source_index]
    for target_index = 0
        target_index < after.fields.length()
        target_index = target_index + 1 {
      let target = after.fields[target_index]
      if !target_claimed[target_index] &&
        target.name == source.name &&
        target.value == source.value {
        source_claimed[source_index] = true
        target_claimed[target_index] = true
        by_source[source_index] = Some(
          ParametersChanged(source.name, source.head, target.head),
        )
        break
      }
    }
  }
  for source_index = 0
      source_index < before.fields.length()
      source_index = source_index + 1 {
    if source_claimed[source_index] {
      continue
    }
    let source = before.fields[source_index]
    for target_index = 0
        target_index < after.fields.length()
        target_index = target_index + 1 {
      let target = after.fields[target_index]
      if !target_claimed[target_index] && target.name == source.name {
        source_claimed[source_index] = true
        target_claimed[target_index] = true
        by_source[source_index] = Some(
          Changed(source.name, source.value, target.value),
        )
        break
      }
    }
  }
  for source_index = 0
      source_index < before.fields.length()
      source_index = source_index + 1 {
    if !source_claimed[source_index] {
      let source = before.fields[source_index]
      by_source[source_index] = Some(Missing(source.name, source.value))
    }
  }
  let findings : Array[Finding] = []
  for item in by_source {
    match item {
      Some(finding) => findings.push(finding)
      None => ()
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
