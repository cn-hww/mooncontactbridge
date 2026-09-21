# mooncontactbridge

换通讯录软件时，导入成功不等于资料完整。手机号码可能还在，号码标签、备注、地址或自定义字段却已经丢了。

mooncontactbridge 先做一件小事：读取迁移前后的 vCard 4.0 文本，列出消失和被改写的内容行。它是纯 MoonBit 库，输入输出不绑定文件系统，可以放进命令行工具、网页或测试程序里。

```moonbit
let old_book = @wire.read(old_vcf)
let new_book = @wire.read(new_vcf)
let report = @review.audit(old_book, new_book)
println(report.render())
let accepted = @review.passes(report, @review.additive_policy())
let portable_copy = @wire.write(old_book.cards)
```

目前有三个包：

- `wire` 负责展开折行、拆分多张名片、保留原始字段头和值，并按 75 个 UTF-8 字节折行写回 vCard；
- `ledger` 先用 UID、邮箱或电话号码配对联系人，再逐项区分字段消失、字段值变化和参数变化；
- `review` 生成整本通讯录的确定性报告，并带上新增、删除联系人和输入诊断。

解析器要求每张卡包含 `VERSION:4.0` 和 `FN`。参数和未知的 `X-` 字段会原样进入模型，便于后续检查。联系人配对只接受唯一候选；若多个联系人共享号码或邮箱，会保留为未匹配项，交给调用方决定。

配对时，电话号码会忽略 `tel:` 前缀、空格、连字符、括号和点；邮箱会忽略 `mailto:` 前缀与域名大小写。本地部分仍区分大小写，也不会猜测国家码，因此格式相近但含义不明确的号码不会被强行合并。

同一联系人可以包含多个同名字段。审计时每个目标字段最多匹配一次，因此重复邮箱、电话或地址无论少了一项还是多了一项都会报告，而不会被另一项掩盖。目标联系人新增的字段会排在该联系人原有字段的检查结果之后。

参数比较遵循内容行的语义：属性名和参数名不区分大小写，参数顺序不影响结果，`TYPE` 的值也按不区分大小写处理。

`strict_policy` 要求迁移结果完全一致；`additive_policy` 允许增加联系人，但仍拒绝删除联系人、字段增减、内容改写、参数变化和输入格式错误。`evaluate` 会返回结构化违规项，便于接入自动化检查。

运行示例：

```sh
moon run examples/check_move --target wasm-gc
```

开发检查：

```sh
moon fmt --check
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc --deny-warn
```

格式行为以 [RFC 6350](https://www.rfc-editor.org/rfc/rfc6350.html) 为依据。
