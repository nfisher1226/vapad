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
        [Gtkchild]
        private unowned Gtk.SearchEntry search_entry;
        [Gtkchild]
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

        public SearchDialog (Gtk.Window window) {
            Object (use_header_bar: 1, transient_for: window);
        }

        construct {
            this.response.connect ( () => this.close ());
            var action_group = new GLib.SimpleActionGroup ();
            ActionEntry[] actions = {
                { "find", this.find },
                { "replace", this.replace },
                { "replace_find", this.replace_find },
            };
            action_group.add_action_entries (actions, null);
            this.insert_action_group ("advanced_search", action_group);
        }

        private GtkSource.SearchSettings get_search_settings () {
            var settings = new GtkSource.SearchSettings ();
            settings.set_regex_enabled (this.use_regex.get_active ());
            settings.set_case_sensitive (this.case_sensitive.get_active ());
            settings.set_at_word_boundaries (this.whole_words.get_active ());
            settings.set_wrap_around (this.wrap.get_active ());
            settings.set_search_text (this.search_entry.get_text ());
            return settings;
        }

        private void find () {
        }

        private void replace () {
        }

        private void replace_find () {
        }
    }
}
