package dialogger;

using haxe.EnumTools;

typedef Dialog = {
	public final character:String;
	public final time_limit:Float;
	public var text:String;
	public final time_path:Path;
	public final options:Array<Option>;
}

typedef Setter = {
	public final variable:String;
	public final operation:Dynamic;
	public final path:Path;
}

typedef Condition = {
	public final operation:Dynamic;
	public final paths:Array<Path>;
}

typedef Path = {
	public final id:String;
	public final type:String;
}

typedef Option = {
	public var text:String;
	public final operation:Dynamic;
	public final path:Path;
}

enum BasicType {
	Number(v:Float);
	Text(v:String);
	Boolean(v:Bool);
}

class Dialogger {
	private var starting:Path;

	private var dialogs:haxe.DynamicAccess<Dialog>;
	private var setters:haxe.DynamicAccess<Setter>;
	private var conditions:haxe.DynamicAccess<Condition>;
	private var characters:haxe.DynamicAccess<haxe.DynamicAccess<Dynamic>>;

	private var values:Map<String, {character:String, field:String}>;

	public var currentDialog(default, null):Dialog;

	public function new(content:String) {
		final data = haxe.Json.parse(content);

		starting = data.starting;
		characters = data.characters;
		dialogs = data.dialog;
		setters = data.setter;
		conditions = data.condition;

		values = new Map();
		for (character_name => fields in characters) {
			for (field_name => _ in fields) {
				final key = "${" + character_name + "." + field_name + "}";
				values.set(key, {character: character_name, field: field_name});
			}
		}
	}

	public function start():Dialog {
		return currentDialog = evaluate(starting);
	}

	public function getValue<T>(character:String, field:String): T {
		return characters[character][field];
	}

	public function setValue(character:String, field:String, value:Dynamic) {
		characters[character][field] = value;
	}

	public function getOption(i:Int):String {
		if (currentDialog == null || currentDialog.options == null || i >= currentDialog.options.length || i < 0)
			return null;

		return currentDialog.options[i].text;
	}

	public function pickOption(i:Int):Dialog {
		if (currentDialog == null || currentDialog.options == null || i >= currentDialog.options.length || i < 0) {
			currentDialog = null;
		} else {
			currentDialog = evaluate(currentDialog.options[i].path);
		}

		return currentDialog;
	}

