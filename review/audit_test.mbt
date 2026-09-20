///|
test "build a deterministic whole-book migration report" {
  let source = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Ada\nUID:a\nEND:VCARD\nBEGIN:VCARD\nVERSION:4.0\nFN:Bo\nEMAIL:bo@example.test\nNOTE:school\nEND:VCARD\n",
  )
  let target = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Ada\nUID:a\nEND:VCARD\nBEGIN:VCARD\nVERSION:4.0\nFN:Bo New\nEMAIL:bo@example.test\nEND:VCARD\nBEGIN:VCARD\nVERSION:4.0\nFN:Cai\nUID:c\nEND:VCARD\n",
  )
  let result = @review.audit(source, target)
  assert_false(result.is_clean())
  assert_eq(
    result.render(),
    (
      #|matched 2, removed 0, added 1
      #|contact Ada -> Ada [UID a]
      #|contact Bo -> Bo New [EMAIL bo@example.test]
      #|  changed FN: Bo -> Bo New
      #|  missing NOTE: school
      #|added #3: Cai
      #|
    ),
  )
}

///|
test "clean audit requires equal cards and valid input" {
  let text = "BEGIN:VCARD\nVERSION:4.0\nFN:Ada\nUID:a\nEND:VCARD\n"
  let result = @review.audit(@wire.read(text), @wire.read(text))
  assert_true(result.is_clean())
  assert_eq(
    result.render(),
    "matched 1, removed 0, added 0\ncontact Ada -> Ada [UID a]\n",
  )
}

///|
test "carry parser diagnostics into the audit" {
  let source = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Ada\nUID:a\nEND:VCARD\n",
  )
  let target = @wire.read(
    "outside\nBEGIN:VCARD\nVERSION:4.0\nFN:Ada\nUID:a\nEND:VCARD\n",
  )
  let result = @review.audit(source, target)
  assert_false(result.is_clean())
  assert_true(result.render().contains("target line 1: content outside a card"))
}
