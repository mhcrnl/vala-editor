namespace Editor {
	public class SymbolItem : GLib.Object, Gtk.SourceCompletionProposal {
		public SymbolItem (Vala.Symbol symbol) {
			GLib.Object (symbol: symbol);
		}
		
		Icon icon;
		
		construct {
			icon = new BytesIcon (resources_lookup_data ("/resources/icons/%s.png".printf (symbol.type_name.substring (4).down()),
				ResourceLookupFlags.NONE));
		}
		
		public unowned GLib.Icon? get_gicon() {
			return icon;
		}
		public unowned string? get_icon_name() { return null; }
		public string? get_info() { return symbol.name; }
		public string get_label() { return symbol.name; }
		public string get_markup() { return symbol.name; }
		public string get_text() { return symbol.name; }
		
		public Vala.Symbol symbol { get; construct; }
	}
	
	public class Provider : GLib.Object, Gtk.SourceCompletionProvider {
		public Provider (Document document) {
			GLib.Object (document: document);
		}
		
		Regex member_access;
		Regex member_access_split;
		
		construct {
			member_access = new Regex ("""((?:\w+(?:\s*\([^()]*\))?\.)*)(\w*)$""");
			member_access_split = new Regex ("""(\s*\([^()]*\))?\.""");
			icon = new Gdk.Pixbuf.from_resource ("/resources/icons/gnome.png");
		}
		
		public Document document { get; construct; }
		
		public string get_name() {
			return "Vala";
		}
		
		Gdk.Pixbuf icon;
		
		public unowned Gdk.Pixbuf? get_icon() {
			return icon;
		}
		
		Gtk.Label info_label;
		
		public unowned Gtk.Widget? get_info_widget (Gtk.SourceCompletionProposal proposal) {
			var symbol = (proposal as SymbolItem).symbol;
			if (info_label == null)
				info_label = new Gtk.Label ("");
			string info = "";
			if (symbol.is_internal_symbol())
				info += "internal ";
			else if (symbol.is_private_symbol())
				info += "private ";
			else
				info += "public ";
			
			if (symbol is Vala.Method) {
				var meth = symbol as Vala.Method;
				if ((meth.binding & Vala.MemberBinding.STATIC) != 0)
					info += "static ";
				string str = "";
				foreach (var param in meth.get_parameters())
					if (param.variable_type != null)
						str += param.variable_type.to_string() + " " + param.name + ", ";
				if (str.length > 1)
					str = str.substring (0, str.length - 2);
				str = meth.return_type.to_string() + " " + meth.name + " (" + str + ")";
				info_label.label = info + str;
			}
			else if (symbol is Vala.Property) {
				var prop = symbol as Vala.Property;
				if ((prop.binding & Vala.MemberBinding.STATIC) != 0)
					info += "static ";
				string str = "{ ";
				if (prop.get_accessor != null)
					str += "get; ";
				if (prop.set_accessor != null)
					str += "set; ";
				str += "}";
				info_label.label = info + prop.property_type.to_string() + " " + prop.name + " " + str;
			}
			else if (symbol is Vala.Variable) {
				var v = symbol as Vala.Variable;
				info_label.label = info + v.variable_type.to_string() + " " + v.name;
			}
			else
				info_label.label = info + symbol.name;
			info_label.show_all();
			return info_label;
		}
		
		public void update_info (Gtk.SourceCompletionProposal proposal, Gtk.SourceCompletionInfo info) {
		}
		
		public void populate (Gtk.SourceCompletionContext context) {
			var list = new List<Gtk.SourceCompletionProposal>();
			Gtk.TextIter iter, start;
			context.get_iter (out iter);
			string text = document.get_current_text (iter);
			MatchInfo match_info;
			if (!member_access.match (text, 0, out match_info))
				return;
			if (match_info.fetch(0).length < 1)
				return;
			string prefix = match_info.fetch (2);
			var names = member_access_split.split (match_info.fetch (1));
			if (names.length > 0) {
				names[names.length - 1] = prefix;
				prefix = names[0];
			}
			document.visible_symbols.foreach (sym => {
				if (sym != null && sym.name.has_prefix (prefix))
					list.append (new SymbolItem (sym));
				return true;
			});
			string[] ns = new string[0];
			foreach (var name in names)
				if (name[0] != '(')
					ns += name;
			names = new string[0];
			foreach (var name in ns)
				names += name;
			if (names.length > 0) {
				for (var i = 1; i < names.length; i++) {
					if (list.length() == 0)
						break;
					Vala.Symbol? current = null;
					list.foreach (prop => {
						var item = prop as SymbolItem;
						var j = i;
						string name = names[i - 1];
						if (item.symbol.name == names[i-1])
							current = item.symbol;
					});
					list = new List<Gtk.SourceCompletionProposal>();
					document.manager.engine.get_symbols_for_name (current, names[i], false).foreach (sym => {
						list.append (new SymbolItem (sym));
						return true;
					});
				}
			}
			
			CompareFunc<Gtk.SourceCompletionProposal> cmp = (a, b) => {
				var na = (a as SymbolItem).symbol.name;
				var nb = (b as SymbolItem).symbol.name;
				return strcmp (na, nb);
			};
			list.sort (cmp);
			
			context.add_proposals (this, list, true);
		}
		
		Vala.Expression construct_member_access (string[] names) {
			Vala.Expression expr = null;

			for (var i = 0; names[i] != null; i++) {
				if (names[i] != "") {
					expr = new Vala.MemberAccess (expr, names[i]);
					if (names[i+1] != null && names[i+1].chug ().has_prefix ("(")) {
						expr = new Vala.MethodCall (expr);
						i++;
					}
				}
			}

			return expr;
		}
	}
}
