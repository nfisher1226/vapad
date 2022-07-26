/* application.vala
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
    public class Application : Gtk.Application {
        public Application () {
            Object (application_id: "org.hitchhiker_linux.vapad", flags: ApplicationFlags.FLAGS_NONE);
        }

        construct {
            ActionEntry[] action_entries = {
                { "about", this.on_about_action },
                { "preferences", this.on_preferences_action },
                { "quit", this.quit }
            };
            this.add_action_entries (action_entries, this);
            this.set_accels_for_action ("app.quit", {"<primary>q"});
            this.set_accels_for_action ("win.search", {"<primary>f"});
            this.set_accels_for_action ("win.hide_search", {"Escape"});
            this.set_accels_for_action ("win.new_file", {"<primary>n"});
            this.set_accels_for_action ("win.close_file", {"<primary>w"});
            this.set_accels_for_action ("win.open_file", {"<primary>o"});
            this.set_accels_for_action ("win.save_file", {"<primary>s"});
            this.set_accels_for_action ("win.save_as", {"<primary><shift>s"});
            this.set_accels_for_action ("win.save_all", {"<primary><shift>l"});
            this.set_accels_for_action ("win.tab1", {"<alt>1"});
            this.set_accels_for_action ("win.tab2", {"<alt>2"});
            this.set_accels_for_action ("win.tab3", {"<alt>3"});
            this.set_accels_for_action ("win.tab4", {"<alt>4"});
            this.set_accels_for_action ("win.tab5", {"<alt>5"});
            this.set_accels_for_action ("win.tab6", {"<alt>6"});
            this.set_accels_for_action ("win.tab7", {"<alt>7"});
            this.set_accels_for_action ("win.tab8", {"<alt>8"});
            this.set_accels_for_action ("win.tab9", {"<alt>9"});
            this.set_accels_for_action ("win.last_tab", {"<alt>0"});
            this.set_accels_for_action ("win.next_tab", {"<alt>Right"});
            this.set_accels_for_action ("win.previous_tab", {"<alt>Left"});
        }

        public override void activate () {
            base.activate ();
            var win = this.active_window;
            if (win == null) {
                win = new Vapad.Window (this);
                Vapad.Window w = (Vapad.Window)win;
                w.new_page ();
            }
            win.present ();
        }

        private void on_about_action () {
            string[] authors = { "Nathan Fisher" };
            Gtk.show_about_dialog (this.active_window,
                                   "program-name", "vapad",
                                   "authors", authors,
                                   "version", "0.1.0");
        }

        private void on_preferences_action () {
            message ("app.preferences action activated");
        }
    }
}
