namespace Editor {
	public class Package : GLib.Object {
		public Package (string id, string name, string description) {
			GLib.Object (id: id, name: name, description: description);
		}
		
		public string description { get; construct; }
		public string id { get; construct; }
		public string name { get; construct; }
	}
	
	public class Engine : GLib.Object, Gtk.SourceCompletionProvider {
		Vala.CodeContext context;
		Vala.Parser parser;
		BlockLocator locator;
		Report report;
		
		static Gee.ArrayList<Package> packages;
		
		static Package process_line (string line) {
			string description, id, name;
			StringBuilder sb = new StringBuilder();
			int i = 0;
			while (!line[i].isspace()) {
				sb.append_c (line[i]);
				i++;
			}
			id = sb.str;
			sb = new StringBuilder();
			while (line[i].isspace())
				i++;
			name = line.substring (i);
			description = name.split (" - ")[1];
			name = name.split (" - ")[0];
			return new Package (id, name, description);
		}
		
		static construct {
			process();
		}
		
		static void process() {
			packages = new Gee.ArrayList<Package>((p1, p2) => {
				return (p1.id == p2.id && p1.name == p2.name && p1.description == p2.description);
			});
			
			string output, err;
			Process.spawn_command_line_sync ("pkg-config --list-all", out output, out err);
			output = output.strip();
			foreach (string line in output.split ("\n"))
				packages.add (process_line (line));
			packages.sort ((p1, p2) => {
				return strcmp (p1.id, p2.id);
			});
		}
		
		public static Gee.List<Package> list_packages() {
			if (packages == null)
				process();
			return packages;
		}
		
		public static Gee.Iterator<Package> list_available_packages() {
			if (packages == null)
				process();
			var context = new Vala.CodeContext();
			context.profile = Vala.Profile.GOBJECT;
			
			return packages.filter (package => {
				return context.get_vapi_path (package.id) != null || context.get_gir_path (package.id) != null;
			});
		}
		
		
		public static bool package_exists (string package, string[] vapidirs) {
			bool res = false;
			foreach (string vapidir in vapidirs)
				if (FileUtils.test (vapidir + "/" + package + ".vapi", FileTest.IS_REGULAR))	
					return true;
			list_available_packages().foreach (pkg => {
				if (pkg.id == package)
					res = true;
				return true;
			});
			return res;
		}
		
		construct {
			report = new Report();
			locator = new BlockLocator();
			context = new Vala.CodeContext();
			context.report = report;
			context.profile = Vala.Profile.GOBJECT;
			parser = new Vala.Parser();
			parser.parse (context);
		}

		public void init() {
			report = new Report();
			locator = new BlockLocator();
			context = new Vala.CodeContext();
			context.report = report;
			context.profile = Vala.Profile.GOBJECT;
			parser = new Vala.Parser();
			parser.parse (context);
		}
		
		public bool add_package (string package) {
			if (!context.has_package ("gobject-2.0")) {
				context.add_external_package ("glib-2.0");
				context.add_external_package ("gobject-2.0");
			}
			return context.add_external_package (package);
		}
		
		public bool add_vapidir (string vapidir) {
			if (!FileUtils.test (vapidir, FileTest.IS_DIR))
				return false;
			var hset = new Gee.HashSet<string>();
			hset.add_all_array (context.vapi_directories);
			hset.add (vapidir);
			context.vapi_directories = hset.to_array();
			return true;
		}
		
		public void add_document (Document document) {
			Vala.CodeContext.push (context);
			foreach (var file in context.get_source_files()) {
				if (file.filename == document.location) {
					Vala.CodeContext.pop();
					return;
				}
			}
			context.add_source_filename (document.location);
			if (!context.has_package ("gobject-2.0")) {
				context.add_external_package ("glib-2.0");
				context.add_external_package ("gobject-2.0");
			}
			Vala.CodeContext.pop();
		}
		
