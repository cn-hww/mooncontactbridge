///|
fn main {
  let old_copy = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Lin Mei\nTEL;TYPE=cell:+886900001\nNOTE:school friend\nEND:VCARD\n",
  )
  let new_copy = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Mei Lin\nTEL:+886900001\nEND:VCARD\n",
  )
  let audit = @review.audit(old_copy, new_copy)
  println(audit.render())
  let violations = @review.evaluate(audit, @review.strict_policy())
  println("strict policy violations: \{violations.length()}")
  println("rewritten source:")
  println(@wire.write(old_copy.cards))
}
