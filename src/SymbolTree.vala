namespace Editor {
	public class SymbolTree : Gtk.ScrolledWindow {
		Gtk.TreeStore store;
		
		construct {
			store = new Gtk.TreeStore (4, typeof (Gdk.Pixbuf), typeof (string), typeof (bool), typeof (Symbol));
			var view = new Gtk.TreeView.with_model (store);
			view.row_activated.connect ((path, column) => {
				Gtk.TreeIter iter;
				store.get_iter (out iter, path);
				bool b;
				Symbol symbol;
				store.get (iter, 2, out b);
				store.get (iter, 3, out symbol);
				symbol_activated (symbol);
				if (!b) {
					store.set (iter, 2, true);
					if (symbol.has_children)
						foreach (var sym in symbol.children)
							append_symbol (sym, iter);
				}
			});
			view.insert_column_with_attributes (-1, null, new Gtk.CellRendererPixbuf(), "pixbuf", 0);
			view.insert_column_with_attributes (-1, null, new Gtk.CellRendererText(), "text", 1);
			add (view);
		}
		
		public signal void symbol_activated (Symbol symbol);
		
		public signal void updated();
		
		public void update (Vala.Namespace root) {
			store.clear();
			try {
				Thread.create<void>(() => {
					var symbol = new Symbol (root);
					foreach (var child in symbol.children)
						append_symbol (child);
					updated();
				}, false);
			} catch {
			
			}
		}
		
		void append_symbol (Symbol symbol, Gtk.TreeIter? parent = null) {
			Gtk.TreeIter iter;
			store.append (out iter, parent);
			store.set (iter, 0, new Gdk.Pixbuf.from_resource (symbol.icon_path), 1, symbol.name, 3, symbol);
		}
	}
}
