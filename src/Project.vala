namespace Editor {
	public class StringList : Gee.ArrayList<string> {
		public StringList() {
			base();
		}
		
		public virtual signal void add (string str) {
			base.add (str);
		}
		
		public virtual signal bool remove (string str) {
			return base.remove (str);
		}
	}
	
	public class Project : GLib.Object {
		public string name { get; construct; }
		public string location { get; construct; }

		public StringList packages { get; private set; }
		public StringList sources { get; private set; }
		public Gee.HashMap<string, string> flags { get; private set; }
		
		public Project (string name, string location) {
			GLib.Object (name: name, location: location);
		}

		construct {
			packages = new StringList();
			sources = new StringList();
			flags = new Gee.HashMap<string, string>();
		}
		
		public virtual signal bool save() {
			var object = new Json.Object();
			object.set_string_member ("name", name);
			var pkg_array = new Json.Array();
			packages.foreach (package => {
				pkg_array.add_string_element (package);
				return true;
			});
			var src_array = new Json.Array();
			sources.foreach (source => {
				src_array.add_string_element (source);
				return true;
			});
			object.set_array_member ("sources", src_array);
			object.set_array_member ("packages", pkg_array);
			var node = new Json.Node.alloc();
			node.init_object (object);
			var gen = new Json.Generator();
			gen.set_root (node);
			gen.pretty = true;
			gen.indent_char = '\t';
			try {
				gen.to_file (location);
				return true;
			}
			catch {
				return false;
			}
		}
		
		public signal void update();
		
		public static Project? load (string filename) {
			try {
				var parser = new Json.Parser();
				parser.load_from_file (filename);
				var basepath = File.new_for_path(filename).get_parent().get_path();
				if (parser.get_root().get_node_type() != Json.NodeType.OBJECT)
					return null;
				var object = parser.get_root().get_object();
				
				if (!object.has_member ("name") || object.get_member("name").get_value_type() != typeof (string))
					return null;
				if (!object.has_member ("sources") || object.get_member("sources").get_node_type() != Json.NodeType.ARRAY)
					return null;
				if (!object.has_member ("packages") || object.get_member("packages").get_node_type() != Json.NodeType.ARRAY)
					return null;
				var project = new Project (object.get_string_member ("name"), filename);
				
				object.get_array_member("packages").foreach_element ((array, index, node) => {
					if (project == null)
						return;					
					if (node.get_value_type() != typeof (string))
						project = null;
					else
						project.packages.add (node.get_string());
				});
				object.get_array_member("sources").foreach_element ((array, index, node) => {
					if (project == null)
						return;	
					if (node.get_value_type() != typeof (string)) {
						project = null;
						return;
					}
					string path = node.get_string();
					if (path[0] != '/')
						path = basepath + "/" + node.get_string();
					var file = File.new_for_path (path);
					if (!file.query_exists()) {
						project = null;
						return;
					}
					project.sources.add (node.get_string());
				});
				return project;
			} catch {
				return null;
			}
		}
	}
}
