///|
test "write short cards with stable CRLF output" {
  let parsed = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Mei Lin\nitem1.X-COLOR:blue\nEND:VCARD\n",
  )
  assert_eq(
    @wire.write(parsed.cards),
    "BEGIN:VCARD\r\nVERSION:4.0\r\nFN:Mei Lin\r\nitem1.X-COLOR:blue\r\nEND:VCARD\r\n",
  )
}

///|
test "fold UTF-8 without changing fields after a round trip" {
  let note = StringBuilder()
  for _ in 0..<68 {
    note.write_char('a')
  }
  note.write_string("中文结尾")
  let source = "BEGIN:VCARD\nVERSION:4.0\nFN:Mei Lin\nNOTE:\{note.to_string()}\nEND:VCARD\n"
  let first = @wire.read(source)
  let encoded = @wire.write(first.cards)
  assert_true(encoded.contains("\r\n 中"))
  for line in encoded.split("\r\n") {
    assert_true(@utf8.encode(line.to_owned()).length() <= 75)
  }
  let second = @wire.read(encoded)
  assert_eq(second.issues, [])
  assert_eq(second.cards.length(), 1)
  assert_eq(second.cards[0].fields.length(), first.cards[0].fields.length())
  for index = 0; index < first.cards[0].fields.length(); index = index + 1 {
    assert_eq(
      second.cards[0].fields[index].head,
      first.cards[0].fields[index].head,
    )
    assert_eq(
      second.cards[0].fields[index].value,
      first.cards[0].fields[index].value,
    )
  }
}
