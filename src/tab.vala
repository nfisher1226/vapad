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
        public signal void file_saved (string name);

        public Tab () {
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
            ScrolledWindow scroller = new ScrolledWindow ();
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
            scroller.set_hexpand (true);
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
    }
}
