# mooncontactbridge

换通讯录软件时，导入成功不等于资料完整。手机号码可能还在，号码标签、备注、地址或自定义字段却已经丢了。

mooncontactbridge 先做一件小事：读取迁移前后的 vCard 4.0 文本，列出消失和被改写的内容行。它是纯 MoonBit 库，输入输出不绑定文件系统，可以放进命令行工具、网页或测试程序里。

```moonbit
let old_book = @wire.read(old_vcf)
let new_book = @wire.read(new_vcf)
let findings = @ledger.compare(old_book.cards[0], new_book.cards[0])
```

目前有两个包：

- `wire` 负责展开折行、拆分多张名片、保留原始字段头和值，并记录源行号；
- `ledger` 逐项核对一张联系人卡，区分字段整体消失与同名字段内容变化。

解析器要求每张卡包含 `VERSION:4.0` 和 `FN`。参数和未知的 `X-` 字段会原样进入模型，便于后续检查。第一版按调用方指定的联系人卡进行比较，暂不猜测两本通讯录中谁和谁是同一个人。

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
