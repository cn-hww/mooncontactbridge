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
test "report an extra value when one of several copies survives" {
  let before = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nEMAIL:a@home.test\nEND:VCARD\n",
  )
  let after = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nEMAIL:a@work.test\nEMAIL:a@home.test\nEND:VCARD\n",
  )
  assert_eq(@ledger.compare(before, after), [
    @ledger.Added("EMAIL", "a@work.test"),
  ])
}

///|
test "report target-only contact details after source findings" {
  let before = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nUID:a\nNOTE:old\nEND:VCARD\n",
  )
  let after = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nUID:a\nNOTE:new\nTEL:12345\nEMAIL:a@example.test\nEND:VCARD\n",
  )
  assert_eq(@ledger.compare(before, after), [
    @ledger.Changed("NOTE", "old", "new"),
    @ledger.Added("TEL", "12345"),
    @ledger.Added("EMAIL", "a@example.test"),
  ])
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

///|
test "ignore parameter order and case-only spelling changes" {
  let before = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nUID:a\nTEL;TYPE=cell;PREF=1:12345\nEND:VCARD\n",
  )
  let after = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nUID:a\ntel;pref=1;type=CELL:12345\nEND:VCARD\n",
  )
  assert_eq(@ledger.compare(before, after), [])
}

///|
test "keep quoted semicolons inside reordered parameters" {
  let before = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nUID:a\nX-TEST;X-LABEL=\"a;b\";TYPE=home:value\nEND:VCARD\n",
  )
  let after = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nUID:a\nx-test;type=HOME;x-label=\"a;b\":value\nEND:VCARD\n",
  )
  assert_eq(@ledger.compare(before, after), [])
}

///|
test "report a real parameter value change" {
  let before = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nUID:a\nTEL;TYPE=cell:12345\nEND:VCARD\n",
  )
  let after = one_card(
    "BEGIN:VCARD\nVERSION:4.0\nFN:A\nUID:a\nTEL;TYPE=home:12345\nEND:VCARD\n",
  )
  assert_eq(@ledger.compare(before, after), [
    @ledger.ParametersChanged("TEL", "TEL;TYPE=cell", "TEL;TYPE=home"),
  ])
}
