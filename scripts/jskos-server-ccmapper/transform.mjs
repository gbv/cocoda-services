#!/usr/bin/env -S zx --install

import anystream from "json-anystream"

const [input = "/tmp/generated.json", output = "/tmp/generated.adjusted.ndjson"] = argv._

console.time("Transform")
const writer = fs.createWriteStream(output)

const stream = await anystream.make(input)
for await (let object of stream) {
  object._score = Math.log10(parseFloat(object._score + 1)) / 5.6
  writer.write(JSON.stringify(object) + "\n")
}

writer.end()
console.timeEnd("Transform")
