/*
 * Presets.vala
 *
 * Copyright 2014 Zdeněk Janeček <haswi@lhota4>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */

using Gtk;

class Presets : Gtk.Dialog
{
    public struct Fractal
    {
        Gdk.Pixbuf img;
        double x;
        double y;
    }

    /* indicates user input */
    private bool dirty = true;

    /* my own settings */
    private Fractal own_fractal;

    /* loaded presets from the file */
    private Fractal[] fractals;

    /* choosen preset */
    private int fr_pos = 0;

    public Presets (Window parent)
    {
        double cx, cy;
        set_transient_for (parent);

        load_fractals ("files");

        cx = ((App) parent).julius.cx;
        cy = ((App) parent).julius.cy;

        create_widgets (cx, cy);

        own_fractal.x = cx;
        own_fractal.y = cy;
    }

    /*
     * load fractals from the file
     */
    private void load_fractals (string f)
    {
        var file = File.new_for_path (f);

        if (!file.query_exists ())
        {
            stderr.printf ("File '%s' doesn't exist.\n", file.get_path ());
            return;
        }

        DataInputStream dis;
        try
        {
            dis = new DataInputStream (file.read ());
            string line;
            line = dis.read_line (null);

            fractals = new Fractal[int.parse(line)];

            for (int i = 0; i < fractals.length; i++)
            {
                line = dis.read_line (null);
                string[] l = line.split (" ", 3);
                fractals[i].img = new Gdk.Pixbuf.from_file (l[0]);
                fractals[i].x = double.parse(l[1]);
                fractals[i].y = double.parse(l[2]);
            }
            dis.close();
        }
        catch (Error e)
        {
            error ("%s", e.message);
        }
    }

    /*
     * prepares widgets of the dialog
     */
    private void create_widgets (double cx, double cy)
    {
        Gtk.ListStore list_store = new Gtk.ListStore (2, typeof(Gdk.Pixbuf), typeof(string));

        Gtk.TreeView view = new Gtk.TreeView.with_model (list_store);

        view.insert_column_with_attributes (-1, "Obrázek", new CellRendererPixbuf (), "pixbuf", 0);
        view.insert_column_with_attributes (-1, "Rovnice", new CellRendererText (), "text", 1);

        get_content_area().add (view);

        Gtk.Entry entryx = new Gtk.Entry ();
        get_content_area().add (entryx);

        Gtk.Entry entryy = new Gtk.Entry ();
        get_content_area().add (entryy);

        TreeIter iter;
        for (int i = 0; i < fractals.length; i++)
        {
            string values = "x=".concat(fractals[i].x.to_string()," y=",fractals[i].y.to_string(),".");
            list_store.append (out iter);
            list_store.set (iter, 0, fractals[i].img, 1, values);
        }

        // TreeView handler
        view.cursor_changed.connect(() =>
        {
            TreePath path;
            TreeViewColumn focus_column;

            view.get_cursor (out path, out focus_column);
            int pos = path.get_indices ()[0];

            dirty = false;
            fr_pos = pos;
            //entryx.set_text (fractals[pos].x.to_string ());
            //entryy.set_text (fractals[pos].y.to_string ());

            own_fractal.x = fractals[pos].x;
            own_fractal.y = fractals[pos].y;
        });

        view.get_selection ().set_mode (SelectionMode.SINGLE);

        // x value
        entryx.set_text (cx.to_string ());
        entryx.placeholder_text = "x";
        entryx.max_length = 10;
        entryx.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-clear");
        entryx.icon_press.connect ((pos, event) =>
        {
            if (pos == Gtk.EntryIconPosition.SECONDARY)
            {
                entryx.set_text ("");
            }
        });
        entryx.activate.connect (() =>
        {
            unowned string str = entryx.get_text ();
            dirty = true;
            own_fractal.x = double.parse(str);
        });

        // y value
        entryy.set_text (cy.to_string ());
        entryy.placeholder_text = "y";
        entryy.max_length = 10;
        entryy.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-clear");
        entryy.icon_press.connect ((pos, event) =>
        {
            if (pos == Gtk.EntryIconPosition.SECONDARY)
            {
                entryy.set_text ("");
            }
        });
        entryy.activate.connect (() =>
        {
            unowned string str = entryy.get_text ();
            dirty = true;
            own_fractal.y = double.parse(str);
        });

        add_button ("Vybrat", ResponseType.ACCEPT);
        show_all ();
    }

    /*
     * Returns custom values or predefined
     */
    public unowned Fractal get_fractal ()
    {
        if (dirty)
        {
            return own_fractal;
        }
        else
        {
            return fractals[fr_pos];
        }

    }
}
