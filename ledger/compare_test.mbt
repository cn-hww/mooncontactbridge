///|
fn one_card(source : String) -> @wire.Card {
  @wire.read(source).cards[0]
}

///|
test "report missing and rewritten contact details" {
  let before = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Lin Mei\nTEL;TYPE=cell:+886900001\nNOTE:met at school\nEND:VCARD\n",
  )
  let after = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Mei Lin\nTEL:+886900001\nEND:VCARD\n",
  )
  assert_eq(@ledger.compare(before, after), [
    @ledger.Changed("FN", "Lin Mei", "Mei Lin"),
    @ledger.ParametersChanged("TEL", "TEL;TYPE=cell", "TEL"),
    @ledger.Missing("NOTE", "met at school"),
  ])
}

///|
test "accept a value when one of several copies survives" {
  let before = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nEMAIL:a@home.test\nEND:VCARD\n",
  )
  let after = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nEMAIL:a@work.test\nEMAIL:a@home.test\nEND:VCARD\n",
  )
  assert_eq(@ledger.compare(before, after), [])
}

///|
test "count repeated fields independently" {
  let before = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nUID:a\nEMAIL:same@example.test\nEMAIL:same@example.test\nEND:VCARD\n",
  )
  let after = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nUID:a\nEMAIL:same@example.test\nEND:VCARD\n",
  )
  assert_eq(@ledger.compare(before, after), [
    @ledger.Missing("EMAIL", "same@example.test"),
  ])
}

///|
test "reserve exact values before pairing rewritten fields" {
  let before = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nUID:a\nEMAIL:a@example.test\nEMAIL:b@example.test\nEND:VCARD\n",
  )
  let after = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nUID:a\nEMAIL:b@example.test\nEMAIL:c@example.test\nEND:VCARD\n",
  )
  assert_eq(@ledger.compare(before, after), [
    @ledger.Changed("EMAIL", "a@example.test", "c@example.test"),
  ])
}

///|
test "do not reuse one parameterized telephone field" {
  let before = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nUID:a\nTEL;TYPE=cell:12345\nTEL;TYPE=home:12345\nEND:VCARD\n",
  )
  let after = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nUID:a\nTEL;TYPE=cell:12345\nEND:VCARD\n",
  )
  assert_eq(@ledger.compare(before, after), [@ledger.Missing("TEL", "12345")])
}
