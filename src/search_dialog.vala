/* search_dialog.vala
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
    [GtkTemplate (ui = "/org/hitchhiker_linux/vapad/search_dialog.ui")]
    public class SearchDialog : Gtk.Dialog {
        [GtkChild]
        private unowned Gtk.Entry search_entry;
        [GtkChild]
        private unowned Gtk.Entry replace_entry;
        [GtkChild]
        private unowned Gtk.CheckButton use_regex;
        [GtkChild]
        private unowned Gtk.CheckButton case_sensitive;
        [GtkChild]
        private unowned Gtk.CheckButton whole_words;
        [GtkChild]
        private unowned Gtk.CheckButton wrap;
        [GtkChild]
        private unowned Gtk.CheckButton backwards;
        [GtkChild]
        private unowned Gtk.CheckButton close_when_finished;
        [GtkChild]
        private unowned Gtk.Button replace_in_session_button;
        [GtkChild]
        private unowned Gtk.Button replace_in_document_button;
        [GtkChild]
        private unowned Gtk.Button replace_in_selection_button;
        [GtkChild]
        private unowned Gtk.Button find_button;
        [GtkChild]
        private unowned Gtk.Button replace_button;
        [GtkChild]
        private unowned Gtk.Button replace_find_button;
        public signal void strings_replaced (uint num);

        public SearchDialog (Gtk.Window window) {
            Object (use_header_bar: 1, transient_for: window);
        }

        construct {
            this.response.connect ( () => this.close ());
            this.search_entry.activate.connect (find);
            this.find_button.clicked.connect (find);
            this.replace_button.clicked.connect (replace);
            this.replace_find_button.clicked.connect (replace_find);
            this.replace_in_session_button.clicked.connect (replace_in_session);
            this.replace_in_document_button.clicked.connect (replace_in_document);
            this.replace_in_selection_button.clicked.connect (replace_in_selection);
            var win = (Vapad.Window)this.get_transient_for ();
            this.search_entry.set_completion (win.search_completion);
        }

        private GtkSource.SearchSettings get_search_settings () {
            var settings = new GtkSource.SearchSettings () {
                regex_enabled = this.use_regex.get_active (),
                case_sensitive = this.case_sensitive.get_active (),
                at_word_boundaries = this.whole_words.get_active (),
                wrap_around = this.wrap.get_active (),
                search_text = this.search_entry.get_text (),
            };
            return settings;
        }

        private GtkSource.SearchContext get_search_context (Vapad.Tab tab) {
            var settings = this.get_search_settings ();
            var buffer = (GtkSource.Buffer)tab.sourceview.get_buffer ();
            var search_context = new GtkSource.SearchContext (buffer,  settings) {
                highlight = true,
            };
            return search_context;
        }

        private void find () {
            var win = (Vapad.Window)this.get_transient_for ();
            var tab = (Vapad.Tab)win.current_tab ();
            var view = tab.sourceview;
            var buffer = (GtkSource.Buffer)view.get_buffer ();
            var search_context = this.get_search_context (tab);
            var position = GLib.Value (GLib.Type.INT);
            buffer.get_property ("cursor_position", ref position);
            Gtk.TextIter current;
            Gtk.TextIter start;
            Gtk.TextIter end;
            buffer.get_iter_at_offset (out current, (int)position);
            Gtk.TextIter sel_start;
            Gtk.TextIter sel_end;
            bool has_wrapped;
            bool has_match;
            if (this.backwards.get_active ()) {
                if (buffer.get_selection_bounds (out sel_start, out sel_end)) {
                    current = sel_start;
                }
                has_match = search_context.backward (current, out start, out end, out has_wrapped);
            } else {
                if (buffer.get_selection_bounds (out sel_start, out sel_end)) {
                    current = sel_end;
                }
                has_match = search_context.forward (current, out start, out end, out has_wrapped);
            }
            if (has_match) {
                buffer.place_cursor (start);
                buffer.select_range (start, end);
                view.scroll_to_iter (start, 0.25, false, 0.1, 0.1);
            }
        }

        private void replace () {
            var win = (Vapad.Window)this.get_transient_for ();
            var tab = (Vapad.Tab)win.current_tab ();
            var search_context = this.get_search_context (tab);
            var view = (GtkSource.View)tab.sourceview;
            var buffer = (GtkSource.Buffer)view.get_buffer ();
            if (!buffer.get_has_selection ()) {
                return;
            }
            var search_text = this.search_entry.get_text ();
            var replace_text = this.replace_entry.get_text ();
            if (search_text == "") {
                return;
            }
            Gtk.TextIter start;
            Gtk.TextIter end;
            buffer.get_selection_bounds (out start, out end);
            var selected_text = buffer.get_slice (start, end, true);
            if (search_text == selected_text) {
                try {
                    search_context.replace (start, end, replace_text, -1);
                } catch (Error e) {
                    print ("%s\n", e.message);
                }
            }
        }

        private void replace_find () {
            this.replace ();
            this.find ();
        }

        private uint? replace_in_document_common (Vapad.Tab tab) {
            var search_context = this.get_search_context (tab);
            var replace_text = this.replace_entry.get_text ();
            try {
                return search_context.replace_all (replace_text, -1);
            } catch (Error e) {
                print ("%s\n", e.message);
                return null;
            }
        }

        private void replace_in_session () {
            var win = (Vapad.Window)this.get_transient_for ();
            uint cases = 0;
            for (int n = 0; n < win.n_tabs (); n++) {
                var tab = (Vapad.Tab)win.nth_tab (n);
                var num = this.replace_in_document_common (tab);
                if (num != null) {
                    cases += num;
                }
            }
            this.strings_replaced (cases);
            if (this.close_when_finished.get_active ()) {
                this.close ();
            }
        }

        private void replace_in_document () {
            var win = (Vapad.Window)this.get_transient_for ();
            var tab = (Vapad.Tab)win.current_tab ();
            var cases = this.replace_in_document_common (tab);
            if (cases != null) {
                this.strings_replaced (cases);
            }
            if (this.close_when_finished.get_active ()) {
                this.close ();
            }
        }

        private void replace_in_selection () {
            var win = (Vapad.Window)this.get_transient_for ();
            var tab = (Vapad.Tab)win.current_tab ();
            var buffer = (GtkSource.Buffer)tab.sourceview.get_buffer ();
            if (!buffer.get_has_selection ()) {
                return;
            }
            var search_context = this.get_search_context (tab);
            bool has_wrapped;
            Gtk.TextIter current, selection_end;
            buffer.get_selection_bounds (out current, out selection_end);
            var current_mark = buffer.create_mark ("current_mark", current, true);
            var end_mark = buffer.create_mark ("selection_mark", selection_end, true);
            while (true) {
                Gtk.TextIter start, end, current_iter, sel_end;
                buffer.get_iter_at_mark (out current_iter, current_mark);
                buffer.get_iter_at_mark (out sel_end, end_mark);
                if (!search_context.forward (current_iter, out start, out end, out has_wrapped)) {
                    break;
                }
                buffer.move_mark (current_mark, end);
                if (end.compare (sel_end) <= 0) {
                    string replace = this.replace_entry.get_text ();
                    try {
                        search_context.replace (start, end, replace, -1);
                    } catch (Error e) {
                        string error = _("Error");
                        print ("%s: %s\n", error, e.message);
                    }
                } else {
                    break;
                }
            }
            buffer.delete_mark (current_mark);
            buffer.delete_mark (end_mark);
            if (this.close_when_finished.get_active ()) {
                this.close ();
            }
        }
    }
}
