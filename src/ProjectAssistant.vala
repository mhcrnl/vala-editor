namespace Editor {
	public class ProjectAssistant : Assistant {
		Gtk.ListStore packages_store;

		construct {
			var page1 = new AssistantPage ("Introduction");
			page1.widget = new Gtk.Label ("Introduction");
			page1.complete = true;

			var page2 = new AssistantPage ("Content", Gtk.AssistantPageType.CONTENT);
			var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
			var entry_label = new Gtk.Label ("Project name");
			var entry = new Gtk.Entry();
			entry.editable = false;
			var button = new Gtk.FileChooserButton ("Create folder", Gtk.FileChooserAction.SELECT_FOLDER);
			button.file_set.connect (() => {
				project = new Project (button.get_file().get_basename());
				entry.text = button.get_file().get_basename();
			});
			button.create_folders = true;
			box.pack_start (entry_label, false, false);
			box.pack_start (entry, false, false);
			box.pack_start (button, false, false);
			page2.widget = box;
			page2.complete = true;
			
			packages_store  = new Gtk.ListStore (3, typeof (bool), typeof (string), typeof (string));
			var packages_view = new Gtk.TreeView.with_model (packages_store);
			var toggle = new Gtk.CellRendererToggle();
			toggle.toggled.connect (path => {
				var tpath = new Gtk.TreePath.from_string (path);
				Gtk.TreeIter iter;
				packages_store.get_iter (out iter, tpath);
				packages_store.set (iter, 0, !toggle.active);
			});
			packages_view.insert_column_with_attributes (-1, null, toggle, "active", 0);
			packages_view.insert_column_with_attributes (-1, "name", new Gtk.CellRendererText(), "text", 1);
			packages_view.insert_column_with_attributes (-1, "description", new Gtk.CellRendererText(), "text", 2);
			var sw = new Gtk.ScrolledWindow (null, null);
			sw.hscrollbar_policy = Gtk.PolicyType.NEVER;
			sw.add (packages_view);

			var page4 = new AssistantPage ("Packages", Gtk.AssistantPageType.CONTENT);
			page4.widget = sw;
			page4.complete = true;

			var page3 = new AssistantPage ("Summary", Gtk.AssistantPageType.CONFIRM);
			page3.widget = new Gtk.Label ("Summary");
			page3.complete = true;
			add_page (page1);
			add_page (page2);
			add_page (page4);
			add_page (page3);
			
			apply.connect (() => {
				
				destroy();
			});
			cancel.connect (() => {
				destroy();
			});
			escape.connect (() => {
				destroy();
			});
		}

		public void update_packages (Gee.Iterator<Package> iterator) {
			packages_store.clear();
			iterator.foreach (package => {
				Gtk.TreeIter iter;
				packages_store.append (out iter);
				packages_store.set (iter, 0, false, 1, package.id, 2, package.description);
				return true;
			});
		}

		public Project project { get; private set; }
	}
}
