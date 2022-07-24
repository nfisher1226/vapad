/* window.vala
 *
 * Copyright 2022 Nathan Fisher
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Vapad {
    [GtkTemplate (ui = "/org/hitchhiker_linux/vapad/window.ui")]
    public class Window : Gtk.ApplicationWindow {
        [GtkChild]
        private unowned Gtk.Notebook notebook;

        public Window (Gtk.Application app) {
            Object (application: app);
        }

	construct {
	    ActionEntry[] actions = {
	        { "new_file", this.new_page },
	        { "close_file", this.close_page },
		{ "open_file", this.open_file },
		{ "save_file", this.save_file },
	    };
	    this.add_action_entries (actions, this);
	    this.notebook.page_removed.connect ( () => {
	        if (this.notebook.get_n_pages () == 0) {
	            this.close ();
	        }
	    });
	}

	public void new_page () {
	    var tab = new Vapad.Tab ();
	    this.notebook.append_page(tab, tab.lbox);
	    tab.close_button.clicked.connect ( () => {
	        this.notebook.remove_page (this.notebook.page_num (tab));
	    });
	}

	private void close_page () {
	    var num = this.notebook.get_current_page ();
	    this.notebook.remove_page (num);
	}

	private void open_file () {
	    var chooser = new Gtk.FileChooserDialog (
                "Select a file to open",
		this,
		Gtk.FileChooserAction.OPEN
            );
	    chooser.add_button ("Accept", Gtk.ResponseType.ACCEPT);
	    chooser.add_button ("Cancel", Gtk.ResponseType.CANCEL);
	    chooser.response.connect ( (dlg, res) => {
                if (res == Gtk.ResponseType.ACCEPT) {
                    //stdout.printf ("Accepted");
		    var file = chooser.get_file ();
		    if (file != null) {
                        try {
			    uint8[] contents;
			    string etag_out;
			    var info = file.query_info ("standard::*", 0);
			    var size = info.get_size ();
			    file.load_contents (null, out contents, out etag_out);
			    var n = this.notebook.get_current_page ();
			    var page = this.notebook.get_nth_page (n);
			    var tab = (Vapad.Tab)page;
			    var buffer = tab.sourceview.get_buffer ();
			    buffer.set_text ((string)contents, (int)size);
                        } catch (Error e) {
			    print ("Error: %s\n", e.message);
			}
		    }
		}
		dlg.close ();
	    });
	    chooser.show ();
	}

	private void save_file () {
	}
    }
}
