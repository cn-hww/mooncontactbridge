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
