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
    public class Tab : Box {
        public Box lbox;
        public Label label;
        public Button close_button;
        public View sourceview;
        public GLib.File? file;
        public GtkSource.File? sourcefile;
        private Gtk.EventController? controller;
        private Gtk.Box cmd_bar;
        private Gtk.Label cmd_bar_txt;
        private Gtk.Label cmd_txt;
        public signal void file_saved (string name);

        public Tab () {
            Object (
                orientation: Gtk.Orientation.VERTICAL,
                vexpand: true
            );
            create_widgets ();
        }

        private void create_widgets () {
            this.lbox = new Box (Orientation.HORIZONTAL, 5) {
                hexpand = true,
                can_focus = false,
            };
            this.label = new Label ("New file") {
                hexpand = true,
            };
            lbox.append (this.label);
            this.close_button = new Button () {
                has_frame = false,
            };
            lbox.append (this.close_button);
            Image image = new Image.from_icon_name ("window-close-symbolic");
            this.close_button.set_child (image);
            ScrolledWindow scroller = new ScrolledWindow () {
                hexpand = true,
                vexpand = true,
            };
            this.append (scroller);
            this.sourceview = new View() {
                show_line_numbers = true,
                auto_indent = true,
                indent_on_tab = true,
                right_margin_position = 80,
                show_right_margin = true,
                smart_home_end = SmartHomeEndType.AFTER,
                smart_backspace = true,
                highlight_current_line = true,
            };
            scroller.set_child (this.sourceview);
            this.cmd_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5) {
                visible = false,
                hexpand = true,
                vexpand = false,
                css_classes = { "vi-cmd-bar" },
            };
            this.cmd_bar_txt = new Gtk.Label ("") {
                margin_start = 10,
                margin_end = 10,
            };
            this.cmd_txt = new Gtk.Label ("") {
                margin_start = 10,
                margin_end = 10,
            };
            cmd_bar.append (cmd_bar_txt);
            cmd_bar.append (cmd_txt);
            this.append (cmd_bar);
        }

        public void load_file (GLib.File f) {
            Buffer buffer = (Buffer)this.sourceview.get_buffer ();
            GtkSource.File file = new GtkSource.File ();
            file.set_location (f);
            FileLoader loader = new FileLoader (buffer, file);
            Language language = new LanguageManager ()
                .get_default ()
                .guess_language (f.get_path (), null);
            buffer.set_language (language);
            loader.load_async.begin (-100, null, null);
            this.file = f;
            this.sourcefile = file;
            this.set_title ();
        }

        public void save_file () {
            if (this.file != null) {
                Buffer buffer = (Buffer) this.sourceview.get_buffer ();
                FileSaver saver = new FileSaver (buffer, this.sourcefile);
                saver.save_async.begin (-100, null, null);
                this.file_saved (this.file.get_basename ());
            } else {
                this.save_as ();
            }
        }

        public void save_as () {
            FileChooserDialog chooser = new FileChooserDialog (
                "Save file as...",
                (Window)this.get_root (),
                FileChooserAction.SAVE
            );
            chooser.add_button ("Accept", Gtk.ResponseType.ACCEPT);
            chooser.add_button ("Cancel", Gtk.ResponseType.CANCEL);
            chooser.response.connect ( (dlg, res) => {
                if (res == Gtk.ResponseType.ACCEPT) {
                    GLib.File f = chooser.get_file ();
                    if (f != null) {
                        this.file = f;
                        GtkSource.File file = new GtkSource.File ();
                        file.set_location (f);
                        this.sourcefile = file;
                        this.save_file ();
                        this.set_title ();
                    }
                }
                dlg.close ();
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

        public void set_css_font (string css) {
            var provider = new Gtk.CssProvider ();
            provider.load_from_data (css.data);
            var ctx = this.sourceview.get_style_context ();
            ctx.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }
    }
}
