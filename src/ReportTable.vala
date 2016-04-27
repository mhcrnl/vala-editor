namespace Editor {
	internal class SourceReferenceWrapper : GLib.Object {
		public Vala.SourceReference reference { get; construct; }
	}
	
	public class ReportTable : Gtk.ScrolledWindow {
		Gtk.ListStore store;
		
		construct {
			store = new Gtk.ListStore (5, typeof (string), typeof (string), typeof (string), typeof (string), typeof (SourceReferenceWrapper));
			var view = new Gtk.TreeView.with_model (store);
			view.row_activated.connect ((path, column) => {
				Gtk.TreeIter iter;
				store.get_iter (out iter, path);
				SourceReferenceWrapper wrapper;
				store.get (iter, 4, out wrapper);
				file_activated (wrapper.reference);
			});
			view.insert_column_with_attributes (-1, null, new Gtk.CellRendererPixbuf(), "icon-name", 0);
			view.insert_column_with_attributes (-1, "message", new Gtk.CellRendererText(), "text", 1);
			view.insert_column_with_attributes (-1, "file", new Gtk.CellRendererText(), "text", 2);
			view.insert_column_with_attributes (-1, "location", new Gtk.CellRendererText(), "text", 3);
			add (view);
		}
		
		public signal void file_activated (Vala.SourceReference reference);
		
		public void clear() {
			store.clear();
		}
		
		public void update (Report report) {
			foreach (var err in report) {
				Gtk.TreeIter iter;
				store.append (out iter);
				store.set (iter,
					0, err.error ? "dialog-error" : "dialog-warning",
					1, err.message,
					2, err.source.file.filename,
					3, "{%d:%d} => {%d:%d}".printf (err.source.begin.line - 1, err.source.begin.column,
						err.source.end.line - 1, err.source.end.column),
					4, (SourceReferenceWrapper)GLib.Object.new (typeof (SourceReferenceWrapper), "reference", err.source));
			}
		}
	}
}