		public void add_source (string source) {
			Vala.CodeContext.push (context);
			foreach (var file in context.get_source_files()) {
				if (file.filename == source) {
					Vala.CodeContext.pop();
					return;
				}
			}
			context.add_source_filename (source);
			if (!context.has_package ("gobject-2.0")) {
				context.add_external_package ("glib-2.0");
				context.add_external_package ("gobject-2.0");
			}
			Vala.CodeContext.pop();
		}
		
		public Vala.Symbol? lookup_symbol_at (string filename, int line, int column) {
			Vala.SourceFile? source = null;
			lock (context) {
				foreach (var file in context.get_source_files()) {
					if (file.filename == filename)  {
						source = file;
						break;
					}
				}
			}
			if (source == null)
				return null;
			return locator.locate (source, line, column);
		}
		
		Vala.MemberBinding prev_binding;
		bool prev_access;
		
		Gee.Collection<Vala.Symbol> lookup_symbol (Vala.Symbol? symbol) {
			var list = new Gee.ArrayList<Vala.Symbol>();
			if (symbol == null)
				return list;
			prev_binding = Vala.MemberBinding.CLASS;
			prev_access = false;
			lock (context) {
				for (var sym = symbol; sym != null; sym = sym.parent_symbol) {
					list.add_all (lookup_symbol_inherited (sym));
				}
				foreach (var ns in symbol.source_reference.file.current_using_directives)
					list.add_all (lookup_symbol_inherited (ns.namespace_symbol));
			}
			return list;
		}	
		
		Gee.Collection<Vala.Symbol> lookup_symbol_inherited (Vala.Symbol? sym) {
			var list = new Gee.ArrayList<Vala.Symbol>();
			if (sym == null)
				return list;
			var symbol_table = sym.scope.get_symbol_table ();
			if (symbol_table != null)
				foreach (string key in symbol_table.get_keys()) {
					var child = symbol_table[key];
					if ((prev_binding != Vala.MemberBinding.STATIC || sym is Vala.Namespace) && 
						(!prev_access || prev_access && (child.access & Vala.SymbolAccessibility.PRIVATE) == 0))
							list.add (child);
					else if (prev_binding == Vala.MemberBinding.STATIC) {
						if ((child is Vala.Property && (child as Vala.Property).binding == Vala.MemberBinding.STATIC ||
							child is Vala.Method && (child as Vala.Method).binding == Vala.MemberBinding.STATIC ||
							child is Vala.Field && (child as Vala.Field).binding == Vala.MemberBinding.STATIC) && 
							(!prev_access || prev_access && (child.access & Vala.SymbolAccessibility.PRIVATE) == 0))
								list.add (child);
					}
				}
			if (sym is Vala.Signal) {
				var sig = sym as Vala.Signal;
				foreach (var p in sig.get_parameters()) {}
			}
			if (sym is Vala.Method) {
				// add missing local variables.
				foreach (var lv in (sym as Vala.Method).body.get_local_variables())
					list.add (lv);
			}
			if (sym is Vala.Class) {
				var klass = sym as Vala.Class;
				foreach (var bt in klass.get_base_types())
					list.add_all (lookup_symbol_inherited (bt.data_type));
			}
			if (sym is Vala.Interface) {
				var iface = sym as Vala.Interface;
				foreach (var pre in iface.get_prerequisites())
					list.add_all (lookup_symbol_inherited (pre.data_type));
			}
			if (sym is Vala.Method && !(sym.parent_symbol is Vala.Block) && prev_binding != Vala.MemberBinding.STATIC) {
				prev_binding = (sym as Vala.Method).binding;
				prev_access = true;
			}
			else if (!(sym is Vala.Block) || (sym is Vala.Block) && !(sym.parent_symbol is Vala.Method))
				prev_access = true;
			return list;
		}
		
