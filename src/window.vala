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
	    this.notebook.switch_page.connect ( (nb, num) => update_title (num));
	}

	public void new_page () {
	    var tab = new Vapad.Tab ();
	    this.notebook.append_page(tab, tab.lbox);
	    tab.close_button.clicked.connect ( () => {
	        this.notebook.remove_page (this.notebook.page_num (tab));
	    });
	    this.notebook.set_current_page (this.notebook.page_num (tab));
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
		    var file = chooser.get_file ();
		    if (file != null) {
		        var n = this.notebook.get_current_page ();
			var page = this.notebook.get_nth_page (n);
			var tab = (Vapad.Tab)page;
			if (tab.file != null) {
		            tab = new Vapad.Tab ();
			    this.notebook.append_page(tab, tab.lbox);
			    tab.close_button.clicked.connect ( () => {
			        this.notebook.remove_page (this.notebook.page_num (tab));
			    });
			}
			tab.load_file (file);
			n = this.notebook.page_num (tab);
			this.notebook.set_current_page (n);
			this.update_title (n);
		    }
		}
		dlg.close ();
	    });
	    chooser.show ();
	}

	private void update_title (uint num) {
	    var tab = (Vapad.Tab)this.notebook.get_nth_page ((int)num);
	    if (tab.file != null) {
		this.set_title (tab.file.get_path ());
	    } else {
		this.set_title ("New file");
	    }
	}

	private void save_file () {
	}
    }
}
