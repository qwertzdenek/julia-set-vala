/*
 * App.vala
 *
 * Copyright 2014 Zdeněk Janeček <jan.zdenek@gmail.com>
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
 */

using Gtk;
using GtkClutter;
using Cairo;
using Gdk;

class App : Gtk.Window
{
    // *** Constants ***

    /* Default animation time */
    private const int DEFAULT_FADE_TIME = 1000;

    /* Fractal window */
    private const double DEFAULT_XMIN = -1.6;
    private const double DEFAULT_XMAX = 1.6;
    private const double DEFAULT_YMIN = -1.2;
    private const double DEFAULT_YMAX = 1.2;

    // *** Attributes ***

    /* click position last occured */
    private float click_x;
    private float click_y;

    /* fractal ranges */
    private double xmax = DEFAULT_XMAX;
    private double xmin = DEFAULT_XMIN;
    private double ymax = DEFAULT_YMAX;
    private double ymin = DEFAULT_YMIN;

    /* indicates img1 on top */
    private bool top = true;

    /* indicates pressed mouse button */
    private bool pressed = false;

    /* drawing area for animation */
    private Clutter.Actor stage;
    private GtkClutter.Texture img1;
    private GtkClutter.Texture img2;

    /* select rectangle */
    private Clutter.Actor r;

    /* Image buffer */
    private Pixbuf pbact;

    /* used julius object */
    public Julius julius;

    // *** Enums ***

    enum Fades
    {
        IN, OUT
    }

    public App ()
    {
        this.title = "Juliova množina";
        this.window_position = WindowPosition.CENTER;
        this.set_default_size (800, 600);
        this.destroy.connect (Gtk.main_quit);

        this.set_events (Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK);
        this.button_press_event.connect (button_press);
        this.button_release_event.connect (button_release);
        this.motion_notify_event.connect (motion_event);

        julius = new Julius();

        // create vertical box
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        // create toolbar
        var toolbar = new Toolbar ();
        toolbar.get_style_context ().add_class (STYLE_CLASS_PRIMARY_TOOLBAR);

        var save_button = new ToolButton (null, "Save image");
        save_button.set_icon_name ("document-save");
        toolbar.add (save_button);
        save_button.clicked.connect (on_save_clicked);

        // presets button
        Gtk.Image img_presets = new Gtk.Image.from_icon_name ("insert-image", Gtk.IconSize.SMALL_TOOLBAR);
        Gtk.ToolButton presets_button = new Gtk.ToolButton (img_presets, null);
        presets_button.clicked.connect (() =>
        {
            var presets = new Presets (this);
            if (presets.run () == ResponseType.ACCEPT)
            {
                unowned Presets.Fractal res = presets.get_fractal ();
                julius.cx = res.x;
                julius.cy = res.y;
                paint ();
            }
            presets.destroy ();
        });
        toolbar.add (presets_button);

        // theme button
        Gtk.Image img_theme = new Gtk.Image.from_icon_name ("preferences-desktop-theme", Gtk.IconSize.SMALL_TOOLBAR);
        Gtk.ToolButton theme_button = new Gtk.ToolButton (img_theme, null);
        theme_button.clicked.connect (() =>
        {
            Gtk.ColorChooserDialog chooser = new Gtk.ColorChooserDialog ("Choose color", this);
            if (chooser.run () == Gtk.ResponseType.OK)
            {
                julius.r = (uint8) (chooser.rgba.red * 255);
                julius.g = (uint8) (chooser.rgba.green * 255);
                julius.b = (uint8) (chooser.rgba.blue * 255);
                paint ();
            }
            chooser.close ();
        });
        toolbar.add (theme_button);

        // refresh button
        Gtk.ToolButton refresh = new Gtk.ToolButton (new Label("Refresh"), null);
        refresh.clicked.connect (() =>
        {
            xmax = DEFAULT_XMAX;
            xmin = DEFAULT_XMIN;
            ymax = DEFAULT_YMAX;
            ymin = DEFAULT_YMIN;

            paint();
        });
        toolbar.add (refresh);

        // add toolbar to vertical box
        box.pack_start (toolbar, false, true, 0);

        GtkClutter.Embed embed = new GtkClutter.Embed ();
        embed.size_allocate.connect (on_size_allocate);
        stage = embed.get_stage ();

        // add GtkClutter
        box.pack_start (embed, true, true, 0);
        add (box);

        img1 = new GtkClutter.Texture();
        img1.set_opacity (255);
        img2 = new GtkClutter.Texture();
        img2.set_opacity (0);

        r = new Clutter.Actor ();
        r.set_opacity (0);
        r.background_color = Clutter.Color.from_string ("#76b8ffAA");

        stage.hide.connect (Gtk.main_quit);
        stage.add_child (img1);
        stage.add_child (img2);
        stage.add_child (r);
    }

    /*
     * linear interpolation between two scalars by k
     */
    public static double lerp (double k, double a, double b)
    {
        return a + k * (b - a);
    }

    /*
     * linear interpolation between two scalars by k
     */
    public static uint8 lerp_u (double k, uint8 a, uint8 b)
    {
        return (uint8) (a + k * (b - a));
    }