		public Gee.Collection<Vala.Symbol?> lookup_visible_symbols_at (string filename, int line, int column) {
			var symbol = lookup_symbol_at (filename, line, column);
			if (symbol == null)
				symbol = lookup_symbol_at (filename, line - 1, column);
			var hashset = new Gee.HashSet<Vala.Symbol?>(symbol_hash, symbol_equal);
			var list = lookup_symbol (symbol);
			if (symbol != null)
				hashset.add_all (list);
			/*
			lock (context) {
				foreach (var file in context.get_source_files()) {
					if (file.file_type == Vala.SourceFileType.SOURCE && file.filename != filename) {
						foreach (var ud in file.current_using_directives)
							append_visible_symbols (hashset, ud.namespace_symbol);
						foreach (var node in file.get_nodes()) 
							if (node is Vala.Symbol) {
								var sym = node as Vala.Symbol;
								if (symbol != null && sym.is_accessible (symbol) && (sym.parent_symbol == null || sym.parent_symbol.name == null))
									hashset.add (sym);
							}
					}
				}
			}
			*/
			return hashset;
		}
		
		uint symbol_hash (Vala.Symbol? symbol) {
			if (symbol == null)
				return 0;
			return str_hash (symbol.name);
		}
		
		bool symbol_equal (Vala.Symbol? symbol, Vala.Symbol? other) {
			if (symbol == null && other == null)
				return true;
			if (symbol == null || other == null)
				return false;
			return str_equal (symbol.name, other.name);
		}
		
		public Gee.Collection<Vala.Symbol> get_symbols_for_name (Vala.Symbol? symbol, string name, bool match, Vala.MemberBinding binding = Vala.MemberBinding.CLASS) {
			var hashset = new Gee.HashSet<Vala.Symbol?>(symbol_hash, symbol_equal);
			if (symbol != null)
				foreach (var sym in gsfm (symbol, name, match, binding))
					hashset.add (sym);
			return hashset;
		}
		
		Gee.Collection<Vala.Symbol> gsfm (Vala.Symbol? symbol, string name, bool match, Vala.MemberBinding binding = Vala.MemberBinding.CLASS) {
			if (symbol == null)
				return new Gee.ArrayList<Vala.Symbol>();
			if (symbol is Vala.Parameter)
				return gsfm ((symbol as Vala.Parameter).variable_type.data_type, name, match, Vala.MemberBinding.INSTANCE);
			if (symbol is Vala.Property)
				return gsfm ((symbol as Vala.Property).property_type.data_type, name, match, (symbol as Vala.Property).binding);
			if (symbol is Vala.Field)
				return gsfm ((symbol as Vala.Field).variable_type.data_type, name, match, (symbol as Vala.Field).binding);
			if (symbol is Vala.LocalVariable)
				return gsfm ((symbol as Vala.LocalVariable).variable_type.data_type, name, match, Vala.MemberBinding.INSTANCE);
			if (symbol is Vala.Namespace)
				return get_symbols_for_namespace (symbol as Vala.Namespace, name, match, binding);
			if (symbol is Vala.Class)
				return get_symbols_for_class (symbol as Vala.Class, name, match, binding);
			if (symbol is Vala.Struct)
				return get_symbols_for_struct (symbol as Vala.Struct, name, match, binding);
			if (symbol is Vala.Enum)
				return get_symbols_for_enum (symbol as Vala.Enum, name, match, binding);
			if (symbol is Vala.ErrorDomain)
				return get_symbols_for_error_domain (symbol as Vala.ErrorDomain, name, match, binding);
			if (symbol is Vala.Interface)
				return get_symbols_for_interface (symbol as Vala.Interface, name, match, binding);
			if (symbol is Vala.Method)
				return gsfm ((symbol as Vala.Method).return_type.data_type, name, match, (symbol as Vala.Method).binding);
			if (symbol is Vala.Signal)
				return get_symbols_for_signal (symbol as Vala.Signal, name, match, binding);
			return new Gee.ArrayList<Vala.Symbol>();
		}
		
