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
    public class ThemeSwitcher : Gtk.Box {
        private Gtk.ToggleButton system_button;
        private Gtk.ToggleButton light_button;
        private Gtk.ToggleButton dark_button;
        public signal void use_system_theme ();
        public signal void use_light_theme ();
        public signal void use_dark_theme ();

        public ThemeSwitcher () {
            Object (
                orientation: Gtk.Orientation.HORIZONTAL,
                margin_top: 10,
                margin_bottom: 10,
                margin_start: 10,
                margin_end: 10
            );
        }

        construct {
            this.system_button = new Gtk.ToggleButton ();
            this.light_button = new Gtk.ToggleButton ();
            this.dark_button = new Gtk.ToggleButton ();
            Gtk.ToggleButton[] buttons = {this.system_button, this.light_button, this.dark_button};
            foreach (Gtk.ToggleButton button in buttons) {
                button.set_hexpand (true);
                button.set_halign (Gtk.Align.CENTER);
                this.append (button);
            }
            this.system_button.set_tooltip_text ("Follow system style");
            this.light_button.set_tooltip_text ("Light style");
            this.dark_button.set_tooltip_text ("Dark style");
            this.light_button.set_group (this.system_button);
            this.dark_button.set_group (this.system_button);
            this.system_button.set_active (true);
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
