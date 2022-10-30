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
    public const string PROGNAME = "Vapad";
    public const string VERSION = "0.6.0";
    public const string[] AUTHORS = { "Nathan Fisher", "Alex Kryuchkov" };

    public class Application : Adw.Application {
        public Adw.ColorScheme theme { get; set; }

        public Application () {
            Object (
                application_id: "org.hitchhiker_linux.vapad",
                flags: ApplicationFlags.HANDLES_OPEN,
                register_session: true
            );

            Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
            Intl.textdomain (Config.GETTEXT_PACKAGE);
        }

        construct {
            ActionEntry[] action_entries = {
                { "about", this.on_about_action },
                { "quit", this.on_quit }
            };
            this.add_action_entries (action_entries, this);
            this.set_accels_for_action ("app.quit", { "<primary>q" });
            this.set_accels_for_action ("win.search", { "<primary>f" });
            this.set_accels_for_action ("win.find_next", { "<primary>g" });
            this.set_accels_for_action ("win.replace_text", { "<primary>h" });
            this.set_accels_for_action ("win.find_previous", { "<primary><shift>g" });
            this.set_accels_for_action ("win.hide_search", { "<shift>Escape" });
            this.set_accels_for_action ("win.new_file", { "<primary>n" });
            this.set_accels_for_action ("win.close_file", { "<primary>w" });
            this.set_accels_for_action ("win.open_file", { "<primary>o" });
            this.set_accels_for_action ("win.save_file", { "<primary>s" });
            this.set_accels_for_action ("win.save_as", { "<primary><shift>s" });
            this.set_accels_for_action ("win.save_all", { "<primary><shift>l" });
            this.set_accels_for_action ("win.tab1", { "<alt>1" });
            this.set_accels_for_action ("win.tab2", { "<alt>2" });
            this.set_accels_for_action ("win.tab3", { "<alt>3" });
            this.set_accels_for_action ("win.tab4", { "<alt>4" });
            this.set_accels_for_action ("win.tab5", { "<alt>5" });
            this.set_accels_for_action ("win.tab6", { "<alt>6" });
            this.set_accels_for_action ("win.tab7", { "<alt>7" });
            this.set_accels_for_action ("win.tab8", { "<alt>8" });
            this.set_accels_for_action ("win.tab9", { "<alt>9" });
            this.set_accels_for_action ("win.last_tab", { "<alt>0" });
            this.set_accels_for_action ("win.next_tab", { "<alt>Right" });
            this.set_accels_for_action ("win.previous_tab", { "<alt>Left" });

            var set_theme_action = new GLib.PropertyAction ("set_app_theme", this, "theme");
            set_theme_action.notify.connect (this.set_app_theme);
            this.add_action (set_theme_action);
            this.open.connect (open_files);
        }

        public override void activate () {
            base.activate ();
            var win = this.active_window;
            if (win == null) {
                win = this.create_window ();
                win.present ();
                this.set_app_theme ();
            }
            ((Vapad.Window) win).new_page ();
        }

        private void open_files (File[] files) {
            var win = (Vapad.Window) this.active_window;
            if (win == null) {
                var w = this.create_window ();
                win = (Vapad.Window) w;
                win.present ();
            }
            foreach (File file in files) {
                if (win.current_tab () == null) {
                    win.new_page ();
                }
                win.current_tab ().load_file (file);
                win.update_title (win.notebook.page_num (win.current_tab ()));
            }
        }

        private Vapad.Window create_window () {
            var win = new Vapad.Window (this);

            // Css settings
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/org/hitchhiker_linux/vapad/style.css");
            Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);

            // GLib settings
            var settings = new GLib.Settings ("org.hitchhiker_linux.vapad");
            settings.bind ("vimode", win, "vimode", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("grid", win, "display_grid", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("syntax", win, "editor_theme", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("font", win, "editor_font", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("theme", this, "theme", GLib.SettingsBindFlags.DEFAULT);
            return win;
        }

        private void on_about_action () {
            var win = new Adw.AboutWindow () {
                application_name = PROGNAME,
                developer_name = "Nathan Fisher",
                developers = AUTHORS,
                version = VERSION,
                application_icon = "org.hitchhiker_linux.vapad",
                comments = _ ("A simple text editor for Linux"),
                license_type = Gtk.License.GPL_3_0,
                copyright = _ ("Copyright © 2022 by Nathan Fisher"),
                translator_credits = _ ("translator-credits"),
                website = "https://codeberg.org/jeang3nie/vapad",
                issue_url = "https://codeberg.org/jeang3nie/vapad/issues"
            };
            win.show ();
        }

        private void set_app_theme () {
            Adw.StyleManager.get_default ().set_color_scheme (this.theme);
        }

        private void on_quit () {
            this.get_windows ().foreach ((obj) => {
                var win = (Vapad.Window) obj;
                win.close_all ();
            });
        }
    }
}
