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
        private unowned Adw.SplitButton open_button;
        [GtkChild]
        private unowned Adw.WindowTitle window_title;
        [GtkChild]
        private unowned Gtk.MenuButton menu_button;
        [GtkChild]
        private unowned Adw.TabBar tab_bar;
        [GtkChild]
        public unowned Adw.TabView tabview;
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
        public bool display_grid { get; set; }
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
                { "next_tab", this.next_tab },
                { "previous_tab", this.previous_tab },
                { "set_font", this.set_font },
            };
            this.add_action_entries (actions, this);
            this.window_title.set_title (@"$PROGNAME-$VERSION");

            // Setup property and action for "vimode"
            var vimode = new PropertyAction ("vimode", this, "vimode");
            vimode.notify.connect (this.set_vi_mode);
            this.add_action (vimode);

            // Setup property action for displaying grid pattern
            var grid = new PropertyAction ("display_grid", this, "display_grid");
            grid.notify.connect (this.set_grid);
            this.add_action (grid);

            this.editor_theme = "Adwaita";
            var set_editor_theme = new PropertyAction ("set_editor_theme", this, "editor_theme");
            set_editor_theme.notify.connect (this.set_theme);
            this.add_action (set_editor_theme);
            var open_named = new SimpleAction ("open_named", GLib.VariantType.STRING);
            open_named.activate.connect ((path) => this.open_named ((string) path));
            this.add_action (open_named);

            var pop = (Gtk.PopoverMenu) this.menu_button.get_popover ();
            this.theme_switcher = new Vapad.ThemeSwitcher ();
            pop.add_child (this.theme_switcher, "theme");
            this.tabview.notify["selected-page"].connect (() => {
                var page = this.tabview.get_selected_page ();
                this.update_title (page);
            });
            this.tabview.close_page.connect ((_tabview, page) => {
                var tab = (Vapad.Tab)page.get_child ();
                this.close_tab (tab);
            });
            this.search_entry.activate.connect (new_search);

            this.search_completion = new Gtk.EntryCompletion () {
                popup_completion = true,
                text_column = 0,
                minimum_key_length = 1,
            };
            var ls = new Gtk.ListStore (1, GLib.Type.STRING);
            this.search_completion.set_model (ls);
            this.search_entry.set_completion (this.search_completion);
            this.init_style_menu (pop);
            this.init_recent ();
            this.close_request.connect (() => {
                this.close_all ();
            });
        }

        private void init_recent () {
            Gtk.RecentManager manager = Gtk.RecentManager.get_default ();
            var all_items = manager.get_items ();
            var model = new GLib.Menu ();
            all_items.foreach ((item) => {
                if (item.has_application ("vapad") && item.get_age () < 7) {
                    string path = item.get_uri_display ();
                    string act = @"win.open_named::$path";
                    var entry = new GLib.MenuItem (item.get_short_name (), act);
                    model.append_item (entry);
                }
            });
            this.open_button.set_menu_model (model);
        }

        private void init_style_menu (Gtk.PopoverMenu pop) {
            GLib.Menu menu = new GLib.Menu ();
            var manager = new GtkSource.StyleSchemeManager ();
            var ids = manager.get_scheme_ids ();
            foreach (string id in ids) {
                menu.append (id, @"win.set_editor_theme::$id");
            }
            var model = (GLib.Menu) pop.get_menu_model ();
            model.insert_submenu (3, _ ("Editor Theme"), menu);
        }

        public void new_page () {
            Tab tab = new Vapad.Tab ();
            this.setup_tab (tab);
        }

        private void setup_tab (Vapad.Tab tab) {
            var manager = new GtkSource.StyleSchemeManager ();
            var scheme = manager.get_scheme (this.editor_theme);
            var buffer = (GtkSource.Buffer) tab.sourceview.get_buffer ();
            buffer.set_style_scheme (scheme);
            var page = this.tabview.append (tab);
            tab.page = page;
            tab.file_saved.connect ((_, name) => {
                this.update_title (this.tabview.get_selected_page ());
                this.send_saved_toast (name);
            });
            if (this.vimode) {
                tab.set_vi_mode ();
            }
            if (this.display_grid) {
                tab.set_display_grid (true);
            } else {
                tab.set_display_grid (false);
            }
            if (this.editor_font != null) {
                var font = Pango.FontDescription.from_string (this.editor_font);
                tab.set_css_font (this.get_font_css (font));
            }
            this.tabview.set_selected_page (page);
            tab.page.set_title ("New File");
            this.update_title (page);
        }

        private void close_page () {
            var page = this.tabview.get_selected_page ();
            this.tabview.close_page (page);
        }

        public void close_all () {
            for (int i = 0; i < this.n_tabs (); i++) {
                this.close_tab (this.nth_tab (i));
            }
        }

        public void close_tab (Vapad.Tab tab) {
            var ext_modified = false;
            if (tab.sourcefile != null) {
                ext_modified = tab.sourcefile.is_externally_modified ();
            }
            if (tab.modified || ext_modified) {
                string fname = "Unknown File";
                if (tab.file != null) {
                    fname = tab.file.get_basename ();
                }
                var dlg = new Adw.MessageDialog (this,_ ("Save %s before closing?").printf(fname),"");
                dlg.add_response("cancel", _("_Cancel"));
                dlg.add_response("ok", _("_OK"));
                dlg.set_default_response("ok");
                dlg.set_close_response("cancel");
                dlg.set_response_appearance("ok", SUGGESTED);
                dlg.show();
                dlg.response.connect ((response) => {
                    if (response == "ok") {
                        if (tab.file != null) {
                            tab.save_file_on_close ();
                            this.tabview.close_page_finish (tab.page, true);
                        } else {
                            var chooser = new Gtk.FileChooserNative (
                                _ ("Save file as..."),
                                this,
                                Gtk.FileChooserAction.SAVE,
                                null,
                                null
                            );
                            chooser.response.connect ((d, res) => {
                                if (res == Gtk.ResponseType.ACCEPT) {
                                    GLib.File f = chooser.get_file ();
                                    if (f != null) {
                                        tab.file = f;
                                        GtkSource.File file = new GtkSource.File ();
                                        file.set_location (f);
                                        tab.sourcefile = file;
                                        tab.save_file_on_close ();
                                    }
                                }
                                this.tabview.close_page_finish (tab.page, true);
                            });
                            chooser.show ();
                        }
                    } else if (response != "delete-event") {
                        this.tabview.close_page_finish (tab.page, true);
                    }
                });
                dlg.show ();
            } else {
                this.tabview.close_page_finish (tab.page, true);
            }
            if (this.tabview.get_n_pages () == 0) {
                this.close ();
            }
        }

        private void open_file () {
            Gtk.FileChooserNative chooser = new Gtk.FileChooserNative (
                _ ("Select a file to open"),
                this,
                Gtk.FileChooserAction.OPEN,
                null,
                null
            );
            var f = this.current_tab ().file;
            if (f != null) {
                try {
                    chooser.set_current_folder (f.get_parent ());
                } catch (Error e) {
                    print ("Error: %s\n", e.message);
                }
            }
            chooser.response.connect ((dlg, res) => {
                if (res == Gtk.ResponseType.ACCEPT) {
                    File file = chooser.get_file ();
                    if (file != null) {
                        var tab = this.current_tab ();
                        if (tab.file != null) {
                            tab = new Vapad.Tab ();
                            this.setup_tab (tab);
                        }
                        tab.load_file (file);
                        this.update_title (tab.page);
                    }
                }
            });
            chooser.show ();
        }

        public void open_named (string path) {
            var file = GLib.File.new_for_path (path);
            var tab = new Vapad.Tab ();
            tab.load_file (file);
            this.setup_tab (tab);
        }

        public void update_title (Adw.TabPage? page) {
            var tab = (Vapad.Tab) page.get_child ();
            if (tab.file != null) {
                string path = tab.file.get_path ();
                string home = GLib.Environment.get_home_dir ();
                var fname = GLib.Path.get_basename (path);
                string title = path.replace (home, "~").replace (fname, "");
                this.window_title.set_subtitle (title);
                this.window_title.set_title (@"$PROGNAME-$VERSION ~ $fname");
            } else {
                this.window_title.set_subtitle (_ ("New file"));
                this.window_title.set_title (@"$PROGNAME-$VERSION");
            }
        }

        private void send_saved_toast (string name) {
            var saved = _ ("saved");
            this.set_toast (@"$name $saved");
        }

        public Vapad.Tab? current_tab () {
            return (Vapad.Tab) this.tabview.get_selected_page ().get_child ();
        }

        public Vapad.Tab? nth_tab (int n) {
            return (Vapad.Tab) this.tabview.get_nth_page (n).get_child ();
        }

        public int n_tabs () {
            return this.tabview.get_n_pages ();
        }

        private GtkSource.Buffer current_buffer () {
            return (GtkSource.Buffer) this.current_tab ().sourceview.get_buffer ();
        }

        private void save_file () {
            this.current_tab ().save_file ();
            this.update_title (this.tabview.get_selected_page ());
        }

        private void save_as () {
            this.current_tab ().save_as ();
        }

        private void save_all () {
            for (int n = 0; n < this.n_tabs (); n++) {
                Tab tab = (Vapad.Tab) this.nth_tab (n);
                tab.save_file ();
            }
        }

        private void last_tab () {
            int num = this.n_tabs ();
            var page = this.tabview.get_nth_page (num - 1);
            this.tabview.set_selected_page (page);
        }

        private void next_tab () {
            var page = this.tabview.get_selected_page ();
            if (this.tabview.get_page_position (page) >= this.n_tabs () - 1) {
                page = this.tabview.get_nth_page (0);
                this.tabview.set_selected_page (page);
            } else {
                this.tabview.select_next_page ();
            }
        }

        private void previous_tab () {
            var page = this.tabview.get_selected_page ();
            if (this.tabview.get_page_position (page) == 0) {
                this.last_tab ();
            } else {
                this.tabview.select_previous_page ();
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
            var list = (Gtk.ListStore) this.search_completion.get_model ();
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
            buffer.get_iter_at_offset (out current, (int) position);
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
            buffer.get_iter_at_offset (out current, (int) position);
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
            dialog.strings_replaced.connect ((n) => {
                string replaced = _ ("replaced");
                string occurances = _ ("occurances");
                this.set_toast (@"$replaced $n $occurances");
            });
            dialog.show ();
        }

        private void replace_text () {
        }

        private void set_toast (string str) {
            var toast = new Adw.Toast (str) {
                timeout = 3,
            };
            overlay.add_toast (toast);
        }

        private void set_vi_mode () {
            var app = this.get_application ();
            if (this.vimode) {
                app.set_accels_for_action ("win.search", {});
            } else {
                app.set_accels_for_action ("win.search", { "<primary>f" });
            }
            for (int i = 0; i < this.n_tabs (); i++) {
                var tab = this.nth_tab (i);
                if (this.vimode) {
                    tab.set_vi_mode ();
                } else {
                    tab.unset_vi_mode ();
                }
            }
        }

        private void set_grid () {
            for (int i = 0; i < this.n_tabs (); i++) {
                var tab = this.nth_tab (i);
                if (this.display_grid) {
                    tab.set_display_grid (true);
                } else {
                    tab.set_display_grid (false);
                }
            }
        }

        private void set_theme () {
            var manager = new GtkSource.StyleSchemeManager ();
            var scheme = manager.get_scheme (this.editor_theme);
            for (int i = 0; i < this.n_tabs (); i++) {
                var tab = this.nth_tab (i);
                var buffer = (GtkSource.Buffer) tab.sourceview.get_buffer ();
                buffer.set_style_scheme (scheme);
            }
            // this.set_toast (@"Set editor style $(this.editor_theme)");
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
            var dlg = new Gtk.FontChooserDialog (_ ("Select a font"), this);
            if (this.editor_font != null) {
                dlg.set_font (editor_font);
            }
            dlg.response.connect ((dlg, res) => {
                if (res == Gtk.ResponseType.OK) {
                    var chooser = (Gtk.FontChooser) dlg;
                    var font = chooser.get_font_desc ();
                    this.editor_font = font.to_string ();
                    var css = this.get_font_css (font);
                    for (int i = 0; i < this.n_tabs (); i++) {
                        var tab = this.nth_tab (i);
                        tab.set_css_font (css);
                    }
                }
                dlg.close ();
            });
            dlg.show ();
        }
    }
}
