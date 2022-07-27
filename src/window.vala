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
        [GtkChild]
        private unowned Gtk.Box search_box;
        [GtkChild]
        private unowned Gtk.SearchEntry search_entry;
        [GtkChild]
        private unowned Gtk.CheckButton match_case;
        [GtkChild]
        private unowned Gtk.CheckButton whole_words;
        public GtkSource.SearchContext? search_context;

        public Window (Gtk.Application app) {
            Object (application: app);
        }

        construct {
            ActionEntry[] actions = {
                { "new_file", this.new_page },
                { "search", this.show_search },
                { "find_next", this.find_next },
                { "find_previous", this.find_previous },
                { "replace_text", this.replace_text },
                { "advanced_search", this.advanced_search },
                { "hide_search", this.hide_search },
                { "close_file", this.close_page },
                { "open_file", this.open_file },
                { "save_file", this.save_file },
                { "save_as", this.save_as },
                { "save_all", this.save_all },
                { "tab1", this.tab1 },
                { "tab2", this.tab2 },
                { "tab3", this.tab3 },
                { "tab4", this.tab4 },
                { "tab5", this.tab5 },
                { "tab6", this.tab6 },
                { "tab7", this.tab7 },
                { "tab8", this.tab8 },
                { "tab9", this.tab9 },
                { "last_tab", this.last_tab },
                { "next_tab", this.next_tab },
                { "previous_tab", this.previous_tab },
            };
            this.add_action_entries (actions, this);
            this.notebook.page_removed.connect (check_tab_visibility);
            this.notebook.page_added.connect (check_tab_visibility);
            this.notebook.switch_page.connect ( (nb, num) => update_title (num));
            this.search_entry.activate.connect (new_search);
        }

        public void new_page () {
            Tab tab = new Vapad.Tab ();
            this.notebook.append_page(tab, tab.lbox);
            tab.close_button.clicked.connect ( () => {
                this.notebook.remove_page (this.notebook.page_num (tab));
            });
            tab.file_saved.connect ( () => {
                this.update_title (this.notebook.get_current_page ());
            });
            this.notebook.set_current_page (this.notebook.page_num (tab));
        }

        private void close_page () {
            int num = this.notebook.get_current_page ();
            this.notebook.remove_page (num);
        }

        private void open_file () {
            Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
                "Select a file to open",
                this,
                Gtk.FileChooserAction.OPEN
            );
            var f = this.current_tab ().file;
            if (f != null) {
                try {
                    chooser.set_current_folder (f.get_parent ());
                } catch (Error e) {
                    print ("Error: %s\n", e.message);
                }
            }
            chooser.add_button ("Accept", Gtk.ResponseType.ACCEPT);
            chooser.add_button ("Cancel", Gtk.ResponseType.CANCEL);
            chooser.response.connect ( (dlg, res) => {
                if (res == Gtk.ResponseType.ACCEPT) {
                    File file = chooser.get_file ();
                    if (file != null) {
                        int n = this.notebook.get_current_page ();
                        var tab = (Vapad.Tab)this.notebook.get_nth_page (n);
                        if (tab.file != null) {
                            tab = new Vapad.Tab ();
                            this.notebook.append_page(tab, tab.lbox);
                            tab.close_button.clicked.connect ( () => {
                                this.notebook.remove_page (this.notebook.page_num (tab));
                            });
                            tab.file_saved.connect ( () => {
                                this.update_title (this.notebook.get_current_page ());
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

        private void check_tab_visibility () {
            switch (this.notebook.get_n_pages ()) {
                case 0:
                    this.close ();
                    break;
                case 1:
                    this.notebook.set_show_tabs (false);
                    break;
                default:
                    if (!this.notebook.get_show_tabs ()) {
                        this.notebook.set_show_tabs (true);
                    }
                    break;
            }
        }

        private void update_title (uint num) {
            var tab = (Vapad.Tab)this.notebook.get_nth_page ((int)num);
            if (tab.file != null) {
                string path = tab.file.get_path ();
                this.set_title (@"$path ~ $PROGNAME-$VERSION");
            } else {
                this.set_title (@"New file ~ $PROGNAME-$VERSION");
            }
        }

        public Vapad.Tab current_tab () {
            return (Vapad.Tab)this.notebook.get_nth_page (this.notebook.get_current_page ());
        }

        private GtkSource.Buffer current_buffer () {
            return (GtkSource.Buffer)this.current_tab ().sourceview.get_buffer ();
        }

        private void save_file () {
            this.current_tab ().save_file ();
            this.update_title (this.notebook.get_current_page ());
        }

        private void save_as () {
	    this.current_tab ().save_as ();
        }

        private void save_all () {
            for (int n = 0; n < this.notebook.get_n_pages (); n++) {
                Tab tab = (Vapad.Tab)this.notebook.get_nth_page (n);
                tab.save_file ();
            }
        }

        private void tab1 () {
            this.notebook.set_current_page (0);
        }

        private void tab2 () {
            this.notebook.set_current_page (1);
        }

        private void tab3 () {
            this.notebook.set_current_page (2);
        }

        private void tab4 () {
            this.notebook.set_current_page (3);
        }

        private void tab5 () {
            this.notebook.set_current_page (4);
        }

        private void tab6 () {
            this.notebook.set_current_page (5);
        }

        private void tab7 () {
            this.notebook.set_current_page (6);
        }

        private void tab8 () {
            this.notebook.set_current_page (7);
        }

        private void tab9 () {
            this.notebook.set_current_page (8);
        }

        private void last_tab () {
            int num = this.notebook.get_n_pages ();
            this.notebook.set_current_page (num - 1);
        }

        private void next_tab () {
            if (this.notebook.get_current_page () >= this.notebook.get_n_pages () - 1) {
                this.notebook.set_current_page (0);
            } else {
                this.notebook.next_page ();
            }
        }

        private void previous_tab () {
            if (this.notebook.get_current_page () == 0) {
                this.notebook.set_current_page (this.notebook.get_n_pages () - 1);
            } else {
                this.notebook.prev_page ();
            }
        }

        private void show_search () {
            this.search_box.show ();
            this.search_entry.grab_focus ();
            if (this.search_context != null) {
                this.search_context.set_highlight (true);
            }
        }

        private void new_search () {
            var settings = new GtkSource.SearchSettings ();
            settings.set_wrap_around (true);
            settings.set_case_sensitive (this.match_case.get_active ());
            settings.set_at_word_boundaries (this.whole_words.get_active ());
            settings.set_search_text (this.search_entry.get_text ());
            this.search_context = new GtkSource.SearchContext (this.current_buffer (), settings);
            this.find_next ();
        }

        private void hide_search () {
            this.search_box.hide ();
            if (this.search_context != null) {
                this.search_context.set_highlight (false);
            }
        }

        private void find_next () {
            if (this.search_context == null) {
                this.show_search ();
                return;
            }
            this.search_context.set_highlight (true);
            var view = this.current_tab ().sourceview;
            var buffer = this.current_buffer ();
            var position = GLib.Value (GLib.Type.INT);
            buffer.get_property ("cursor_position", ref position);
            Gtk.TextIter current;
            Gtk.TextIter start;
            Gtk.TextIter end;
            buffer.get_iter_at_offset (out current, (int)position);
            Gtk.TextIter sel_start;
            Gtk.TextIter sel_end;
            if (buffer.get_selection_bounds (out sel_start, out sel_end)) {
                current = sel_end;
            }
            bool has_wrapped;
            this.search_context.forward (current, out start, out end, out has_wrapped);
            buffer.place_cursor (start);
            buffer.select_range (start, end);
            view.scroll_to_iter (start, 0.25, false, 0.1, 0.1);
        }

        private void find_previous () {
            if (this.search_context == null) {
                this.show_search ();
                return;
            }
            this.search_context.set_highlight (true);
            var view = this.current_tab ().sourceview;
            var buffer = this.current_buffer ();
            var position = GLib.Value (GLib.Type.INT);
            buffer.get_property ("cursor_position", ref position);
            Gtk.TextIter current;
            Gtk.TextIter start;
            Gtk.TextIter end;
            buffer.get_iter_at_offset (out current, (int)position);
            Gtk.TextIter sel_start;
            Gtk.TextIter sel_end;
            if (buffer.get_selection_bounds (out sel_start, out sel_end)) {
                current = sel_start;
            }
            bool has_wrapped;
            this.search_context.backward (current, out start, out end, out has_wrapped);
            buffer.place_cursor (start);
            buffer.select_range (start, end);
            view.scroll_to_iter (start, 0.25, false, 0.1, 0.1);
        }

        private void advanced_search () {
            this.hide_search ();
        }

        private void replace_text () {
        }
    }
}
