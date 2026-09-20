///|
priv enum Cursor {
  Waiting
  Collecting(Int, Array[Field])
}

///|
fn logical_lines(text : String) -> Array[(Int, String)] {
  let result : Array[(Int, String)] = []
  let mut physical = 0
  for view in text.split("\n") {
    physical += 1
    let line = view.trim_end(chars="\r").to_owned()
    if line.has_prefix(" ") || line.has_prefix("\t") {
      match result.pop() {
        Some((first_line, previous)) =>
          result.push((first_line, previous + line[1:].to_owned()))
        None => result.push((physical, line))
      }
    } else if line.length() > 0 {
      result.push((physical, line))
    }
  }
  result
}

///|
fn name_from_head(head : String) -> String {
  let property = StringBuilder()
  for ch in head {
    if ch == ';' {
      break
    }
    property.write_char(ch)
  }
  let mut name = ""
  for piece in property.to_string().split(".") {
    name = piece.to_owned()
  }
  name.to_upper()
}

///|
fn decode_field(line_number : Int, line : String) -> Field? {
  let head = StringBuilder()
  let value = StringBuilder()
  let mut found_separator = false
  let mut quoted = false
  for ch in line {
    if !found_separator && ch == '"' {
      quoted = !quoted
    }
    if !found_separator && !quoted && ch == ':' {
      found_separator = true
    } else if found_separator {
      value.write_char(ch)
    } else {
      head.write_char(ch)
    }
  }
  let raw_head = head.to_string()
  let name = name_from_head(raw_head)
  guard found_separator && name.length() > 0 else { return None }
  Some({
    source_line: line_number,
    head: raw_head,
    name,
    value: value.to_string(),
  })
}

///|
fn finish_card(
  start : Int,
  fields : Array[Field],
  cards : Array[Card],
  issues : Array[Issue],
) -> Unit {
  let mut has_version = false
  let mut has_name = false
  for field in fields {
    if field.name == "VERSION" && field.value == "4.0" {
      has_version = true
    }
    if field.name == "FN" && field.value.length() > 0 {
      has_name = true
    }
  }
  if !has_version {
    issues.push({ line: start, detail: "expected VERSION:4.0", })
  }
  if !has_name {
    issues.push({ line: start, detail: "card has no formatted name", })
  }
  cards.push({ opened_at: start, fields, })
}

///|
pub fn read(text : String) -> Book {
  let cards : Array[Card] = []
  let issues : Array[Issue] = []
  let mut cursor = Waiting
  for (line_number, line) in logical_lines(text) {
    let marker = line.to_upper()
    if marker == "BEGIN:VCARD" {
      match cursor {
        Waiting => ()
        Collecting(start, _) =>
          issues.push({ line: start, detail: "card was not closed", })
      }
      cursor = Collecting(line_number, [])
    } else if marker == "END:VCARD" {
      match cursor {
        Waiting =>
          issues.push({ line: line_number, detail: "unexpected END:VCARD", })
        Collecting(start, fields) => {
          finish_card(start, fields, cards, issues)
          cursor = Waiting
        }
      }
    } else {
      match cursor {
        Waiting =>
          issues.push({ line: line_number, detail: "content outside a card", })
        Collecting(_, fields) =>
          match decode_field(line_number, line) {
            Some(field) => fields.push(field)
            None =>
              issues.push({
                line: line_number,
                detail: "malformed content line",
              })
          }
      }
    }
  }
  match cursor {
    Waiting => ()
    Collecting(start, _) =>
      issues.push({ line: start, detail: "card was not closed", })
  }
  { cards, issues, }
}
