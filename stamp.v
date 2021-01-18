module main

import os
import flag

enum FieldType {
	string
	int
}

type FlagType = int | string | bool

struct Command {
mut:
	name        string
	suffix      byte
	default     FlagType
	description string
}

struct IntCommandConfig {
	name        string = 'line'
	suffix      byte   = `l`
	default     int
	description string
}

struct StringCommandConfig {
	name        string
	suffix      byte = `i`
	default     string
	description string
}

struct BoolCommandConfig {
	name string
	suffix byte = `w`
	default bool = false
	description string
}

type CommandConfig = IntCommandConfig | StringCommandConfig | BoolCommandConfig

fn new_command(c CommandConfig) &Command {
	mut command := &Command{}
	match c {
		IntCommandConfig {
			command.name = c.name
			command.suffix = c.suffix
			command.default = int(c.default)
			command.description = c.description
		}
		StringCommandConfig {
			command.name = c.name
			command.suffix = c.suffix
			command.default = c.default
			command.description = c.description
		}
		BoolCommandConfig {
			command.name = c.name
			command.suffix = c.suffix
			command.default = c.default
			command.description = c.description
		}
	}
	return command
}

fn new_flag(mut fp flag.FlagParser, c Command) FlagType {
	x := c.default
	match x {
		string { return fp.string(c.name, c.suffix, x, c.description) }
		int { return fp.int(c.name, c.suffix, x, c.description) }
		bool { return fp.bool(c.name, c.suffix, x, c.description) }
	}
}

fn (c Command) new_int(mut fp flag.FlagParser) int {
	x := new_flag(mut fp, c)
	match x {
		int { return x }
		else { return -1 }
	}
}

fn (c Command) new_string(mut fp flag.FlagParser) string {
	x := new_flag(mut fp, c)
	match x {
		string { return x }
		else { return '' }
	}
}

fn (c Command) new_bool(mut fp flag.FlagParser) bool {
	x := new_flag(mut fp, c)
	match x {
		bool { return x }
		else { return false }
	}
}

fn (c Command) str() string {
	return 'COMMAND $c.name: --$c.name [-$c.suffix.ascii_str()] => $c.description'
}

const (
	default_stamp_file   = 'stamp.file'
	default_stamp_suffix = 'stamped'
	commands             = {
		'input':  new_command(&StringCommandConfig{
			name: 'input'
			suffix: `i`
			default: ''
			description: 'File holding the destination text'
		})
		'stamp':  new_command(&StringCommandConfig{
			name: 'stamp'
			suffix: `s`
			default: default_stamp_file
			description: 'File holding the "stamp" text [Default = "$default_stamp_file"]'
		})
		'suffix': new_command(&StringCommandConfig{
			name: 'suffix'
			suffix: `f`
			default: default_stamp_suffix
			description: 'Text added to end of output file name and extension; i.e filename.extension-suffix [Default = "$default_stamp_suffix"]'
		})
		'line':   new_command(&IntCommandConfig{
			name: 'line'
			suffix: `l`
			default: 0
			description: 'Line where the text from the stamp file will be inserted. [Default = 0]'
		})
		'overwrite': new_command(&BoolCommandConfig{
			name: 'overwrite'
			suffix: `w`
			default: true
			description: 'Overwrite the input file(s); instead of, creating a separate stamped file.'
			})
	}
)

fn init_stamp(mut fp flag.FlagParser) {
	fp.application('virtualStamp')
	fp.version('v0.0.0')
	fp.description('This tool is designed to inject (or "stamp") text from a specified file into another file (other files).\n' +
		'Motivated for inserting copyright/header text into source code after the fact.')
	fp.skip_executable()
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	init_stamp(mut fp)
	input_file := commands['input'].new_string(mut fp)
	stamp_file := commands['stamp'].new_string(mut fp)
	stamp_suffix := commands['suffix'].new_string(mut fp)
	position := commands['line'].new_int(mut fp)
	overwrite := commands['overwrite'].new_bool(mut fp)
	help := fp.string('help', `h`, '', 'This help text')
	if input_file.len > 0 {
		mut stamp_text := os.read_file(stamp_file) or {
			panic('Something went wrong trying to read: $stamp_file')
		}
		input_file_arr := input_file.split('.')
		file_name := input_file_arr[0]
		if file_name.ends_with('_') {
			mut temp_path := os.getwd()
			if file_name.contains('/') || file_name.contains('\\') {
				temp_path = os.join_path(temp_path, os.dir(file_name) )
			}
			wd_files := os.ls(temp_path) or {
				panic('Something went wrong trying to read: $os.getwd()')
			}
			for file in wd_files {
				if file.ends_with(input_file_arr[1]) {
					mut temp := os.read_lines(os.join_path(temp_path, file)) or {
						panic('Something went wrong trying to read: $file')
					}
					temp.insert(position, stamp_text)
					lines := temp.join('\n')
				//	path := os.join_path(temp_path, '$file-$stamp_suffix')
					output_file := file + if !overwrite { '-$stamp_suffix' } else { '' }
					path := os.join_path(temp_path, output_file)
					os.write_file(path, lines)
				}
			}
		} else {
			mut temp := os.read_lines(input_file) or {
				panic('Something went wrong trying to read: $input_file')
			}
			temp.insert(position, stamp_text)
			lines := temp.join('\n')
			output_file := input_file + if !overwrite { '-$stamp_suffix' } else { '' }
			os.write_file(output_file, lines)
		}
	}
	if help in commands {
		println(commands[help])
	} else {
		println(fp.usage())
	}
}
