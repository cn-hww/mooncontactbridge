///|
test "strict policy returns actionable migration violations" {
  let source = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Ada\nUID:a\nNOTE:school\nEND:VCARD\n",
  )
  let target = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Ada New\nUID:a\nEND:VCARD\nBEGIN:VCARD\nVERSION:4.0\nFN:Bo\nUID:b\nEND:VCARD\n",
  )
  let result = @review.evaluate(
    @review.audit(source, target),
    @review.strict_policy(),
  )
  assert_eq(result, [
    @review.ChangedValue(0, "FN", "Ada", "Ada New"),
    @review.MissingField(0, "NOTE", "school"),
    @review.AddedContact(1, "Bo"),
  ])
}

///|
test "additive policy permits only new contacts" {
  let source = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Ada\nUID:a\nEND:VCARD\n",
  )
  let target = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Ada\nUID:a\nEND:VCARD\nBEGIN:VCARD\nVERSION:4.0\nFN:Bo\nUID:b\nEND:VCARD\n",
  )
  let audit = @review.audit(source, target)
  assert_false(@review.passes(audit, @review.strict_policy()))
  assert_true(@review.passes(audit, @review.additive_policy()))
  let reverse = @review.audit(target, source)
  assert_false(@review.passes(reverse, @review.additive_policy()))
}

///|
test "input diagnostics fail both built-in policies" {
  let source = @wire.read(
    "outside\nBEGIN:VCARD\nVERSION:4.0\nFN:Ada\nUID:a\nEND:VCARD\n",
  )
  let target = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Ada\nUID:a\nEND:VCARD\n",
  )
  let audit = @review.audit(source, target)
  assert_eq(@review.evaluate(audit, @review.additive_policy()), [
    @review.InvalidSource(1, "content outside a card"),
  ])
}

///|
test "strict policy rejects fields added to a matched contact" {
  let source = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Ada\nUID:a\nEND:VCARD\n",
  )
  let target = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Ada\nUID:a\nEMAIL:ada@example.test\nEND:VCARD\n",
  )
  let audit = @review.audit(source, target)
  assert_eq(@review.evaluate(audit, @review.strict_policy()), [
    @review.AddedField(0, "EMAIL", "ada@example.test"),
  ])
  assert_false(@review.passes(audit, @review.additive_policy()))
}
