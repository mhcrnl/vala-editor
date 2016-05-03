namespace Editor {
	public class SymbolItem : GLib.Object, Gtk.SourceCompletionProposal {
		public SymbolItem (Vala.Symbol symbol) {
			GLib.Object (symbol: symbol);
		}
		
		Icon icon;
		string info;
		
		construct {
			icon = new BytesIcon (resources_lookup_data ("/resources/icons/%s.png".printf (symbol.type_name.substring (4).down()),
				ResourceLookupFlags.NONE));
				
			info = symbol.is_private_symbol() ? " " : "public ";
			
			if (symbol is Vala.Constant) {
				info += "const ";
			}
			else if (!(symbol is Vala.Method || symbol is Vala.Field || symbol is Vala.Property || symbol is Vala.Variable))
				info += "%s ".printf (symbol.type_name.substring (4).down());
			if (symbol is Vala.Delegate) {
				var del = symbol as Vala.Delegate;
				info += del.return_type.to_string() + " ";
				string str = "";
				foreach (var param in del.get_parameters())
					str += param.variable_type.to_string() + " " + param.name + ", ";
				if (str.length > 1)
					str = str.substring (0, str.length - 2);
				info += del.name + "(" + str + ")";
			}
			else if (symbol is Vala.Signal) {
				var sig = symbol as Vala.Signal;
				info += sig.return_type.to_string() + " ";
				string str = "";
				foreach (var param in sig.get_parameters())
					str += param.variable_type.to_string() + " " + param.name + ", ";
				if (str.length > 1)
					str = str.substring (0, str.length - 2);
				info += sig.name + "(" + str + ")";
			}
			else if (symbol is Vala.Method) {
				var meth = symbol as Vala.Method;
				if ((meth.binding & Vala.MemberBinding.STATIC) != 0)
					info += "static ";
				string str = "";
				foreach (var param in meth.get_parameters())
					if (param.variable_type != null)
						str += param.variable_type.to_string() + " " + param.name + ", ";
				if (str.length > 1)
					str = str.substring (0, str.length - 2);
				string mn = "";
				if (meth is Vala.CreationMethod)
					mn = (meth as Vala.CreationMethod).class_name;
				else
					mn = meth.return_type.to_string();
				str = mn + " " + meth.name + " (" + str + ")";
				info += str;
			}
			else if (symbol is Vala.Property) {
				var prop = symbol as Vala.Property;
				if ((prop.binding & Vala.MemberBinding.STATIC) != 0)
					info += "static ";
				string str = "{ ";
				if (prop.get_accessor != null) {
					if (prop.get_accessor.is_private_symbol())
						str += "private ";
					if (prop.get_accessor.is_internal_symbol())
						str += "internal ";
					str += "get; ";
				}
				if (prop.set_accessor != null) {
					if (prop.set_accessor.is_private_symbol())
						str += "private ";
					if (prop.set_accessor.is_internal_symbol())
						str += "internal ";
					str += "set; ";
				}
				str += "}";
				info += prop.property_type.to_string() + " " + prop.name + " " + str;
			}
			else if (symbol is Vala.Variable) {
				var v = symbol as Vala.Variable;
				info += v.variable_type.to_string() + " " + v.name;
			}
			else if (symbol is Vala.EnumValue || symbol is Vala.ErrorDomain) {
				info += symbol.parent_symbol.name + " " + symbol.name;
			}
			else if (symbol is Vala.Constant) {
				info += (symbol as Vala.Constant).type_reference.to_string() + " " + symbol.name;
			}
			else
				info += symbol.name;
			if (symbol.comment != null)
				info += "\n" + symbol.comment.content;
		}
		
		public unowned GLib.Icon? get_gicon() {
			return icon;
		}
		public unowned string? get_icon_name() { return null; }
		public string? get_info() { return info; }
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
			start_line = -1;
			start_column = -1;
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
			if (info_label == null)
				info_label = new Gtk.Label ("");
			info_label.label = proposal.get_info();
			info_label.show_all();
			return info_label;
		}
		
		public void update_info (Gtk.SourceCompletionProposal proposal, Gtk.SourceCompletionInfo info) {
		}
		
		static string normalize (string str) {
			string[] result = new string[0];
			int len = str.length;
			int i = 0;
			string cur = "";
			while (i < len) {
				if (str[i] == '"') {
					var j = str.index_of ("\"", i + 1);
					if (j == -1) {
						result = new string[0];
						cur = "";
						return null;
					}
					cur += str.substring (i, j + 1 - i);
					i = j + 1;
				}
				else if (str[i] == '.') {
					result += cur;
					cur = "";
					i++;
				}
				else {
					cur += str[i].to_string();
					i++;
				}
			}
			result += cur;
			for (var z = 0; z < result.length; z++) {
				int index = result[z].index_of ("(");
				string s = result[z].substring (0, index).strip();
				if (z == result.length - 1)
					s = result[z].substring (0, index);
				if (index != -1)
					s += "(";
				if (index != -1 && index + 1 < result[z].length)
					s += result[z].substring (index + 1).strip();
				result[z] = s;
			}
			return string.joinv (".", result);
		}
		
		int start_line;
		int start_column;
		/*
		public bool activate_proposal (Gtk.SourceCompletionProposal proposal, Gtk.TextIter iter) {
			Gtk.TextIter start;
			document.view.buffer.get_iter_at_line_offset (out start, start_line, start_column);
			string text = start.get_text (iter);
			text = (proposal as SymbolItem).symbol.name.substring (text.length);
			document.view.buffer.insert_at_cursor (text, text.length);
			start_line = -1;
			start_column = -1;
			return false;
		}
		*/
		
		public signal void hide();
		
		public void populate (Gtk.SourceCompletionContext context) {
			Gtk.TextIter iter, start;
			context.get_iter (out iter);
			if (start_line != iter.get_line()) {
				start_line = iter.get_line();
				start_column = iter.get_line_offset() - 1;
			}
			var list = new List<Gtk.SourceCompletionProposal>();
			string text = document.get_current_text (iter);
			var ntext = normalize (text);
			if (ntext == null)
				return;
			MatchInfo match_info;
			if (!member_access.match (ntext, 0, out match_info))
				return;
			if (match_info.fetch(0).length < 1)  {
				hide();
				return;
			}
			string prefix = match_info.fetch (2);
		//	string prefix = text.substring (text.last_index_of (match_info.fetch (2)));
			var names = member_access_split.split (match_info.fetch (1));
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
				names[names.length - 1] = prefix;
				list = new List<Gtk.SourceCompletionProposal>();
				document.visible_symbols.foreach (sym => {
					if (sym != null && sym.name == names[0])
						list.append (new SymbolItem (sym));
					return true;
				});
				for (var i = 1; i < names.length; i++) {
					Vala.Symbol? current = null;
					list.foreach (prop => {
						if (current != null)
							return;
						var sym = (prop as SymbolItem).symbol;
						if (sym.name == names[i - 1])
							current = sym;
					});
					if (current == null)
						break;
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
