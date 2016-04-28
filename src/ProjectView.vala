namespace Editor {
	public class PackagePopover : Gtk.Popover {
		Gtk.ListStore store;
		
		construct {
			store = new Gtk.ListStore (2, typeof (bool), typeof (string));
			var tree_view = new Gtk.TreeView.with_model (store);
			tree_view.headers_visible = false;
			var toggle = new Gtk.CellRendererToggle();
			toggle.toggled.connect (path => {
				var tpath = new Gtk.TreePath.from_string (path);
				Gtk.TreeIter iter;
				store.get_iter (out iter, tpath);
				store.set (iter, 0, !toggle.active);
			});
			tree_view.insert_column_with_attributes (-1, "add", toggle, "active", 0);
			tree_view.insert_column_with_attributes (-1, "name", new Gtk.CellRendererText(), "text", 1);
			var view = new Gtk.ScrolledWindow (null, null);
			view.add (tree_view);
			add (view);
			set_position (Gtk.PositionType.BOTTOM);
			set_size_request (250, 350);
			
			Engine.list_available_packages().foreach (pkg => {
				Gtk.TreeIter iter;
				store.append (out iter);
				store.set (iter, 0, false, 1, pkg.id);
				return true;
			});
		}
		
		public string[] packages {
			owned get {
				var result = new GenericArray<string>();
				if (store == null || store.iter_n_children (null) == 0)
					return new string[0];
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
			set {
				store.foreach ((model, path, iter) => {
					string pkg;
					model.get (iter, 1, out pkg);
					store.set (iter, 0, (pkg in value));
					return false;
				});
			}
		}
	}
	
	public class ProjectView : Gtk.ScrolledWindow {
		enum FileType {
			NONE,
			DIRECTORY,
			SOURCE,
			SOURCE_NODE,
			PACKAGE,
			PACKAGE_NODE
		}
		
		public ProjectView (Gtk.Window parent) {
			GLib.Object (window: parent);
		}
		
		Gtk.TreeStore store;
		PackagePopover popover;
		bool popover_hide;
		
		public signal void sources_root_activated();
		public signal void source_activated (string path);
		public signal void package_activated (string package);
		
		construct {
			popover = new PackagePopover();
			popover.hide.connect (self => {
				if (popover_hide || popover.packages.length == 0)
					return;
				project.packages.clear();
				project.packages.add_all_array (popover.packages);
				project.update();
				update();
				popover_hide = true;
			});
			store = new Gtk.TreeStore (4, typeof (string), typeof (string), typeof (string), typeof (int));
			var view = new Gtk.TreeView.with_model (store);
			view.row_activated.connect ((path, column) => {
				Gtk.TreeIter iter;
				store.get_iter (out iter, path);
				FileType ft;
				string pkg;
				string p;
				store.get (iter, 3, out ft);
				store.get (iter, 2, out p);
				store.get (iter, 1, out pkg);
				if (ft == FileType.PACKAGE)
					package_activated (pkg);
				if (ft == FileType.SOURCE) {
					var basepath = File.new_for_path (project.location).get_parent().get_path();
					if (p[0] != '/')
						p = basepath + "/" + p;
					source_activated (p);
				}
				if (ft == FileType.PACKAGE_NODE) {
					Gdk.Rectangle rect;
					view.get_cell_area (path, column, out rect);
					rect.height += rect.height;
					popover.packages = project.packages.to_array();
					popover.set_relative_to (view);
					popover.set_pointing_to (rect);
					popover_hide = false;
					popover.show_all();
				}
				if (ft == FileType.SOURCE_NODE)
					sources_root_activated();
			});
			
			view.insert_column_with_attributes (-1, null, new Gtk.CellRendererPixbuf(), "icon-name", 0);
			view.insert_column_with_attributes (-1, null, new Gtk.CellRendererText(), "markup", 1);
			add (view);
			
			
			notify["project"].connect (update);
		}
		
		public void update() {
			store.clear();
			Gtk.TreeIter iter;
			store.append (out iter, null);
			store.set (iter, 1, "<b>Files</b>", 3, FileType.SOURCE_NODE);
			foreach (var src in project.sources)
				add_path (iter, src.split ("/"));
			store.append (out iter, null);
			store.set (iter, 1, "<b>Packages</b>", 3, FileType.PACKAGE_NODE);
			foreach (string pkg in project.packages) {
				Gtk.TreeIter child;
				store.append (out child, iter);
				store.set (child, 0, "package-x-generic", 1, pkg, 3, FileType.PACKAGE);
			}
		}
		
		bool add_path (Gtk.TreeIter? root, string[] parts, int depth = 0) {
			for (var i = 0; i < store.iter_n_children (root); i++) {
				Gtk.TreeIter child;
				store.iter_nth_child (out child, root, i);
				string str;
				store.get (child, 1, out str);
				if (parts[depth] == str) {
					return add_path (child, parts, depth + 1);
				}
			}
			Gtk.TreeIter iter;
			store.append (out iter, root);
			string icon_name = ContentType.get_generic_icon_name (ContentType.guess (parts[depth], null, null));
			if (!("." in parts[depth]) && depth < parts.length - 1)
				icon_name = "folder";
			store.set (iter,
				0, icon_name,
				1, parts[depth],
				2, string.joinv ("/", parts),
				3, FileType.SOURCE);
			if (depth == parts.length - 1)
				return false;
			return add_path (iter, parts, depth + 1);
		}
		
		public Project project { get; set; }
		public Gtk.Window window { get; construct; }
	}
}
