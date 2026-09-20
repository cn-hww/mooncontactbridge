///|
fn main {
  let old_copy = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Lin Mei\nTEL;TYPE=cell:+886900001\nNOTE:school friend\nEND:VCARD\n",
  )
  let new_copy = @wire.read(
    "BEGIN:VCARD\nVERSION:4.0\nFN:Mei Lin\nTEL:+886900001\nEND:VCARD\n",
  )
  let alignment = @ledger.align(old_copy, new_copy)
  println("matched contacts: \{alignment.pairs.length()}")
  for pair in alignment.pairs {
    for
      finding in @ledger.compare(
        old_copy.cards[pair.before_index],
        new_copy.cards[pair.after_index],
      ) {
      println(finding.describe())
    }
  }
}
