namespace Editor {
	public class SymbolTree : Gtk.ScrolledWindow {
		
		construct {
			
		}
		
		public signal void symbol_activated (Symbol symbol);
		
		public signal void updated();
		
		public void update (Vala.Namespace root) {
			
		}
	}
}
