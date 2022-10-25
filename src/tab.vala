/* tab.vala
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

using Gtk;
using GtkSource;

namespace Vapad {
    [GtkTemplate (ui = "/org/hitchhiker_linux/vapad/tab.ui")]
    public class Tab : Box {
        [GtkChild]
        public unowned Box lbox;
        [GtkChild]
        public unowned Label label;
        [GtkChild]
        public unowned Button close_button;
        [GtkChild]
        public unowned View sourceview;
        [GtkChild]
        private unowned Gtk.Box cmd_bar;
        [GtkChild]
        private unowned Gtk.Label cmd_bar_txt;
        [GtkChild]
        private unowned Gtk.Label cmd_txt;
        public GLib.File? file;
        public GtkSource.File? sourcefile;
        public bool modified {get; set; }
        private Gtk.EventController? controller;
        public signal void file_saved (string name);
        public string syntax_language { get; set; }

        public Tab () {
            Object ();
        }

        construct {
            this.syntax_language = "C";
            var tabgroup = new GLib.SimpleActionGroup ();
            this.insert_action_group ("tab", tabgroup);
            var set_lang = new GLib.PropertyAction ("set_lang", this, "syntax_language");
            tabgroup.add_action (set_lang);
            set_lang.notify.connect (set_language);
            this.sourceview.buffer.changed.connect ( () => this.modified = true);
            this.modified = false;
        }

        public void load_file (GLib.File f) {
            GtkSource.File file = new GtkSource.File ();
            file.set_location (f);
            this.file = f;
            this.sourcefile = file;
            this.setup_language ();
            FileLoader loader = new FileLoader ((Buffer)this.sourceview.buffer, file);
            loader.load_async.begin (-100, null, null, this.finish_load);
        }
        
        private void setup_language () {
            Language language = new LanguageManager ()
                .get_default ()
                .guess_language (this.file.get_path (), null);
            if (language != null) {
    		var buffer = (GtkSource.Buffer)this.sourceview.buffer;
                buffer.set_language (language);
                this.syntax_language = language.get_id ();
            }
        }
        
        private void finish_load () {
            this.set_title ();
            var extra_menu = this.sourceview.get_extra_menu ();
            if (extra_menu != null) {
                this.set_lang_menu ((GLib.Menu)extra_menu);
            }
	    this.modified = false;
	}

        public void save_file () {
            if (this.file != null) {
                Buffer buffer = (Buffer) this.sourceview.get_buffer ();
                FileSaver saver = new FileSaver (buffer, this.sourcefile);
                saver.save_async.begin (-100, null, null, this.finish_save);
            } else {
                this.save_as ();
            }
        }
        
        private void finish_save () {
            this.file_saved (this.file.get_basename ());
            this.modified = false;
        }

        public void save_as () {
            FileChooserNative chooser = new FileChooserNative (
                _("Save file as..."),
                (Window)this.get_root (),
                FileChooserAction.SAVE,
                null,
                null
            );
            chooser.response.connect ( (dlg, res) => {
                if (res == Gtk.ResponseType.ACCEPT) {
                    GLib.File f = chooser.get_file ();
                    if (f != null) {
                        this.file = f;
                        GtkSource.File file = new GtkSource.File ();
                        file.set_location (f);
                        this.sourcefile = file;
                        this.setup_language ();
                        var extra_menu = this.sourceview.get_extra_menu ();
    			if (extra_menu != null) {
        		    this.set_lang_menu ((GLib.Menu)extra_menu);
    			}
                        this.save_file ();
                        this.set_title ();
                    }
                }
            });
            chooser.show ();
        }

        private void set_title () {
            string name = this.file.get_basename ();
            if (name != null) {
                this.label.set_text (name);
            }
        }

        public void set_vi_mode () {
            var ctx = new GtkSource.VimIMContext ();
            var key = new Gtk.EventControllerKey ();
            key.set_im_context (ctx);
            key.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
            this.sourceview.add_controller (key);
            ctx.set_client_widget (this.sourceview);
            this.controller = key;
            this.cmd_bar.show ();
            ctx.bind_property ("command-bar-text", this.cmd_bar_txt, "label", 0);
            ctx.bind_property ("command-text", this.cmd_txt, "label", 0);
            ctx.write.connect (save_file);
            ctx.edit.connect ( (ctx,view,path) => {
                var win = (Vapad.Window)this.get_root ();
                win.open_named (path);
            });
        }

        public void unset_vi_mode () {
            if (this.controller != null) {
                this.sourceview.remove_controller (this.controller);
            }
            this.cmd_bar.set_visible (false);
            this.controller = null;
        }
        
        public void set_display_grid (bool display) {
	    if (display) {
                this.sourceview.set_background_pattern (GtkSource.BackgroundPatternType.GRID);
	    } else {
                this.sourceview.set_background_pattern (GtkSource.BackgroundPatternType.NONE);
	    }
	}

        public void set_css_font (string css) {
            var provider = new Gtk.CssProvider ();
            provider.load_from_data (css.data);
            var ctx = this.sourceview.get_style_context ();
            ctx.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        public void set_lang_menu (GLib.Menu model) {
            var manager = new GtkSource.LanguageManager ();
            var languages = manager.get_language_ids ();
            var menu = new GLib.Menu ();
            foreach (string id in languages) {
                menu.append (id, @"tab.set_lang::$id");
            }
            model.insert_submenu (2, _("Language"), menu);
        }

        private void set_language () {
            var manager = new GtkSource.LanguageManager ();
            var language = manager.get_language (syntax_language);
            var buffer = (GtkSource.Buffer)this.sourceview.buffer;
            buffer.set_language (language);
        }
    }
}