    /*
     * button press handler
     */
    private bool button_press (Gdk.EventButton event)
    {
        pressed = true;

        click_x = (float) event.x;
        click_y = (float) event.y;

        // set rectangle initial values
        r.x = click_x;
        r.y = click_y;
        r.width = 1f;
        r.height = 1f;
        r.set_opacity (255); // show

        return true;
    }

    /*
     * button release handler
     */
    private bool button_release (Gdk.EventButton event)
    {
        pressed = false;
        actor_fade (r, Fades.OUT, 300);

        // Compute new fractal min max values
        int w = pbact.get_width();
        int h = pbact.get_height();

        double kxmin = (double) r.x / w;
        xmin = lerp(kxmin, xmin, xmax);

        double kxmax = (double) (r.x + r.width) / w;
        xmax = lerp(kxmax, xmin, xmax);

        double kymin = (double) r.y / h;
        ymin = lerp(kymin, ymin, ymax);

        double kymax = (double) (r.y + r.height) / h;
        ymax = lerp(kymax, ymin, ymax);

        paint();

        return true;
    }

    /*
     * mouse motion handler
     */
    private bool motion_event (EventMotion event)
    {
        if (!pressed)
            return true;

        float delta_x  = (float) (event.x - click_x);
        float delta_y = (float) (event.y - click_y);

        // determine quadrant
        if (delta_x > 0f && delta_y > 0f)
        {
            r.x = click_x;
            r.y = click_y;
            r.width = delta_x;
            r.height = delta_y;
        }
        else if (delta_y < 0f && delta_x > 0f)
        {
            r.x = (float) click_x;
            r.y = (float) event.y;
            r.width = delta_x;
            r.height = (float) (click_y - event.y);
        }
        else if (delta_x < 0f && delta_y > 0f)
        {
            r.x = (float) event.x;
            r.y = click_y;
            r.width = (float) (click_x - event.x);
            r.height = delta_y;
        }
        else
        {
            r.x = (float) event.x;
            r.y = (float) event.y;
            r.width = (float) (click_x - event.x);
            r.height = (float) (click_y - event.y);
        }

        return true;
    }

    /*
     * Window size change handler
     */
    private void on_size_allocate (Allocation a)
    {
        pbact = new Pixbuf (Gdk.Colorspace.RGB, true, 8, (int) a.width, (int) a.height);

        paint_simple ();
    }

    /*
     * nice paint method..
     */
    private void paint ()
    {
        julius.draw_julius(pbact, xmin, xmax, ymin, ymax);

        top = !top;

        try
        {
            if (top)
            {
                img1.set_from_pixbuf (pbact);
                actor_fade (img1, Fades.IN, DEFAULT_FADE_TIME);
                actor_fade (img2, Fades.OUT, DEFAULT_FADE_TIME);
            }
            else
            {
                img2.set_from_pixbuf (pbact);
                actor_fade (img2, Fades.IN, DEFAULT_FADE_TIME);
                actor_fade (img1, Fades.OUT, DEFAULT_FADE_TIME);
            }
        }
        catch (GLib.Error e)
        {
            Gtk.MessageDialog msg = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL,
                    Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "Can't draw on canvas");
            msg.response.connect ((response_id) =>
            {
                msg.destroy();
            });
            msg.show();
        }
    }

    /*
     * simple paint method
     */
    private void paint_simple ()
    {
        julius.draw_julius(pbact, xmin, xmax, ymin, ymax);

        try
        {
            if (top)
            {
                img1.set_from_pixbuf (pbact);
            }
            else
            {
                img2.set_from_pixbuf (pbact);
            }
        }
        catch (GLib.Error e)
        {
            Gtk.MessageDialog msg = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL,
                    Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "Can't draw on canvas");
            msg.response.connect ((response_id) =>
            {
                msg.destroy();
            });
            msg.show();
        }
    }

    /*
     * Do fade animation on the actor.
     * a actor to animate
     * f direction of the animation
     * time run time
     */
    private void actor_fade (Clutter.Actor a, Fades f, int time)
    {
        a.save_easing_state ();
        a.set_easing_mode (Clutter.AnimationMode.EASE_IN_CUBIC);
        a.set_easing_duration (time);

        if (f == Fades.IN)
        {
            a.set_opacity (255); // show
        }
        else if (f == Fades.OUT)
        {
            a.set_opacity (0); // hide
        }

        a.restore_easing_state ();
    }

    /*
     * Save file handler
     */
    private void on_save_clicked ()
    {
        var file_chooser = new FileChooserDialog ("Save file", this,
                FileChooserAction.SAVE,
                "Cancel", ResponseType.CANCEL,
                "Save", ResponseType.ACCEPT);

        if (file_chooser.run () == ResponseType.ACCEPT)
        {
            try
            {
                pbact.save (file_chooser.get_filename (), "png");
            }
            catch (GLib.Error e)
            {
                Gtk.MessageDialog msg = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL,
                        Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "Can't write to file");
                msg.response.connect ((response_id) =>
                {
                    msg.destroy();
                });
                msg.show();
            }
        }
        file_chooser.destroy ();
    }

    static int main (string[] args)
    {
        Gtk.init(ref args);
        if (GtkClutter.init (ref args) != Clutter.InitError.SUCCESS)
            return 1;

        var okno = new App ();
        okno.show_all ();

        Gtk.main ();

        return 0;
    }
}
