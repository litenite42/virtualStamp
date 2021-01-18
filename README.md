# virtualStamp
> Useful tool to inject ("stamp") copyright/extraneous text from one file into another or many.

## Description
This tool is designed to inject (or "stamp") text from a specified file into another file (other files).
Motivated for inserting copyright/header text into source code after the fact.

### Options:
<dl>
  <dt>-i, --input <string></dt>
  <dd>File holding the destination text</dd>
  <dt>-s, --stamp <string></dt>
  <dd>File holding the "stamp" text [Default = "stamp.file"]</dd>
 <dt>-f, --suffix <string></dt>
 <dd>Text added to end of output file name and extension; i.e filename.extension-suffix [Default = "stamped"]</dd>
 <dt>-l, --line <int></td>
 <dd>Line where the text from the stamp file will be inserted. [Default = 0]</dd>
</dl>

* input and stamp files should be in or under the current working directory
* use the discard '_.ext' to represent all files with extension 'ext'

## Examples
```v
// eight.v
============
fn main() {
	x := 4 + 4
	println(x)
}
============

// stamp.file
============
// This is a test header :wave:
============

./stamp -i examples/eight.v -f teststamp

// examples/eight.v-teststamp
============
// This is a test header :wave:
fn main() {
	x := 4 + 4
	println(x)
}
============
```
