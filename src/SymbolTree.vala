namespace Editor {
	public class SymbolTree : Gtk.ScrolledWindow {
		Gtk.TreeStore store;
		
		construct {
			store = new Gtk.TreeStore (2, typeof (Icon), typeof (string));
			
			var view = new Gtk.TreeView.with_model (store);
			view.insert_column_with_attributes (-1, null, new Gtk.CellRendererPixbuf(), "gicon", 0);
			view.insert_column_with_attributes (-1, null, new Gtk.CellRendererText(), "text", 1);
			
			add (view);
		}
		
		public signal void updated();
		
		public void update (Vala.Namespace root) {
			store.clear();
			try {
				Thread.create<void>(() => {
					var symbol = new Symbol (root);
					foreach (var child in symbol.get_children())
						append_symbol (child);
					updated();
				}, false);
			} catch {
			
			}
		}
		
		void append_symbol (Symbol symbol, Gtk.TreeIter? parent = null) {
			Gtk.TreeIter iter;
			store.append (out iter, parent);
			store.set (iter, 0, symbol.icon, 1, symbol.name);
			foreach (var child in symbol.get_children())
				append_symbol (child, iter);
		}
	}
}
