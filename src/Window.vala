namespace Editor {
	public class FileChooserDialog : Gtk.FileChooserDialog {
		public FileChooserDialog (Gtk.Window parent, string title, Gtk.FileChooserAction action) {
			GLib.Object (use_header_bar : 1, action : action, select_multiple : true,
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
		ProjectView project_view;
		DocumentManager manager;
		ReportTable table;
		
		construct {
			destroy.connect (Gtk.main_quit);
			project_view = new ProjectView (this);
			table = new ReportTable();
			manager = new DocumentManager();
			project_view.source_activated.connect (source => {
				manager.add_document (source);
			});
			manager.notify["project"].connect (() => {
				project_view.project = manager.project;
			});
			manager.engine.begin_parsing.connect (table.clear);
			manager.engine.end_parsing.connect (report => {
				table.update (report);
			});
			var bar = new Gtk.HeaderBar();
			bar.show_close_button = true;
			bar.title = "Editor";
			
			var button = new Gtk.MenuButton();
			var menu = new Gtk.Menu();
			var newitem = new Gtk.MenuItem.with_label ("New project");			
			newitem.activate.connect (() => {
				var assistant = new ProjectAssistant();
				assistant.response.connect (id => {
					if (id == Gtk.ResponseType.APPLY)
						manager.project = assistant.project;
				});
				assistant.show_all();
			});
			
			var fileitem = new Gtk.MenuItem.with_label ("Add file");
			fileitem.sensitive = false;
			fileitem.activate.connect (() => {
				var dialog = new FileChooserDialog (this, "Add file(s)", Gtk.FileChooserAction.OPEN);
				if (dialog.run() == Gtk.ResponseType.OK)  {
					if (manager.project != null)
						foreach (var file in dialog.get_filenames())
							manager.project.sources.add (file);
				}
				dialog.destroy();	
			});
			
			var prjitem = new Gtk.MenuItem.with_label ("Open project");
			prjitem.activate.connect (() => {
				var dialog = new ProjectChooserDialog (this);
				Project? project = null;
				if (dialog.run() == Gtk.ResponseType.OK) {
					project = manager.load_project (dialog.get_filename());
					fileitem.sensitive = true;
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
			menu.add (fileitem);
			menu.add (new Gtk.SeparatorMenuItem());
			menu.add (quititem);
			button.popup = menu;
			menu.show_all();
			
			bar.pack_start (button);
			set_titlebar (bar);
			
			var hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
			hpaned.add2 (manager);
			hpaned.add1 (project_view);
			hpaned.position = 100;
			
			var vpaned = new Gtk.Paned (Gtk.Orientation.VERTICAL);
			vpaned.add1 (hpaned);
			vpaned.add2 (table);
			vpaned.position = 600;
			
			add (vpaned);
		}
	}
}
