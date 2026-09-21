///|
fn utf8_width(ch : Char) -> Int {
  let value = ch.to_int()
  if value <= 0x7f {
    1
  } else if value <= 0x7ff {
    2
  } else if value <= 0xffff {
    3
  } else {
    4
  }
}

///|
fn write_folded_line(output : StringBuilder, line : String) -> Unit {
  let mut column = 0
  for ch in line {
    let width = utf8_width(ch)
    if column + width > 75 {
      output.write_string("\r\n ")
      column = 1
    }
    output.write_char(ch)
    column += width
  }
  output.write_string("\r\n")
}

///|
/// Serialize parsed cards as vCard text with CRLF endings and 75-octet folding.
pub fn write(cards : Array[Card]) -> String {
  let output = StringBuilder()
  for card in cards {
    output.write_string("BEGIN:VCARD\r\n")
    for field in card.fields {
      write_folded_line(output, field.head + ":" + field.value)
    }
    output.write_string("END:VCARD\r\n")
  }
  output.to_string()
}
