namespace Editor {
	public class FileChooserDialog : Gtk.FileChooserDialog {
		public FileChooserDialog (Gtk.Window parent, string title) {
			GLib.Object (use_header_bar : 1, action : Gtk.FileChooserAction.OPEN, select_multiple : true,
				transient_for : parent, title : title);
		}
		
		construct {
			var ftr = new Gtk.FileFilter();
			ftr.set_filter_name ("Vala");
			ftr.add_pattern ("*.vala");
			add_filter (ftr);
			add_buttons ("Cancel", Gtk.ResponseType.CANCEL, "OK", Gtk.ResponseType.OK);
		}
	}
	
	public class ProjectChooserDialog : Gtk.FileChooserDialog {
		public ProjectChooserDialog (Gtk.Window parent) {
			GLib.Object (use_header_bar : 1, action : Gtk.FileChooserAction.OPEN, select_multiple : false,
				transient_for : parent, title : "Choose project");
		}
		
		construct {
			var ftr = new Gtk.FileFilter();
			ftr.set_filter_name ("Editor project");
			ftr.add_pattern ("*.edi");
			ftr.add_pattern ("*.json");
			add_filter (ftr);
			add_buttons ("Cancel", Gtk.ResponseType.CANCEL, "OK", Gtk.ResponseType.OK);
		}
		
		public Project? project {
			owned get {
				if (get_filenames().length() == 0)
					return null;
				return Project.load (get_filenames().nth_data (0));
			}
		}
	}
	
	public class Window : Gtk.Window {
		DocumentManager manager;
		ReportTable table;
		SymbolTree tree;
		
		construct {
			destroy.connect (Gtk.main_quit);
			
			tree = new SymbolTree();
			tree.width_request = 200;
			tree.updated.connect (() => { print ("done\n"); });
			table = new ReportTable();
			manager = new DocumentManager();
			manager.engine.begin_parsing.connect (table.clear);
			manager.engine.end_parsing.connect (report => {
				table.update (report);
				tree.update (manager.engine.get_root());
			});
			var bar = new Gtk.HeaderBar();
			bar.show_close_button = true;
			bar.title = "Editor";
			
			var button = new Gtk.MenuButton();
			var menu = new Gtk.Menu();
			var newitem = new Gtk.MenuItem.with_label ("New project");			
			newitem.activate.connect (() => {
				var assistant = new ProjectAssistant();
				assistant.show_all();
			});
			var prjitem = new Gtk.MenuItem.with_label ("Open project");
			prjitem.activate.connect (() => {
				var dialog = new ProjectChooserDialog (this);
				Project? project = null;
				if (dialog.run() == Gtk.ResponseType.OK) {
					project = manager.load_project (dialog.get_filename());
				}
				if (project != null) {
					manager.project = project;
				}
				dialog.destroy();
			});
			
			var quititem = new Gtk.MenuItem.with_label ("Quit");
			quititem.activate.connect (Gtk.main_quit);
			menu.add (newitem);
			menu.add (prjitem);
			menu.add (new Gtk.SeparatorMenuItem());
			menu.add (quititem);
			button.popup = menu;
			menu.show_all();
			
			bar.pack_start (button);
			set_titlebar (bar);
			
			var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
			vbox.pack_start (manager);
			table.height_request = 200;
			vbox.pack_start (table, false, false);
			
			var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
			hbox.pack_start (vbox);
			hbox.pack_start (tree, false, false);
			
			add (hbox);
		}
	}
}
