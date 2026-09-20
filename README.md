# mooncontactbridge

换通讯录软件时，导入成功不等于资料完整。手机号码可能还在，号码标签、备注、地址或自定义字段却已经丢了。

mooncontactbridge 先做一件小事：读取迁移前后的 vCard 4.0 文本，列出消失和被改写的内容行。它是纯 MoonBit 库，输入输出不绑定文件系统，可以放进命令行工具、网页或测试程序里。

```moonbit
let old_book = @wire.read(old_vcf)
let new_book = @wire.read(new_vcf)
let report = @review.audit(old_book, new_book)
println(report.render())
```

目前有两个包：

- `wire` 负责展开折行、拆分多张名片、保留原始字段头和值，并记录源行号；
- `ledger` 先用 UID、邮箱或电话号码配对联系人，再逐项区分字段消失、字段值变化和参数变化；
- `review` 生成整本通讯录的确定性报告，并带上新增、删除联系人和输入诊断。

解析器要求每张卡包含 `VERSION:4.0` 和 `FN`。参数和未知的 `X-` 字段会原样进入模型，便于后续检查。联系人配对只接受唯一候选；若多个联系人共享号码或邮箱，会保留为未匹配项，交给调用方决定。

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
