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
