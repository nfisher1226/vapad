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

        public Tab () {
            create_widgets ();
        }

        private void create_widgets () {
            this.lbox = new Box (Orientation.HORIZONTAL, 5);
            this.lbox.set_hexpand (true);
            this.lbox.set_can_focus (false);
            this.label = new Label ("New file");
            this.label.set_hexpand (true);
            lbox.append (this.label);
            this.close_button = new Button ();
            this.close_button.set_has_frame (false);
            lbox.append (this.close_button);
            Image image = new Image.from_icon_name ("window-close-symbolic");
            this.close_button.set_child (image);
            ScrolledWindow scroller = new ScrolledWindow ();
            this.append (scroller);
            this.sourceview = new View();
            this.sourceview.set_show_line_numbers (true);
            this.sourceview.set_auto_indent (true);
            this.sourceview.set_indent_on_tab (true);
            this.sourceview.set_right_margin_position (80);
            this.sourceview.set_show_right_margin (true);
            scroller.set_child (this.sourceview);
            scroller.set_hexpand (true);
        }

        public void load_file (GLib.File f) {
            try {
                uint8[] contents;
                string etag_out;
                FileInfo info = f.query_info ("standard::*", 0);
                int64 size = info.get_size ();
                f.load_contents (null, out contents, out etag_out);
                Buffer buffer = (Buffer)this.sourceview.get_buffer ();
                Language language = new LanguageManager ()
                    .get_default ()
                    .guess_language (f.get_path (), null);
                buffer.set_language (language);
                buffer.set_text ((string)contents, (int)size);
                this.file = f;
                this.set_title ();
            } catch (Error e) {
                print ("Error: %s\n", e.message);
            }
        }

        public void save_file () {
            if (this.file != null) {
                try {
                    TextBuffer buffer = this.sourceview.get_buffer ();
                    TextIter start;
                    TextIter end;
                    buffer.get_start_iter (out start);
                    buffer.get_end_iter (out end);
                    string text = buffer.get_text (start, end, true);
                    this.file.replace_contents (
                        text.data,
                        null,
                        false,
                        GLib.FileCreateFlags.NONE,
                        null,
                        null
                    );
                } catch (Error e) {
                    print ("Error: %s\n", e.message);
                }
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
                    GLib.File file = chooser.get_file ();
                    if (file != null) {
                        this.file = file;
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
        
        public void search (SearchContext context) {
        }
    }
}
