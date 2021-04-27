import dialogger.Dialogger;

class Example {
	static public function main():Void {
		// Read the dialogger project from file.
		final content:String = sys.io.File.getContent("fizzbuzz.json");
		// Initialize dialogger by providing any String content.
		final dialogger = new Dialogger(content);

		// Start the dialogger
		dialogger.start();

		// Loop until you run out of dialogs.
		while (dialogger.currentDialog != null) {
			// Print the dialog text.
			trace("-------------------------------------------");
			trace(dialogger.currentDialog.text);
			trace("-------------------------------------------");

			// Print the dialog choices with the 'index-)' prefix.
			for (i in (0...dialogger.currentDialog.options.length)) {
				trace('${i + 1}-) ${dialogger.getOption(i)}');
			}

			// Get the choice from user.
			var choice = Std.parseInt(Sys.stdin().readLine());

			// Make the choice that user picked.
			dialogger.pickOption(choice - 1);
		}

		trace("Finished.");
	}
}