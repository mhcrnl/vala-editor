namespace Editor {
	public class AssistantPage : GLib.Object {
		public AssistantPage (string title, Gtk.AssistantPageType page_type = Gtk.AssistantPageType.INTRO) {
			GLib.Object (title : title, page_type: page_type);
		}
		
		construct {
			notify["complete"].connect (() => {
				completed (complete);
			});
		}

		
		public signal void completed (bool complete);
		
		internal int page_num;

		public string title { get; set construct; }
		public Gtk.AssistantPageType page_type { get; set; }
		public bool complete { get; set; }
		public Gtk.Widget  widget { get; set; }
	}

	public class Assistant : Gtk.Assistant {
		public Assistant() {
			GLib.Object (use_header_bar: 1);
		}

		construct {
			set_default_size (500, 500);
		}

		public bool add_page (AssistantPage page) {
			if (page.widget == null)
				return false;
			page.page_num = append_page (page.widget);
			set_page_title (page.widget, page.title);
			set_page_type (page.widget, page.page_type);
			set_page_complete (page.widget, page.complete);
			page.completed.connect (complete => {
				set_page_complete (page.widget, complete);
			});
			return true;
		}
	}
}
