namespace Editor {
	public class DocumentManager : Gtk.Notebook {
		ThreadPool<DocumentManager> pool;
		
		construct {
			pool = new ThreadPool<DocumentManager>.with_owned_data (data => {
				data.update();
			}, 3, false);
			
			scrollable = true;
			engine = new Engine();
			engine.begin_parsing.connect (clear_errors);
			engine.end_parsing.connect (update_errors);
			string s = "toto";
			notify["project"].connect (() => {
				this.foreach (widget => {
					this.remove (widget);				
				});
				project.update.connect (update);
				project.sources.add.connect (source => {
					update();
				});
				project.packages.add.connect (package => {
					update();
				});
				pool.add (this);
			});
		}
		
		public void update() {
			engine.init();
			foreach (var dir in project.vapidirs)
				engine.add_vapidir (dir);
			foreach (var src in project.sources) {
				string path = src;
				if (path[0] != '/') {
					var basepath = File.new_for_path (project.location).get_parent().get_path();
					path = basepath + "/" + src;
				}
				engine.add_source (path);
			}
			foreach (var pkg in project.packages)
				engine.add_package (pkg);
			engine.parse();
		}
		
		void clear_errors() {
			this.foreach (widget => {
				var document = widget as Document;
				document.clear_tags();
			});
		}
		
		void update_errors (Report report) {
			this.foreach (widget => {
				var document = widget as Document;
				foreach (var err in report) {
					if (err.source.file.filename == document.location)
						if (err.error)
							document.apply_error (err);
						else
							document.apply_warning (err);
				}
			});
		}
		
		public new void add (Document document) {
			document.manager = this;
			engine.add_document (document);
			var label = new Gtk.Label (document.title);
			append_page (document, label);
			set_tab_reorderable (document, true);
			set_tab_detachable (document, true);
		}
		
		public bool contains (string path) {
			bool result = false;
			this.foreach (widget => {
				if (widget is Document && (widget as Document).location == path)
					result = true;
			});
			return result;
		}
		
		public bool add_file (Vala.SourceReference reference) {
			if (reference.file.filename in this)
				return false;
			var document = new Document (reference.file.filename);
			document.manager = this;
			document.show.connect (() => {
				document.go_to (reference.begin);
			});
			if (reference.file.file_type == Vala.SourceFileType.PACKAGE) {
				document.view.sensitive = false;
			}
			var tab = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
			var icon = new Gtk.Image.from_icon_name ("document", Gtk.IconSize.BUTTON);
			var label = new Gtk.Label (document.title);
			var button  = new Gtk.Button.from_icon_name ("dialog-close", Gtk.IconSize.BUTTON);
			tab.pack_start (icon, false, false);
			tab.pack_start (label);
			tab.pack_end (button, false, false);

			int i = prepend_page (document, tab);
			button.clicked.connect (() => {
				this.remove (document);
			});
			tab.show_all();
			set_tab_reorderable (document, true);
			show_all();
			return true;
		}
		
		public bool add_document (string src) {
			string path = src;
			if (path[0] != '/') {
				var basepath = File.new_for_path (project.location).get_parent().get_path();
				path = basepath + "/" + src;
			}
			if (path in this)
				return false;
			var document = new Document (path);
			document.save.connect_after (update);
			document.manager = this;
			engine.add_document (document);

			var tab = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
			var icon = new Gtk.Image.from_icon_name ("document", Gtk.IconSize.BUTTON);
			var label = new Gtk.Label (document.title);
			var button  = new Gtk.Button.from_icon_name ("dialog-close", Gtk.IconSize.BUTTON);
			tab.pack_start (icon, false, false);
			tab.pack_start (label);
			tab.pack_end (button, false, false);

			document.editing.connect (edit => {
				icon.icon_name = edit ? "edit-copy" : "document";
			});
			
			int i = prepend_page (document, tab);
			button.clicked.connect (() => {
				this.remove (document);
			});
			tab.show_all();
			set_tab_reorderable (document, true);
			show_all();
			return true;
		}
		
		public Project? load_project (string filename) {
			return Project.load (filename);
		}
		
		public Engine engine { get; private set; }
		public Project project { get; set; }
	}
}
