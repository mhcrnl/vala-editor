namespace Editor {
	public abstract class Build : GLib.Object {
		public Project project { get; set; }
		public string directory { get; set; }
		
		public abstract bool configure();
		public abstract bool make();
		
		public static Build create (string id) {
			return new SimpleBuild();
		}
	}
	
	public class SimpleBuild : Build {
		public override bool configure() {
			if (project == null)
				return false;
			return FileUtils.test (directory, FileTest.IS_DIR);
		}
		
		public override bool make() {
			if (!configure())
				return false;
			string cmd_line = "valac ";
			foreach (string source in project.sources)
				cmd_line += source + " ";
			cmd_line += "-o " + directory + "/" + project.name;
			foreach (string pkg in project.packages)
				cmd_line += "--pkg " + pkg;
			string output, err;
			Process.spawn_command_line_sync (cmd_line, out output, out err);
			return err.strip().length == 0;
		}
	}
}
