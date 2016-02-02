namespace Editor {
	public class DocumentManager : Gtk.Notebook {
		construct {
			scrollable = true;
			engine = new Engine();
			engine.clear.connect (clear_errors);
			engine.end_parsing.connect (update_errors);
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
			append_page (document, new Gtk.Label (document.title));
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
			var document = new Document (path);
			document.manager = this;
			engine.add_document (document);
			append_page (document, new Gtk.Label (document.title));
		}
		
		public new bool remove (Document document) {
			bool result = false;
			this.foreach (widget => {
				if (widget is Document && (widget as Document).location == document.location) {
					base.remove (widget);
					result = true;
				}
			});
			return result;
		}
		
		public Project? load_project (string filename) {
			return engine.load_project (filename);
		}
		
		public Engine engine { get; private set; }
	}
}
