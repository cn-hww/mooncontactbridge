///|
pub(all) struct AcceptancePolicy {
  allow_added_contacts : Bool
  allow_removed_contacts : Bool
  allow_missing_fields : Bool
  allow_changed_values : Bool
  allow_parameter_changes : Bool
  allow_input_issues : Bool
} derive(Eq, Debug)

///|
pub(all) enum Violation {
  InvalidSource(Int, String)
  InvalidTarget(Int, String)
  RemovedContact(Int, String)
  AddedContact(Int, String)
  MissingField(Int, String, String)
  ChangedValue(Int, String, String, String)
  ChangedParameters(Int, String, String, String)
} derive(Eq, Debug)

///|
pub extend AcceptancePolicy with Eq::{not_equal, equal}

///|
pub extend AcceptancePolicy with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Violation with Eq::{not_equal, equal}

///|
pub extend Violation with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub fn strict_policy() -> AcceptancePolicy {
  {
    allow_added_contacts: false,
    allow_removed_contacts: false,
    allow_missing_fields: false,
    allow_changed_values: false,
    allow_parameter_changes: false,
    allow_input_issues: false,
  }
}

///|
/// Allow new contacts while requiring every source contact and field to survive.
pub fn additive_policy() -> AcceptancePolicy {
  { ..strict_policy(), allow_added_contacts: true, }
}

///|
pub fn evaluate(audit : Audit, policy : AcceptancePolicy) -> Array[Violation] {
  let violations : Array[Violation] = []
  if !policy.allow_input_issues {
    for issue in audit.source_issues {
      violations.push(InvalidSource(issue.line, issue.detail))
    }
    for issue in audit.target_issues {
      violations.push(InvalidTarget(issue.line, issue.detail))
    }
  }
  for contact in audit.matched {
    for finding in contact.findings {
      match finding {
        @ledger.Missing(name, value) =>
          if !policy.allow_missing_fields {
            violations.push(MissingField(contact.source.index, name, value))
          }
        @ledger.Changed(name, old, current) =>
          if !policy.allow_changed_values {
            violations.push(
              ChangedValue(contact.source.index, name, old, current),
            )
          }
        @ledger.ParametersChanged(name, old, current) =>
          if !policy.allow_parameter_changes {
            violations.push(
              ChangedParameters(contact.source.index, name, old, current),
            )
          }
      }
    }
  }
  if !policy.allow_removed_contacts {
    for contact in audit.removed {
      violations.push(RemovedContact(contact.index, contact.name))
    }
  }
  if !policy.allow_added_contacts {
    for contact in audit.added {
      violations.push(AddedContact(contact.index, contact.name))
    }
  }
  violations
}

///|
pub fn passes(audit : Audit, policy : AcceptancePolicy) -> Bool {
  evaluate(audit, policy).length() == 0
}
