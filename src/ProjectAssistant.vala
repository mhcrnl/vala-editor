namespace Editor {
	public class PackageView : Gtk.ScrolledWindow {
		Gtk.ListStore store;
		
		construct {
			hscrollbar_policy = Gtk.PolicyType.NEVER;
			store = new Gtk.ListStore (3, typeof (bool), typeof (string), typeof (string));
			var view = new Gtk.TreeView.with_model (store);
			
			var toggle = new Gtk.CellRendererToggle();
			toggle.toggled.connect (path => {
				var tpath = new Gtk.TreePath.from_string (path);
				Gtk.TreeIter iter;
				store.get_iter (out iter, tpath);
				store.set (iter, 0, !toggle.active);
			});
			view.insert_column_with_attributes (-1, null, toggle, "active", 0);
			view.insert_column_with_attributes (-1, "name", new Gtk.CellRendererText(), "text", 1);
			view.insert_column_with_attributes (-1, "description", new Gtk.CellRendererText(), "text", 2);
			
			Engine.list_available_packages().foreach (pkg => {
				Gtk.TreeIter iter;
				store.append (out iter);
				store.set (iter, 0, false, 1, pkg.id, 2, pkg.description);
				return true;
			});
			
			add (view);
		}
		
		public string[] get_packages() {
			var result = new GenericArray<string>();
			store.foreach ((model, path, iter) => {
				GLib.Value b, n;
				model.get_value (iter, 0, out b);
				model.get_value (iter, 1, out n);
				if ((bool)b)
					result.add ((string)n);
				return false;
			});
			return result.data;
		}
	}
	
	public class ProjectAssistant : Assistant {
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
				page2.complete = true;
				var basename = button.get_file().get_basename();
				project = new Project (basename, button.get_file().get_path() + "/" + basename + ".edi");
				entry.text = button.get_file().get_basename();
			});
			button.create_folders = true;
			box.pack_start (entry_label, false, false);
			box.pack_start (entry, false, false);
			box.pack_start (button, false, false);
			page2.widget = box;
			page2.complete = false;
			
			var package_view = new PackageView();

			var page4 = new AssistantPage ("Packages", Gtk.AssistantPageType.CONTENT);
			page4.widget = package_view;
			page4.complete = true;

			var page3 = new AssistantPage ("Summary", Gtk.AssistantPageType.CONFIRM);
			page3.widget = new Gtk.Label ("Summary");
			page3.complete = true;
			add_page (page1);
			add_page (page2);
			add_page (page4);
			add_page (page3);
			
			apply.connect (() => {
				if (project != null)
					foreach (var package in package_view.get_packages())
						project.packages.add (package);
				destroy();
			});
			cancel.connect (() => {
				destroy();
			});
			escape.connect (() => {
				destroy();
			});
		}

		public Project project { get; private set; }
	}
}
