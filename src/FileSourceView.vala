namespace Editor {
	public class FileSourceBar : Gtk.Revealer {
		Gtk.InfoBar info_bar;
		Gtk.Label label;
		Gtk.Image image;
		
		construct {
			info_bar = new Gtk.InfoBar();
			info_bar.response.connect (id => {
				set_reveal_child (false);
				response (id);
			});
			info_bar.add_buttons ("OK", Gtk.ResponseType.OK, "Cancel", Gtk.ResponseType.CANCEL);
			label = new Gtk.Label ("");
			image = new Gtk.Image.from_icon_name ("dialog-warning", Gtk.IconSize.LARGE_TOOLBAR);
			var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
			box.pack_start (image, false, false);
			box.pack_start (label);
			info_bar.get_content_area().add (box);
			add (info_bar);
			
			notify["message"].connect (() => {
				label.label = message;
			});
			notify["message-type"].connect (() => {
				info_bar.message_type = message_type;
				if (message_type == Gtk.MessageType.INFO)
					image.icon_name = "dialog-information";
				if (message_type == Gtk.MessageType.WARNING)
					image.icon_name = "dialog-warning";
				if (message_type == Gtk.MessageType.QUESTION)
					image.icon_name = "dialog-question";
				if (message_type == Gtk.MessageType.ERROR)
					image.icon_name = "dialog-error";
			});
		}
		
		public signal void response (int id);
		
		public string message { get; set; }
		public Gtk.MessageType message_type { get; set; }
	}
	
	public class FileSourceView : Gtk.EventBox {
		GLib.File file;
		GLib.FileMonitor monitor;
		string etag;
		
		public FileSourceView (string location) {
			GLib.Object (location: location);
		}
		
		construct {
			file = File.new_for_path (location);
			monitor = file.monitor (FileMonitorFlags.NONE);
			var manager = new Gtk.SourceLanguageManager();
			var language = manager.guess_language (location, null);
			if (language == null) {
				string ext = location.substring (1 + location.index_of ("."));
				language = manager.get_language (ext);
			}
			buffer = new Gtk.SourceBuffer.with_language (language);
			view = new Gtk.SourceView.with_buffer (buffer);
			var sw = new Gtk.ScrolledWindow (null, null);
			sw.add (view);
			bar = new FileSourceBar();
			bar.response.connect (id => {
				if (id == Gtk.ResponseType.OK && bar.message_type == Gtk.MessageType.INFO) {
					uint8[] data;
					file.load_contents (null, out data, null);
					view.buffer.text = (string)data;
					saved();
				}
				else if (id == Gtk.ResponseType.OK && bar.message_type == Gtk.MessageType.WARNING) {
					string tag;
					file.replace_contents (view.buffer.text.data, etag, true, FileCreateFlags.NONE, out tag);
					etag = tag;
				}
			});
			
			bool changed = false;
			monitor.changed.connect ((f1, f2, event_type) => {
				if (event_type == FileMonitorEvent.CHANGES_DONE_HINT) {
					if (changed) {
						changed = false;
						return;
					}
					bar.message_type = Gtk.MessageType.INFO;
					bar.message = "file content changed. reload it ?";
					bar.reveal_child = true;
				}
				if (f1.get_path() == location && event_type == FileMonitorEvent.DELETED) {
					bar.message_type = Gtk.MessageType.WARNING;
					bar.message = "file deleted. save it ?";
					bar.reveal_child = true;
					changed = true;
				}
			});
			
			var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
			box.pack_start (bar, false, false);
			box.pack_start (sw);
			bar.show_all();
			add (box);
			
			realize.connect (() => {
				uint8[] data;
				file.load_contents (null, out data, null);
				view.buffer.text = (string)data;
			});
			
			view.key_press_event.connect (event => {
				Gtk.TextIter iter;
				view.buffer.get_iter_at_mark (out iter, view.buffer.get_insert());
				current_line = iter.get_line();
				current_column = iter.get_line_offset();
				
				if ((event.state & Gdk.ModifierType.CONTROL_MASK) != 0 && event.keyval == Gdk.Key.s) {
					string tag;
					changed = true;
					file.replace_contents (view.buffer.text.data, etag, true, FileCreateFlags.NONE, out tag);
					etag = tag;
					saved();
				}
				return false;
			});
		}
		
		public void add_completion_provider (Gtk.SourceCompletionProvider provider) {
			view.completion.add_provider (provider);
		}
		
		public string get_current_text (Gtk.TextIter iter) {
			Gtk.TextIter start;
			view.buffer.get_iter_at_line_offset (out start, iter.get_line(), 0);
			return start.get_text (iter);
		}
		
		public signal void saved();
		
		public FileSourceBar bar { get; private set; }
		public int current_line { get; private set; }
		public int current_column { get; private set; }
		public string location { get; construct; }
		public Gtk.SourceBuffer buffer { get; private set; }
		public Gtk.SourceView view { get; private set; }
	}
}
