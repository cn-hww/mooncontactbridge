///|
fn without_prefix(value : String, prefix : String) -> String {
  if value.to_lower().has_prefix(prefix) {
    value[prefix.length():].to_owned()
  } else {
    value
  }
}

///|
fn normalized_email(value : String) -> String {
  let address = without_prefix(value.trim().to_owned(), "mailto:")
  let mailbox = StringBuilder()
  let domain = StringBuilder()
  let mut separator_count = 0
  for ch in address {
    if ch == '@' {
      separator_count += 1
    } else if separator_count == 0 {
      mailbox.write_char(ch)
    } else {
      domain.write_char(ch)
    }
  }
  let mailbox_text = mailbox.to_string()
  let domain_text = domain.to_string()
  if separator_count == 1 &&
    mailbox_text.length() > 0 &&
    domain_text.length() > 0 {
    mailbox_text + "@" + domain_text.to_lower()
  } else {
    address
  }
}

///|
fn normalized_telephone(value : String) -> String {
  let number = without_prefix(value.trim().to_owned(), "tel:")
  let result = StringBuilder()
  let mut parameters = false
  for ch in number {
    if ch == ';' {
      parameters = true
      result.write_char(ch)
    } else if !parameters &&
      (
        ch == ' ' ||
        ch == '\t' ||
        ch == '-' ||
        ch == '(' ||
        ch == ')' ||
        ch == '.'
      ) {
      continue
    } else {
      result.write_char(ch)
    }
  }
  result.to_string()
}

///|
fn identity_value(name : String, value : String) -> String {
  match name {
    "EMAIL" => normalized_email(value)
    "TEL" => normalized_telephone(value)
    _ => value
  }
}