		Gee.List<Vala.Symbol> get_symbols_for_signal (Vala.Signal sig, string name, bool match, Vala.MemberBinding binding) {
			var list = new Gee.ArrayList<Vala.Symbol>();
			if (match && name == "connect" || "connect".has_prefix (name)) {
				var m = new Vala.Method ("connect", new Vala.SignalType (sig));
				list.add (m);
			}
			if (match && name == "disconnect" || "disconnect".has_prefix (name)) {
				var m = new Vala.Method ("disconnect", new Vala.VoidType());
				list.add (m);
			}
			return list;
		}
		
		Gee.List<Vala.Symbol> get_symbols_for_error_domain (Vala.ErrorDomain ed, string name, bool match, Vala.MemberBinding binding) {
			var list = new Gee.ArrayList<Vala.Symbol>();
			if (binding == Vala.MemberBinding.CLASS) {
				foreach (var code in ed.get_codes())
					if ((match && name == code.name) || code.name.has_prefix (name))
						list.add (code);
			} 
			foreach (var m in ed.get_methods()) {
				if (m.binding == Vala.MemberBinding.INSTANCE && binding != Vala.MemberBinding.CLASS ||
				binding == Vala.MemberBinding.CLASS && m.binding == Vala.MemberBinding.STATIC)
					if ((match && name == m.name) || m.name.has_prefix (name))
						list.add (m);
			}
			return list;
		}
		
		Gee.List<Vala.Symbol> get_symbols_for_enum (Vala.Enum e, string name, bool match, Vala.MemberBinding binding) {
			var list = new Gee.ArrayList<Vala.Symbol>();
			if (binding == Vala.MemberBinding.CLASS) {
				foreach (var c in e.get_constants())
					if ((match && name == c.name) || c.name.has_prefix (name))
						list.add (c);
				foreach (var ev in e.get_values())
					if ((match && name == ev.name) || ev.name.has_prefix (name))
						list.add (ev);
			}
			foreach (var m in e.get_methods())
				if (m.binding == Vala.MemberBinding.INSTANCE && binding != Vala.MemberBinding.CLASS ||
				binding == Vala.MemberBinding.CLASS && m.binding == Vala.MemberBinding.STATIC)
					if ((match && name == m.name) || m.name.has_prefix (name))
						list.add (m);
			return list;
		}
		
		Gee.List<Vala.Symbol> get_symbols_for_namespace (Vala.Namespace ns, string name, bool match, Vala.MemberBinding binding) {
			var list = new Gee.ArrayList<Vala.Symbol>();
			foreach (var cls in ns.get_classes())
				if ((match && name == cls.name) || cls.name.has_prefix (name))
					list.add (cls);
			foreach (var c in ns.get_constants())
				if ((match && name == c.name) || c.name.has_prefix (name))
					list.add (c);
			foreach (var d in ns.get_delegates())
				if ((match && name == d.name) || d.name.has_prefix (name))
					list.add (d);
			foreach (var e in ns.get_enums())
				if ((match && name == e.name) || e.name.has_prefix (name))
					list.add (e);
			foreach (var ed in ns.get_error_domains())
				if ((match && name == ed.name) || ed.name.has_prefix (name))
					list.add (ed);
			foreach (var f in ns.get_fields())
				if ((match && name == f.name) || f.name.has_prefix (name))
					list.add (f);
			foreach (var i in ns.get_interfaces())
				if ((match && name == i.name) || i.name.has_prefix (name))
					list.add (i);
			foreach (var n in ns.get_namespaces())
				if ((match && name == n.name) || n.name.has_prefix (name))
					list.add (n);
			foreach (var m in ns.get_methods())
				if ((match && name == m.name) || m.name.has_prefix (name))
					list.add (m);
			foreach (var s in ns.get_structs())
				if ((match && name == s.name) || s.name.has_prefix (name))
					list.add (s);
			return list;
		}
	
