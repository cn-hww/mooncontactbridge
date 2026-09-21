///|
fn book(source : String) -> @wire.Book {
  @wire.read(source)
}

///|
test "align reordered cards by stable contact fields" {
  let before = book(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Ada\nUID:person-a\nEND:VCARD\nBEGIN:VCARD\nVERSION:4.0\nFN:Bo\nEMAIL:bo@example.test\nEND:VCARD\n",
  )
  let after = book(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Bo Renamed\nEMAIL:bo@example.test\nEND:VCARD\nBEGIN:VCARD\nVERSION:4.0\nFN:Ada\nUID:person-a\nEND:VCARD\nBEGIN:VCARD\nVERSION:4.0\nFN:Cai\nEMAIL:cai@example.test\nEND:VCARD\n",
  )
  assert_eq(@ledger.align(before, after), @ledger.Alignment::{
    pairs: [
      { before_index: 0, after_index: 1, key: @ledger.Uid("person-a"), },
      {
        before_index: 1,
        after_index: 0,
        key: @ledger.Email("bo@example.test"),
      },
    ],
    removed: [],
    added: [2],
  })
}

///|
test "leave shared telephone numbers unresolved" {
  let before = book("BEGIN:VCARD\nVERSION:4.0\nFN:Home\nTEL:12345\nEND:VCARD\n")
  let after = book(
    "BEGIN:VCARD\nVERSION:4.0\nFN:One\nTEL:12345\nEND:VCARD\nBEGIN:VCARD\nVERSION:4.0\nFN:Two\nTEL:12345\nEND:VCARD\n",
  )
  let result = @ledger.align(before, after)
  assert_eq(result.pairs, [])
  assert_eq(result.removed, [0])
  assert_eq(result.added, [0, 1])
}

///|
test "pair telephone numbers across common display formatting" {
  let before = book(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Lin\nTEL:tel:+886 (900)-001.22\nEND:VCARD\n",
  )
  let after = book(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Lin\nTEL:+88690000122\nEND:VCARD\n",
  )
  assert_eq(@ledger.align(before, after).pairs, [
    {
      before_index: 0,
      after_index: 0,
      key: @ledger.Telephone("tel:+886 (900)-001.22"),
    },
  ])
}

///|
test "pair email addresses while preserving local-part case" {
  let before = book(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Lin\nEMAIL:User@EXAMPLE.COM\nEND:VCARD\n",
  )
  let after = book(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Lin\nEMAIL:mailto:User@example.com\nEND:VCARD\n",
  )
  assert_eq(@ledger.align(before, after).pairs, [
    { before_index: 0, after_index: 0, key: @ledger.Email("User@EXAMPLE.COM"), },
  ])

  let changed_local = book(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Lin\nEMAIL:user@example.com\nEND:VCARD\n",
  )
  let result = @ledger.align(before, changed_local)
  assert_eq(result.pairs, [])
  assert_eq(result.removed, [0])
  assert_eq(result.added, [0])
}

///|
test "leave normalized telephone collisions unresolved" {
  let before = book(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Desk\nTEL:+1 555-0100\nEND:VCARD\n",
  )
  let after = book(
    "BEGIN:VCARD\nVERSION:4.0\nFN:One\nTEL:tel:+15550100\nEND:VCARD\nBEGIN:VCARD\nVERSION:4.0\nFN:Two\nTEL:+1(555)0100\nEND:VCARD\n",
  )
  let result = @ledger.align(before, after)
  assert_eq(result.pairs, [])
  assert_eq(result.removed, [0])
  assert_eq(result.added, [0, 1])
}
