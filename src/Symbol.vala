namespace Editor {
	static bool location_before (Vala.SourceLocation location, Vala.SourceLocation other) {
		if (location.line > other.line)
			return false;
		if (location.line == other.line && location.column > other.column)
			return false;
		return true;
	}
	
	static bool reference_before (Vala.SourceReference reference, Vala.SourceReference other) {
		return location_before (reference.end, other.begin);
	}
	
	public class Symbol : GLib.Object {
		internal Vala.Symbol handle;
		internal Vala.SourceReference source_reference;
		
		internal Symbol (Vala.Symbol vsymbol) {
			handle = vsymbol;
			source_reference = vsymbol.source_reference;
		}
		
		static Gee.List<Symbol> fill_symbols (Vala.Symbol vsymbol) {
			var symbols = new Gee.ArrayList<Symbol>((a, b) => {
				return (a as Symbol).name == (b as Symbol).name;
			});
			if (vsymbol is Vala.Namespace) {
				var symbol = vsymbol as Vala.Namespace;
				foreach (var sym in symbol.get_namespaces())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_classes())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_constants())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_delegates())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_enums())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_error_domains())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_fields())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_interfaces())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_methods())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_delegates())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_structs())
					symbols.add (new Symbol (sym));
			}
			else if (vsymbol is Vala.Interface) {
				var symbol = vsymbol as Vala.Interface;
				foreach (var sym in symbol.get_classes())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_constants())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_delegates())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_enums())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_fields())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_properties())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_methods())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_signals())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_structs())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_virtuals())
					symbols.add (new Symbol (sym));
			}
			else if (vsymbol is Vala.Class) {
				var symbol = vsymbol as Vala.Class;
				foreach (var sym in symbol.get_classes())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_constants())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_delegates())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_enums())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_fields())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_properties())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_methods())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_signals())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_structs())
					symbols.add (new Symbol (sym));
			}
			else if (vsymbol is Vala.Struct) {
				var symbol = vsymbol as Vala.Struct;
				foreach (var sym in symbol.get_constants())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_fields())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_properties())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_methods())
					symbols.add (new Symbol (sym));
			}	
			else if (vsymbol is Vala.Enum) {
				var symbol = vsymbol as Vala.Enum;
				foreach (var sym in symbol.get_values())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_methods())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_constants())
					symbols.add (new Symbol (sym));
			}
			else if (vsymbol is Vala.ErrorDomain) {
				var symbol = vsymbol as Vala.ErrorDomain;
				foreach (var sym in symbol.get_codes())
					symbols.add (new Symbol (sym));
				foreach (var sym in symbol.get_methods())
					symbols.add (new Symbol (sym));
			}
			else if (vsymbol is Vala.Parameter) {
				var symbol = vsymbol as Vala.Parameter;
				symbols.add_all (fill_symbols (symbol.variable_type.data_type));
			}
			else if (vsymbol is Vala.Property) {
				var symbol = vsymbol as Vala.Property;
				symbols.add_all (fill_symbols (symbol.property_type.data_type));
			}
			else if (vsymbol is Vala.Field) {
				var symbol = vsymbol as Vala.Field;
				symbols.add_all (fill_symbols (symbol.variable_type.data_type));
			}
			else if (vsymbol is Vala.LocalVariable) {
				var symbol = vsymbol as Vala.LocalVariable;
				symbols.add_all (fill_symbols (symbol.variable_type.data_type));
			}
			symbols.sort ((s1, s2) => {
				if (s1.source_reference.file.filename != s2.source_reference.file.filename)
					return strcmp (s1.source_reference.file.filename, s2.source_reference.file.filename);
				var ref1 = s1.source_reference;
				var ref2 = s2.source_reference;
				if (reference_before (ref1, ref2))
					return -1;
				if (reference_before (ref2, ref1))
					return 1;
				return 0;
			});
			return symbols;
		}
		
		public Gee.List<Symbol> children {
			owned get {
				return fill_symbols (handle);
			}
		}
		
		public string icon_path {
			owned get {
				return "/resources/icons/%s.png".printf (handle.type_name.substring (4).down());
			}
		}
		
		public string name {
			owned get {
				return handle.name;
			}
		}
		
		public Symbol? parent {
			owned get {
				if (handle.parent_symbol == null)
					return null;
				return new Symbol (handle.parent_symbol);
			}
		}
		
	}
}
