namespace Editor {
	public class Document : SourceFileView {
		public Document (string path) {
			base (path);
		}
		
		Gee.ArrayList<Report.Error?> errors_list;
		string tooltip_icon_name;
		string tooltip_message;
		Gtk.TextTag warning_tag;
		Gtk.TextTag error_tag;
		string old_content;
		
		construct {
			view.auto_indent = true;
			int cc_line, cc_column;
			view.paste_clipboard.connect (() => {
				Gtk.TextIter tmp;
				view.buffer.get_iter_at_mark (out tmp, view.buffer.get_insert());
				cc_line = tmp.get_line();
				cc_column = tmp.get_line_offset();
			});
			view.buffer.paste_done.connect (clipboard => {
				Gtk.TextIter cc_end;
				view.buffer.get_iter_at_mark (out cc_end, view.buffer.get_insert());
				Gtk.TextIter cc_start;
				view.buffer.get_iter_at_line_offset (out cc_start, cc_line, cc_column);
				buffer.remove_tag_by_name ("warning-tag", cc_start, cc_end);
				buffer.remove_tag_by_name ("error-tag", cc_start, cc_end);
			});
			old_content = view.buffer.text;
			save.connect (() => {
				old_content = view.buffer.text;
			});
			view.has_tooltip = false;
			view.show_line_numbers = true;
			view.background_pattern = Gtk.SourceBackgroundPatternType.GRID;
			
			errors_list = new Gee.ArrayList<Report.Error?>();
			view.query_tooltip.connect ((x, y, keyboard_tooltip, tooltip) => {
				tooltip.set_icon_from_icon_name (tooltip_icon_name, Gtk.IconSize.LARGE_TOOLBAR); 
				tooltip.set_markup ("<b>%s</b>".printf (tooltip_message));
				return true;
			});
			
			line_changed.connect (() => {
				//save();
			});
			
			view.key_press_event.connect (event => {
				editing (old_content != view.buffer.text);

				view.has_tooltip = false;
				return false;
			});
			
			view.button_press_event.connect (evt => {
				
				view.has_tooltip = false;
				return false;
			});
			
			provider = new Provider (this);
			add_completion_provider (provider);
			
			Gdk.RGBA ecolor = Gdk.RGBA();
			ecolor.parse ("red");
			
			Gdk.RGBA wcolor = Gdk.RGBA();
			wcolor.parse ("orange");
			
			warning_tag = buffer.create_tag ("warning-tag", "underline", Pango.Underline.ERROR, "underline-rgba", wcolor, "underline-rgba-set", true);
			warning_tag.event.connect ((object, event, iter) => {
				view.has_tooltip = false;
				errors_list.foreach (err => {
					if (iter_inside_reference (iter, err.source)) {
						view.has_tooltip = true;
						tooltip_icon_name = "dialog-warning";
						tooltip_message = err.message;
						return false;
					}
					return true;
				});
				return false;
			});
			
			error_tag = buffer.create_tag ("error-tag", "underline", Pango.Underline.ERROR, "underline-rgba", ecolor, "underline-rgba-set", true);
			error_tag.event.connect ((object, event, iter) => {
				has_tooltip = false;
				errors_list.foreach (err => {
					if (iter_inside_reference (iter, err.source)) {
						view.has_tooltip = true;
						tooltip_icon_name = "dialog-error";
						tooltip_message = err.message;
						return false;
					}
					return true;
				});
				return false;
			});
		}
		
		bool iter_inside_reference (Gtk.TextIter iter, Vala.SourceReference reference) {
			int line = iter.get_line() + 1;
			int column = iter.get_line_offset() + 1;
			var loc = new BlockLocator.Location (line, column);
			return loc.inside (reference);
		} 
		
		Gtk.TextIter location_to_iter (Vala.SourceLocation location, bool end = false) {
			Gtk.TextIter iter;
			buffer.get_iter_at_line_offset (out iter, location.line - 1, location.column - (end ? 0 : 1));
			return iter;
		}
		
		public void go_to (Vala.SourceLocation location) {
			view.place_cursor_onscreen();
			view.buffer.place_cursor (location_to_iter (location));
		}
		
		public void clear_tags() {
			errors_list = new Gee.ArrayList<Report.Error?>();
			Gtk.TextIter start, end;
			buffer.get_start_iter (out start);
			buffer.get_end_iter (out end);
			buffer.remove_tag_by_name ("warning-tag", start, end);
			buffer.remove_tag_by_name ("error-tag", start, end);
		}
		
		public void apply_error (Report.Error err) {
			if (!err.error)
				return;
			errors_list.add (err);
			Gtk.TextIter begin = location_to_iter (err.source.begin);
			Gtk.TextIter end = location_to_iter (err.source.end, true);
			buffer.apply_tag (error_tag, begin, end);
		}
		
		public void apply_warning (Report.Error err) {
			if (err.error)
				return;
			errors_list.add (err);
			Gtk.TextIter begin = location_to_iter (err.source.begin);
			Gtk.TextIter end = location_to_iter (err.source.end, true);
			buffer.apply_tag (warning_tag, begin, end);
		}

		public signal void editing (bool edit);
		
		public DocumentManager manager { get; internal set; }
		public Provider provider { get; private set; }
		
		public Vala.Symbol current_context {
			owned get {
				return manager.engine.lookup_symbol_at (location, current_line + 1, current_column);
			}
		}
		
		public string title {
			owned get {
				var parts = location.split ("/");
				return parts[parts.length - 1];
			}
		}
		
		public Gee.Collection<Vala.Symbol?> visible_symbols {
			owned get {
				return manager.engine.lookup_visible_symbols_at (location, current_line + 1, current_column);
			}
		}
	}
}
