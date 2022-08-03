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
    public class Window : Adw.ApplicationWindow {
        [GtkChild]
        private unowned Gtk.MenuButton menu_button;
        [GtkChild]
        private unowned Gtk.Notebook notebook;
        [GtkChild]
        private unowned Gtk.Box search_box;
        [GtkChild]
        private unowned Gtk.Entry search_entry;
        [GtkChild]
        private unowned Gtk.CheckButton match_case;
        [GtkChild]
        private unowned Gtk.CheckButton whole_words;
        [GtkChild]
        private unowned Adw.ToastOverlay overlay;
        private Vapad.ThemeSwitcher theme_switcher;
        public GtkSource.SearchContext? search_context;
        public Gtk.EntryCompletion search_completion;
        public bool vimode { get; set; }
        public string editor_theme { get; set; }
        public string? editor_font { get; set; }

        public Window (Adw.Application app) {
            Object (application: app);
        }

        construct {
            ActionEntry[] actions = {
                { "new_file", this.new_page },
                { "search", this.show_search },
                { "advanced_search", this.advanced_search },
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
                { "set_font", this.set_font },
            };
            this.add_action_entries (actions, this);
            var vimode = new PropertyAction ("vimode", this, "vimode");
            vimode.notify.connect (this.set_vi_mode);
            this.add_action (vimode);
            this.editor_theme = "Adwaita";
            var set_editor_theme = new PropertyAction ("set_editor_theme", this, "editor_theme");
            set_editor_theme.notify.connect (this.set_theme);
            this.add_action (set_editor_theme);
            var pop = (Gtk.PopoverMenu)this.menu_button.get_popover ();
            this.theme_switcher = new Vapad.ThemeSwitcher ();
            pop.add_child (this.theme_switcher, "theme");
            this.notebook.page_removed.connect (check_tab_visibility);
            this.notebook.page_added.connect (check_tab_visibility);
            this.notebook.switch_page.connect ( (nb, num) => update_title (num));
            this.search_entry.activate.connect (new_search);

            this.search_completion = new Gtk.EntryCompletion () {
                popup_completion = true,
                text_column = 0,
                minimum_key_length = 1,
            };
            var ls = new Gtk.ListStore (1, GLib.Type.STRING);
            this.search_completion.set_model (ls);
            this.search_entry.set_completion (this.search_completion);
            this.theme_switcher.use_system_theme.connect (set_system_theme);
            this.theme_switcher.use_light_theme.connect (set_light_theme);
            this.theme_switcher.use_dark_theme.connect (set_dark_theme);
            this.init_style_menu (pop);
        }

        private void init_style_menu (Gtk.PopoverMenu pop) {
            GLib.Menu menu = new GLib.Menu ();
            var manager = new GtkSource.StyleSchemeManager ();
            var ids = manager.get_scheme_ids ();
            foreach (string id in ids) {
                menu.append (id, @"win.set_editor_theme::$id");
            }
            var model = (GLib.Menu)pop.get_menu_model ();
            model.insert_submenu (3, "Editor Theme", menu);
        }

        public void new_page () {
            Tab tab = new Vapad.Tab ();
            this.setup_tab (tab);
        }

        private void setup_tab (Vapad.Tab tab) {
            var manager = new GtkSource.StyleSchemeManager ();
            var scheme = manager.get_scheme (this.editor_theme);
            var buffer = (GtkSource.Buffer)tab.sourceview.get_buffer ();
            buffer.set_style_scheme (scheme);
            this.notebook.append_page(tab, tab.lbox);
            tab.close_button.clicked.connect ( () => {
                this.notebook.remove_page (this.notebook.page_num (tab));
            });
            tab.file_saved.connect ( () => {
                this.update_title (this.notebook.get_current_page ());
                this.send_saved_toast (name);
            });
            if (this.vimode) {
                tab.set_vi_mode ();
            }
            if (this.editor_font != null) {
                var font = Pango.FontDescription.from_string (this.editor_font);
                tab.set_css_font (this.get_font_css (font));
            }
            var n = this.notebook.page_num (tab);
            this.notebook.set_current_page (n);
            this.update_title (n);
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
                            this.setup_tab (tab);
                        }
                        tab.load_file (file);
                    }
                }
                dlg.close ();
            });
            chooser.show ();
        }

        public void open_named (string path) {
            var file = GLib.File.new_for_path (path);
            var tab = new Vapad.Tab ();
            tab.load_file (file);
            this.setup_tab (tab);
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

        private void send_saved_toast (string name) {
            this.set_toast (@"$name saved");
        }

        public Vapad.Tab? current_tab () {
            return (Vapad.Tab)this.notebook.get_nth_page (this.notebook.get_current_page ());
        }

        public Vapad.Tab? nth_tab (int n) {
            return (Vapad.Tab)this.notebook.get_nth_page (n);
        }

        public int n_tabs () {
            return this.notebook.get_n_pages ();
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
            var settings = new GtkSource.SearchSettings () {
                wrap_around = true,
                case_sensitive = this.match_case.get_active (),
                at_word_boundaries = this.whole_words.get_active (),
                search_text = this.search_entry.get_text (),
            };
            var list = (Gtk.ListStore)this.search_completion.get_model ();
            Gtk.TreeIter iter;
            list.append (out iter);
            list.set (iter, 0, this.search_entry.get_text ());
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
            if (this.search_context.forward (current, out start, out end, out has_wrapped)) {
                buffer.place_cursor (start);
                buffer.select_range (start, end);
                view.scroll_to_iter (start, 0.25, false, 0.1, 0.1);
            }
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
            if (this.search_context.backward (current, out start, out end, out has_wrapped)) {
                buffer.place_cursor (start);
                buffer.select_range (start, end);
                view.scroll_to_iter (start, 0.25, false, 0.1, 0.1);
            }
        }

        private void advanced_search () {
            this.hide_search ();
            var dialog = new Vapad.SearchDialog (this);
            dialog.strings_replaced.connect ( (n) => {
                this.set_toast (@"replaced $n occurances");
            });
            dialog.show ();
        }

        private void replace_text () {
        }
        
        private void set_toast (string str){
            var toast = new Adw.Toast (str);
            toast.set_timeout (3);
            overlay.add_toast (toast);
        }

        private void set_system_theme () {
            Adw.StyleManager.get_default ().set_color_scheme (Adw.ColorScheme.DEFAULT);
            this.set_toast ("Using system application style");
        }

        private void set_light_theme () {
            Adw.StyleManager.get_default ().set_color_scheme (Adw.ColorScheme.FORCE_LIGHT);
            this.set_toast ("Using light application style");
        }

        private void set_dark_theme () {
            Adw.StyleManager.get_default ().set_color_scheme (Adw.ColorScheme.FORCE_DARK);
            this.set_toast ("Using dark application style");
        }

        private void set_vi_mode () {
            var app = this.get_application ();
            if (this.vimode) {
                app.set_accels_for_action ("win.search", {});
            } else {
                app.set_accels_for_action ("win.search", {"<primary>f"});
            }
            for (int i = 0; i < this.notebook.get_n_pages (); i++) {
                var tab = (Vapad.Tab)this.notebook.get_nth_page (i);
                if (this.vimode) {
                    tab.set_vi_mode ();
                } else {
                    tab.unset_vi_mode ();
                }
            }
        }

        private void set_theme () {
            var manager = new GtkSource.StyleSchemeManager ();
            var scheme = manager.get_scheme (this.editor_theme);
            for (int i = 0; i < this.notebook.get_n_pages (); i++) {
                var tab = (Vapad.Tab)this.notebook.get_nth_page (i);
                var buffer = (GtkSource.Buffer)tab.sourceview.get_buffer ();
                buffer.set_style_scheme (scheme);
            }
            //this.set_toast (@"Set editor style $(this.editor_theme)");
        }

        private string get_font_css (Pango.FontDescription font) {
            var family = font.get_family ();
            var style = "normal";
            switch (font.get_style ()) {
                case Pango.Style.ITALIC:
                    style = "Italic";
                    break;
                case Pango.Style.OBLIQUE:
                    style = "Oblique";
                    break;
                default:
                    style = "Normal";
                    break;
            }
            var size = font.get_size () / 1024;
            int weight = 400;
            switch (font.get_weight ()) {
                case Pango.Weight.BOLD:
                    weight = 700;
                    break;
                case Pango.Weight.THIN:
                    weight = 100;
                    break;
                case Pango.Weight.BOOK:
                    weight = 400;
                    break;
                case Pango.Weight.HEAVY:
                    weight = 900;
                    break;
                case Pango.Weight.LIGHT:
                    weight = 300;
                    break;
                case Pango.Weight.MEDIUM:
                    weight = 500;
                    break;
                case Pango.Weight.SEMIBOLD:
                    weight = 600;
                    break;
                case Pango.Weight.SEMILIGHT:
                    weight = 350;
                    break;
                case Pango.Weight.ULTRABOLD:
                    weight = 800;
                    break;
                case Pango.Weight.ULTRALIGHT:
                    weight = 100;
                    break;
                case Pango.Weight.ULTRAHEAVY:
                    weight = 950;
                    break;
                default:
                    weight = 400;
                    break;
            }
            var css = @"textview.view { font-family: $family; font-size: $(size)pt; font-weight: $weight; font-style: $style; }";
            return css;
        }

        private void set_font () {
            var dlg = new Gtk.FontChooserDialog ("Select a font", this);
            if (this.editor_font!= null) {
                dlg.set_font (editor_font);
            }
            dlg.response.connect ( (dlg,res) => {
                if (res == Gtk.ResponseType.OK) {
                    var chooser = (Gtk.FontChooser)dlg;
                    var font = chooser.get_font_desc ();
                    this.editor_font = font.to_string ();
                    var css = this.get_font_css (font);
                    for (int i = 0; i < this.notebook.get_n_pages (); i++) {
                        var tab = (Vapad.Tab)this.notebook.get_nth_page (i);
                        tab.set_css_font(css);
                    }
                }
                dlg.close ();
            });
            dlg.show ();
        }
    }
}
