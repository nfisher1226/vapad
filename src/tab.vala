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

 using Gtk;
 using GtkSource;

namespace Vapad {
    public class Tab : Box {
        public Box lbox;
        public Label label;
	public Button close_button;
	public View sourceview;

	public Tab () {
	    create_widgets ();
	}

	private void create_widgets () {
	    this.lbox = new Box (Orientation.HORIZONTAL, 5);
	    this.label = new Label ("New file");
	    lbox.append (this.label);
	    this.close_button = new Button ();
	    this.close_button.set_has_frame (false);
	    lbox.append (this.close_button);
	    var image = new Image.from_icon_name ("window-close-symbolic");
	    this.close_button.set_child (image);
	    var scroller = new ScrolledWindow ();
	    this.append (scroller);
	    this.sourceview = new View();
	    scroller.set_child (this.sourceview);
	    scroller.set_hexpand (true);
	}
    }
}