	private function resolveObject(field:String, op:Dynamic):BasicType {
		switch (field) {
			case "var":
				final name = values["${" + op + "}"];
				return resolve(characters[name.character][name.field]);
			case "+":
				final arr:Array<Dynamic> = op;
				var result:Dynamic = resolve(arr[0]).getParameters()[0];
				for (i in (1...arr.length)) {
					result += resolve(arr[i]).getParameters()[0];
				}
				return resolve(result);
			case "-":
				final arr:Array<Dynamic> = op;
				var result:Dynamic = resolve(arr[0]).getParameters()[0];
				for (i in (1...arr.length)) {
					result -= resolve(arr[i]).getParameters()[0];
				}
				return resolve(result);
			case "*":
				final arr:Array<Dynamic> = op;
				var result:Dynamic = resolve(arr[0]).getParameters()[0];
				for (i in (1...arr.length)) {
					result *= resolve(arr[i]).getParameters()[0];
				}
				return resolve(result);
			case "/":
				final arr:Array<Dynamic> = op;
				var result:Dynamic = resolve(arr[0]).getParameters()[0];
				for (i in (1...arr.length)) {
					result /= resolve(arr[i]).getParameters()[0];
				}
				return resolve(result);
			case "%":
				final arr:Array<Dynamic> = op;
				var result:Dynamic = resolve(arr[0]).getParameters()[0];
				for (i in (1...arr.length)) {
					result %= resolve(arr[i]).getParameters()[0];
				}
				return resolve(result);
			case "max":
				final arr:Array<Dynamic> = op;
				var result:Dynamic = resolve(arr[0]).getParameters()[0];
				for (i in (1...arr.length)) {
					result = Math.max(result, resolve(arr[i]).getParameters()[0]);
				}
				return resolve(result);
			case "min":
				final arr:Array<Dynamic> = op;
				var result:Dynamic = resolve(arr[0]).getParameters()[0];
				for (i in (1...arr.length)) {
					result = Math.min(result, resolve(arr[i]).getParameters()[0]);
				}
				return resolve(result);
			case "and":
				final arr:Array<Dynamic> = op;
				var result:Bool = resolve(arr[0]).getParameters()[0];
				for (i in (1...arr.length)) {
					result = result && resolve(arr[i]).getParameters()[0];
				}
				return BasicType.Boolean(result);
			case "or":
				final arr:Array<Dynamic> = op;
				var result:Bool = resolve(arr[0]).getParameters()[0];
				for (i in (1...arr.length)) {
					result = result || resolve(arr[i]).getParameters()[0];
				}
				return BasicType.Boolean(result);
			case "==" | "===":
				final arr:Array<Dynamic> = op;
				final first:Dynamic = resolve(arr[0]).getParameters()[0];
				final second:Dynamic = resolve(arr[1]).getParameters()[0];
				return BasicType.Boolean(first == second);
			case "!=" | "!==":
				final arr:Array<Dynamic> = op;
				final first:Dynamic = resolve(arr[0]).getParameters()[0];
				final second:Dynamic = resolve(arr[1]).getParameters()[0];
				return BasicType.Boolean(first != second);
			case ">":
				final arr:Array<Dynamic> = op;
				final first:Dynamic = resolve(arr[0]).getParameters()[0];
				final second:Dynamic = resolve(arr[1]).getParameters()[0];
				return BasicType.Boolean(first > second);
			case "<":
				final arr:Array<Dynamic> = op;
				final first:Dynamic = resolve(arr[0]).getParameters()[0];
				final second:Dynamic = resolve(arr[1]).getParameters()[0];
				return BasicType.Boolean(first < second);
			case ">=":
				final arr:Array<Dynamic> = op;
				final first:Dynamic = resolve(arr[0]).getParameters()[0];
				final second:Dynamic = resolve(arr[1]).getParameters()[0];
				return BasicType.Boolean(first >= second);
			case "<=":
				final arr:Array<Dynamic> = op;
				final first:Dynamic = resolve(arr[0]).getParameters()[0];
				final second:Dynamic = resolve(arr[1]).getParameters()[0];
				return BasicType.Boolean(first <= second);
			case "if":
				final arr:Array<Dynamic> = op;
				var i = 0;
				while (i < arr.length - 2) {
					final is_true:Bool = resolve(arr[i]).getParameters()[0];
					if (is_true) {
						return BasicType.Number(resolve(arr[i + 1]).getParameters()[0]);
					}
					i += 2;
				}
				return BasicType.Number(resolve(arr[arr.length - 1]).getParameters()[0]);
			case unsupported:
				trace("Unsupported operator : " + unsupported);
				return null;
		}
	}

	private function resolve(op:Dynamic):BasicType {
		switch (Type.typeof(op)) {
			case TInt | TFloat:
				return BasicType.Number(op);
			case TBool:
				return BasicType.Boolean(op);
			case TClass(String):
				return BasicType.Text(op);
			case TObject:
				for (field in Reflect.fields(op)) {
					return resolveObject(field, Reflect.getProperty(op, field));
				}
				return null;
			case _:
				return null;
		}
	}

	private function evaluate(path:Path):Dialog {
		switch (path.type) {
			case "setter":
				final setter = setters[path.id];
				final name_field = setter.variable.split('.');
				characters[name_field[0]][name_field[1]] = resolve(setter.operation).getParameters()[0];
				return evaluate(setter.path);
			case "condition":
				final condition = conditions[path.id];
				final idx:BasicType = resolve(condition.operation);
				switch (idx) {
					case Number(v): return evaluate(condition.paths[Std.int(v)]);
					case _: throw new haxe.Exception("Condition result must be Number !");
				}
			case "dialog":
				return renderDialog(path.id);
			case _:
				return null;
		}
	}

	static function replaceAll(text:String, from:String, to:String):String {
		var parsed = text.split(from);
		return parsed.join(to);
	}

	private function renderDialog(id:String):Dialog {
		final ref_dialog = dialogs[id];

		final dialog:Dialog = {
			character: ref_dialog.character,
			text: ref_dialog.text,
			time_limit: ref_dialog.time_limit,
			time_path: ref_dialog.time_path,
			options: new Array<Option>()
		};

		// Check for option logic
		for (option in ref_dialog.options) {
			if (option.operation != null) {
				switch (resolve(option.operation)) {
					case Boolean(v) if (!v):
						continue;
					case _:
				}
			}

			dialog.options.push({text: option.text, path: option.path, operation: null});
		}

		// Replace all variable templates ${name.field}
		for (template => name in values) {
			final changeTo = Std.string(characters[name.character][name.field]);
			dialog.text = replaceAll(dialog.text, template, changeTo);
			for (option in dialog.options) {
				option.text = replaceAll(option.text, template, changeTo);
			}
		}

		return dialog;
	}
}
