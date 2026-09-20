///|
test "unfold lines and retain grouped extension fields" {
  let book = @wire.read(
    "BEGIN:VCARD\r\nVERSION:4.0\r\nFN:Mei\r\n Ling\r\nitem2.X-LABEL;LANGUAGE=zh:家人\r\nEND:VCARD\r\n",
  )
  assert_eq(book.issues, [])
  assert_eq(book.cards.length(), 1)
  assert_eq(book.cards[0].fields[1].value, "MeiLing")
  assert_eq(book.cards[0].fields[2].name, "X-LABEL")
  assert_eq(book.cards[0].fields[2].source_line, 5)
}

///|
test "continue after an abandoned card" {
  let book = @wire.read(
    "BEGIN:VCARD\nFN:Old\nBEGIN:VCARD\nVERSION:4.0\nFN:New\nEND:VCARD\n",
  )
  assert_eq(book.cards.length(), 1)
  assert_eq(book.issues.length(), 1)
  assert_eq(book.issues[0].line, 1)
}
