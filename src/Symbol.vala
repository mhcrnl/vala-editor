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
		internal Vala.Symbol vsymbol;
		internal Vala.SourceReference source_reference;
		
		internal Symbol (Vala.Symbol vsymbol) {
			this.vsymbol = vsymbol;
			source_reference = vsymbol.source_reference;
		}
		
		public List<Symbol> get_children() {
			var list = new List<Symbol>();
			if (vsymbol is Vala.Namespace) {
				var symbol = vsymbol as Vala.Namespace;
				foreach (var sym in symbol.get_namespaces())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_classes())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_constants())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_delegates())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_enums())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_error_domains())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_fields())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_interfaces())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_methods())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_delegates())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_structs())
					list.append (new Symbol (sym));
			}
			
			if (vsymbol is Vala.Interface) {
				var symbol = vsymbol as Vala.Interface;
				foreach (var sym in symbol.get_classes())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_constants())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_delegates())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_enums())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_fields())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_properties())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_methods())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_signals())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_structs())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_virtuals())
					list.append (new Symbol (sym));
			}
			
			if (vsymbol is Vala.Class) {
				var symbol = vsymbol as Vala.Class;
				foreach (var sym in symbol.get_classes())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_constants())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_delegates())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_enums())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_fields())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_properties())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_methods())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_signals())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_structs())
					list.append (new Symbol (sym));
			}
			
			if (vsymbol is Vala.Struct) {
				var symbol = vsymbol as Vala.Struct;
				foreach (var sym in symbol.get_constants())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_fields())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_properties())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_methods())
					list.append (new Symbol (sym));
			}
			
			if (vsymbol is Vala.Enum) {
				var symbol = vsymbol as Vala.Enum;
				foreach (var sym in symbol.get_values())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_methods())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_constants())
					list.append (new Symbol (sym));
			}
			
			if (vsymbol is Vala.ErrorDomain) {
				var symbol = vsymbol as Vala.ErrorDomain;
				foreach (var sym in symbol.get_codes())
					list.append (new Symbol (sym));
				foreach (var sym in symbol.get_methods())
					list.append (new Symbol (sym));
			}
			
			list.sort_with_data ((s1, s2) => {
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
			return list;
		}
		
		public GLib.Icon icon {
			owned get {
				return new BytesIcon (resources_lookup_data ("/resources/icons/%s.png".printf (vsymbol.type_name.substring (4).down()),
					ResourceLookupFlags.NONE));
			}
		}
		
		public string name {
			owned get {
				return vsymbol.name;
			}
		}
		
		public Symbol? parent {
			owned get {
				if (vsymbol.parent_symbol == null)
					return null;
				return new Symbol (vsymbol.parent_symbol);
			}
		}
	}
}
