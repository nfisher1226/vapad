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
    [GtkTemplate (ui = "/org/hitchhiker_linux/vapad/theme_switcher.ui")]
    public class ThemeSwitcher : Gtk.Widget {
        [GtkChild]
        private unowned Gtk.CheckButton system_button;
        [GtkChild]
        private unowned Gtk.CheckButton light_button;
        [GtkChild]
        private unowned Gtk.CheckButton dark_button;
        public signal void use_system_theme ();
        public signal void use_light_theme ();
        public signal void use_dark_theme ();

        public ThemeSwitcher () {
            Object ();
        }

        construct {
            this.set_layout_manager (new Gtk.BinLayout ());
            this.system_button.toggled.connect (emit);
            this.light_button.toggled.connect (emit);
            this.dark_button.toggled.connect (emit);
        }

        private void emit () {
            if (this.system_button.get_active ()) {
                this.use_dark_theme ();
            } else if (this.light_button.get_active ()) {
                this.use_light_theme ();
            } else {
                this.use_dark_theme ();
            }
        }
    }
}
