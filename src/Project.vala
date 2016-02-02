namespace Editor {
	public class Project : GLib.Object {
		public string name { get; construct; }
		public Gee.ArrayList<string> packages { get; private set; }
		public Gee.ArrayList<string> sources { get; private set; }
		public Gee.HashMap<string, string> flags { get; private set; }
		
		public Project (string name) {
			GLib.Object (name: name);
		}

		construct {
			packages = new Gee.ArrayList<string>();
			sources = new Gee.ArrayList<string>();
			flags = new Gee.HashMap<string, string>();
		}
		
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
				var project = new Project (object.get_string_member ("name"));
				
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
					string rpath = node.get_string();
					if (rpath[0] != '/')
						rpath = basepath + "/" + rpath;
					if (node.get_value_type() != typeof (string) || !FileUtils.test (rpath, FileTest.EXISTS))
						project = null;
					else
						project.sources.add (rpath);
				});
				return project;
			} catch {
				return null;
			}
		}
	}
}
