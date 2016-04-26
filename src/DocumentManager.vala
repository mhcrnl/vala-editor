namespace Editor {
	public class DocumentManager : Gtk.Notebook {
		construct {
			scrollable = true;
			engine = new Engine();
			engine.begin_parsing.connect (clear_errors);
			engine.end_parsing.connect (update_errors);
			string s = "toto";
			notify["project"].connect (() => {
				this.foreach (widget => {
					this.remove (widget);				
				});
				engine.init();
				project.update.connect (update);
				project.sources.add.connect (source => {
					update();
				});
				project.packages.add.connect (package => {
					update();
				});
				foreach (var src in project.sources)
					engine.add_source (src);
				foreach (var pkg in project.packages)
					engine.add_package (pkg);
				show_all();
				engine.parse();
			});
		}
		
		void update() {
			engine.init();
			foreach (var src in project.sources)
				engine.add_source (src);
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
			set_tab_reorderable (label, true);
			set_tab_detachable (label, true);
		}
		
		public bool contains (string path) {
			bool result = false;
			this.foreach (widget => {
				if (widget is Document && (widget as Document).location == path)
					result = true;
			});
			return result;
		}
		
		public void add_document (string path) {
			var real_path = File.new_for_path (path).get_path();
			var document = new Document (real_path);
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
				this.remove (get_nth_page (i));
			});
			tab.show_all();
			set_tab_reorderable (get_nth_page (i), true);
			show_all();
		}
		
		public Project? load_project (string filename) {
			return engine.load_project (filename);
		}
		
		public Engine engine { get; private set; }
		public Project project { get; set; }
	}
}
