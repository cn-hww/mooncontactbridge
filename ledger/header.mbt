///|
fn compare_text(left : String, right : String) -> Int {
  let common = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
  for index in 0..<common {
    let order = left.unsafe_get(index).compare(right.unsafe_get(index))
    if order != 0 {
      return order
    }
  }
  left.length().compare(right.length())
}

///|
fn split_head(head : String) -> Array[String] {
  let parts : Array[String] = []
  let current = StringBuilder()
  let mut quoted = false
  for ch in head {
    if ch == '"' {
      quoted = !quoted
      current.write_char(ch)
    } else if ch == ';' && !quoted {
      parts.push(current.to_string())
      current.reset()
    } else {
      current.write_char(ch)
    }
  }
  parts.push(current.to_string())
  parts
}

///|
fn remove_quotes(value : String) -> String {
  if value.length() >= 2 && value.has_prefix("\"") && value.has_suffix("\"") {
    value[1:value.length() - 1].to_owned()
  } else {
    value
  }
}

///|
fn canonical_type_values(value : String) -> String {
  let values : Array[String] = []
  for part in value.split(",") {
    values.push(part.trim().to_owned().to_upper())
  }
  values.sort_by(compare_text)
  values.join(",")
}

///|
fn canonical_parameter(parameter : String) -> String {
  let name = StringBuilder()
  let value = StringBuilder()
  let mut separator = false
  for ch in parameter {
    if !separator && ch == '=' {
      separator = true
    } else if separator {
      value.write_char(ch)
    } else {
      name.write_char(ch)
    }
  }
  if !separator {
    return parameter.to_upper()
  }
  let canonical_name = name.to_string().to_upper()
  let unquoted = remove_quotes(value.to_string())
  let canonical_value = if canonical_name == "TYPE" {
    canonical_type_values(unquoted)
  } else {
    unquoted
  }
  canonical_name + "=" + canonical_value
}

///|
fn canonical_property_name(value : String) -> String {
  let mut result = ""
  for part in value.split(".") {
    result = part.to_owned()
  }
  result.to_upper()
}

///|
fn canonical_head(head : String) -> String {
  let parts = split_head(head)
  if parts.length() == 0 {
    return ""
  }
  let parameters : Array[String] = []
  for index = 1; index < parts.length(); index = index + 1 {
    parameters.push(canonical_parameter(parts[index]))
  }
  parameters.sort_by(compare_text)
  let property_name = canonical_property_name(parts[0])
  if parameters.length() == 0 {
    property_name
  } else {
    property_name + ";" + parameters.join(";")
  }
}

///|
fn same_head(left : String, right : String) -> Bool {
  canonical_head(left) == canonical_head(right)
}