		Gee.List<Vala.Symbol> get_symbols_for_interface (Vala.Interface intf, string name, bool match, Vala.MemberBinding binding) {
			var list = new Gee.ArrayList<Vala.Symbol>();
			if (binding == Vala.MemberBinding.CLASS) {
				foreach (var cls in intf.get_classes())
					if ((match && name == cls.name) || cls.name.has_prefix (name))
						list.add (cls);
				foreach (var c in intf.get_constants())
					if ((match && name == c.name) || c.name.has_prefix (name))
						list.add (c);
				foreach (var d in intf.get_delegates())
					if ((match && name == d.name) || d.name.has_prefix (name))
						list.add (d);
				foreach (var e in intf.get_enums())
					if ((match && name == e.name) || e.name.has_prefix (name))
						list.add (e);
				foreach (var s in intf.get_structs())
					if ((match && name == s.name) || s.name.has_prefix (name))
						list.add (s);
			}
			foreach (var f in intf.get_fields())
				if (f.binding == Vala.MemberBinding.INSTANCE && binding != Vala.MemberBinding.CLASS ||
				binding == Vala.MemberBinding.CLASS && f.binding == Vala.MemberBinding.STATIC)
					if ((match && name == f.name) || f.name.has_prefix (name))
						list.add (f);
			foreach (var m in intf.get_methods())
				if (m.binding == Vala.MemberBinding.INSTANCE && binding != Vala.MemberBinding.CLASS && !(m is Vala.CreationMethod) ||
				binding == Vala.MemberBinding.CLASS && (m.binding == Vala.MemberBinding.STATIC || m is Vala.CreationMethod))
					if ((match && name == m.name) || m.name.has_prefix (name))
						list.add (m);
			foreach (var p in intf.get_properties())
				if (p.binding == Vala.MemberBinding.INSTANCE && binding != Vala.MemberBinding.CLASS ||
				binding == Vala.MemberBinding.CLASS && p.binding == Vala.MemberBinding.STATIC)
					if ((match && name == p.name) || p.name.has_prefix (name))
						list.add (p);
			foreach (var s in intf.get_signals())
				if (binding != Vala.MemberBinding.CLASS)
					if ((match && name == s.name) || s.name.has_prefix (name))
						list.add (s);
			if (binding == Vala.MemberBinding.INSTANCE) {
				foreach (var dt in intf.get_prerequisites())
					foreach (var sym in gsfm (dt.data_type, name, match, binding))
						list.add (sym);
			}
			return list;
		}
		
		Gee.List<Vala.Symbol> get_symbols_for_class (Vala.Class klass, string name, bool match, Vala.MemberBinding binding) {
			var list = new Gee.ArrayList<Vala.Symbol>();
			if (binding == Vala.MemberBinding.CLASS) {
				foreach (var cls in klass.get_classes())
					if ((match && name == cls.name) || cls.name.has_prefix (name))
						list.add (cls);
				foreach (var c in klass.get_constants())
					if ((match && name == c.name) || c.name.has_prefix (name))
						list.add (c);
				foreach (var d in klass.get_delegates())
					if ((match && name == d.name) || d.name.has_prefix (name))
						list.add (d);
				foreach (var e in klass.get_enums())
					if ((match && name == e.name) || e.name.has_prefix (name))
						list.add (e);
				foreach (var s in klass.get_structs())
					if ((match && name == s.name) || s.name.has_prefix (name))
						list.add (s);
			}
			foreach (var f in klass.get_fields())
				if (f.binding == Vala.MemberBinding.INSTANCE && binding != Vala.MemberBinding.CLASS ||
				binding == Vala.MemberBinding.CLASS && f.binding == Vala.MemberBinding.STATIC)
					if ((match && name == f.name) || f.name.has_prefix (name))
						list.add (f);
			foreach (var m in klass.get_methods()) {
				if (m.binding == Vala.MemberBinding.INSTANCE && binding != Vala.MemberBinding.CLASS && !(m is Vala.CreationMethod) ||
				binding == Vala.MemberBinding.CLASS && (m.binding == Vala.MemberBinding.STATIC || m is Vala.CreationMethod))
					if ((match && name == m.name) || m.name.has_prefix (name))
						list.add (m);
			}
			foreach (var p in klass.get_properties())
				if (p.binding == Vala.MemberBinding.INSTANCE && binding != Vala.MemberBinding.CLASS ||
				binding == Vala.MemberBinding.CLASS && p.binding == Vala.MemberBinding.STATIC)
					if ((match && name == p.name) || p.name.has_prefix (name))
						list.add (p);
			foreach (var s in klass.get_signals())
				if (binding != Vala.MemberBinding.CLASS)
					if ((match && name == s.name) || s.name.has_prefix (name))
						list.add (s);
			if (binding == Vala.MemberBinding.INSTANCE) {
				foreach (var dt in klass.get_base_types())
					foreach (var sym in gsfm (dt.data_type, name, match, binding))
						list.add (sym);
			}
			return list;
		}
		
