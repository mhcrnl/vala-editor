namespace Editor {
	public class Report : Vala.Report {
		public struct Error {
			public Vala.SourceReference source;
			public bool error;
			public string message;
		}
		
		Vala.ArrayList<Error?> errors_list;
		
		public Report() {
			errors_list = new Vala.ArrayList<Error?>();
		}
		
		public void clear (Vala.SourceFile file) {
			for (var i = 0; i < errors_list.size; i++) {
				if (errors_list[i].source.file == file) {
					if (errors_list[i].error)
						errors --;
					else
						warnings --;

					errors_list.remove_at (i);
					i --;
				}
			}
		}
		
		public Error? get (int index) {
			return errors_list[index];
		}
		
		public int size {
			get {
				return errors_list.size;
			}
		}
		
		public override void depr (Vala.SourceReference? source, string message) {
			warnings ++;
			if (source == null)
				return;
			lock (errors_list) {
				errors_list.add (Error(){ source = source, message = message, error = false });
			}
		}
		
		public override void warn (Vala.SourceReference? source, string message) {
			warnings ++;
			if (source == null)
				return;
			lock (errors_list) {
				errors_list.add (Error(){ source = source, message = message, error = false });
			}
		}
		
		public override void err (Vala.SourceReference? source, string message) {
			errors ++;
			if (source == null)
				return;
			lock (errors_list) {
				errors_list.add (Error(){ source = source, message = message, error = true });
			}
		}
	}
}
