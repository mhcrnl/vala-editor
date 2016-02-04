namespace Editor {
	public class AssistantPage : GLib.Object {
		
	}

	public class Assistant : Gtk.Assistant {
		public Assistant() {
			GLib.Object (use_header_bar: 1);
		}

		construct {
			set_default_size (500, 500);
			
			var label = new Gtk.Label ("Project creation");
			int pos = this.append_page (label);
		}

		public void add_page () {}
	}
}