		Gee.List<Vala.Symbol> get_symbols_for_struct (Vala.Struct st, string name, bool match, Vala.MemberBinding binding) {
			var list = new Gee.ArrayList<Vala.Symbol>();
			if (binding == Vala.MemberBinding.CLASS)
				foreach (var c in st.get_constants())
					if ((match && name == c.name) || c.name.has_prefix (name))
						list.add (c);
			foreach (var f in st.get_fields()) {
				if (f.binding == Vala.MemberBinding.INSTANCE && binding != Vala.MemberBinding.CLASS ||
				binding == Vala.MemberBinding.CLASS && f.binding == Vala.MemberBinding.STATIC)
					if ((match && name == f.name) || f.name.has_prefix (name))
						list.add (f);
			}
			foreach (var m in st.get_methods()) {
				if (m.binding == Vala.MemberBinding.INSTANCE && binding != Vala.MemberBinding.CLASS && !(m is Vala.CreationMethod) ||
				binding == Vala.MemberBinding.CLASS && (m.binding == Vala.MemberBinding.STATIC || m is Vala.CreationMethod))
					if ((match && name == m.name) || m.name.has_prefix (name))
						list.add (m);
			}
			foreach (var p in st.get_properties()) {
				if (p.binding == Vala.MemberBinding.INSTANCE && binding != Vala.MemberBinding.CLASS ||
				binding == Vala.MemberBinding.CLASS && p.binding == Vala.MemberBinding.STATIC)
					if ((match && name == p.name) || p.name.has_prefix (name))
						list.add (p);
			}
			return list;
		}
		
		public signal void end_parsing (Report report);
		public signal void begin_parsing();
		
		public Vala.Namespace get_root() {
			return context.root;
		}
		
		public bool parsing { get; private set; }
		/*
		public void parse() {
			if (parsing)
				return;
			begin_parsing();
			try {
				Thread.create<void>(() => {
					lock (context) {
						parsing = true;
						report.init();
						Vala.CodeContext.push (context);
						foreach (var file in context.get_source_files())
							if (file.get_nodes().size == 0)
								parser.visit_source_file (file);
						context.check();
						parsing = false;
						Vala.CodeContext.pop();
						end_parsing (report);
					}
				}, false);
			} catch {
			
			}
		}
		*/
		
		public void parse() {
			lock (context) {
				begin_parsing();
				report.init();
				parsing = true;
				Vala.CodeContext.push (context);
				foreach (var file in context.get_source_files())
					if (file.get_nodes().size == 0)
						parser.visit_source_file (file);
				context.check();
				Vala.CodeContext.pop();
				end_parsing (report);
				parsing = false;
			}
		}
	}
}
