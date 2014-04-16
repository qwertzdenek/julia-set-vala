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

class App : Gtk.Window
{
    // *** Constants ***

    /* Default animation time */
    private const int DEFAULT_FADE_TIME = 1000;
    private const int MIN_LEVEL = 4;

    /* Fractal window */
    private const double DEFAULT_XMIN = -1.6;
    private const double DEFAULT_XMAX = 1.6;
    private const double DEFAULT_YMIN = -1.2;
    private const double DEFAULT_YMAX = 1.2;

    // *** Attributes ***

    /* click position last occured */
    private double start_x;
    private double start_y;

    /* fractal ranges */
    private double xmax = DEFAULT_XMAX;
    private double xmin = DEFAULT_XMIN;
    private double ymax = DEFAULT_YMAX;
    private double ymin = DEFAULT_YMIN;

    /* indicates fractal level */
    private int level = MIN_LEVEL;

    /* drawing area for animation */
    private Gtk.Image img;
    
    private Gtk.SpinButton spin;

    /* Image buffer */
    private Gdk.Pixbuf pbact;

    /* used julius object */
    public Julius julius;

    // *** Enums ***

    enum Fades
    {
        IN, OUT
    }

	// *** Methods ***
	
    public App ()
    {
        this.title = "Aplikace";
        this.window_position = WindowPosition.CENTER;
        this.set_default_size (800, 600);
        this.destroy.connect (Gtk.main_quit);

        julius = new Julius();

        HeaderBar hb = new HeaderBar ();
        hb.set_show_close_button (true);
        hb.set_title ("Juliova množina");
        this.set_titlebar (hb);
        
        
        Gtk.Button save_button = new Gtk.Button.from_icon_name ("document-save", Gtk.IconSize.BUTTON);
        save_button.clicked.connect (on_save_clicked);
        hb.pack_start (save_button);

        // refresh button
        Gtk.Button refresh = new Gtk.Button.from_icon_name ("view-refresh", Gtk.IconSize.BUTTON);
        refresh.clicked.connect (() =>
        {
            xmax = DEFAULT_XMAX;
            xmin = DEFAULT_XMIN;
            ymax = DEFAULT_YMAX;
            ymin = DEFAULT_YMIN;
		        level = MIN_LEVEL;
		        spin.set_value (MIN_LEVEL);
			
            paint();
        });
        hb.pack_start (refresh);

        // presets button
        Gtk.Button presets_button = new Gtk.Button.from_icon_name ("insert-image", Gtk.IconSize.BUTTON);
        presets_button.clicked.connect (() =>
        {
            var presets = new Presets (this);
            if (presets.run () == ResponseType.ACCEPT)
            {
                unowned Presets.Fractal res = presets.get_fractal ();
                julius.cx = res.x;
                julius.cy = res.y;
                xmax = DEFAULT_XMAX;
                xmin = DEFAULT_XMIN;
                ymax = DEFAULT_YMAX;
                ymin = DEFAULT_YMIN;
                level = MIN_LEVEL;
                spin.set_value (MIN_LEVEL);
                
                paint ();
            }
            presets.destroy ();
        });
        hb.pack_end (presets_button);

        // theme button
        Gtk.Button theme_button = new Gtk.Button.from_icon_name ("preferences-desktop-theme", Gtk.IconSize.BUTTON);
        theme_button.clicked.connect (() =>
        {
            Gtk.ColorChooserDialog chooser = new Gtk.ColorChooserDialog ("Vyberte barvu", this);
            if (chooser.run () == Gtk.ResponseType.OK)
            {
                julius.r = (uint8) (chooser.rgba.red * 255);
                julius.g = (uint8) (chooser.rgba.green * 255);
                julius.b = (uint8) (chooser.rgba.blue * 255);
                paint ();
            }
            chooser.close ();
        });
        hb.pack_end (theme_button);
        
        spin = new Gtk.SpinButton.with_range (MIN_LEVEL, Julius.num, 1);
        spin.value_changed.connect (() => {
		    	int val = spin.get_value_as_int ();
			    level = val;
			    
			    paint ();
		    });
        hb.pack_start (spin);
        
        img = new Gtk.Image ();
        
        Gtk.EventBox eb = new EventBox ();
        eb.add (img);
        
        eb.set_events (Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK);
        eb.size_allocate.connect (on_size_allocate);
        eb.button_press_event.connect (button_press);
        eb.button_release_event.connect (button_release);

        this.add (eb);
    }
    
    /*
     * button press handler
     */
    private bool button_press (Gdk.EventButton event)
    {
		  if (event.button == 1) // left button
	  	{
	  		start_x = event.x;
	  		start_y = event.y;
	   	}
	  	else if (event.button == 3) // right button
		  {
		  	level = int.min (++level, Julius.num);
		  	spin.set_value (level);
		  	
		  	paint();
		  }

      return true;
    }

    /*
     * button release handler
     */
    private bool button_release (Gdk.EventButton event)
    {
    if (event.button == 1) // left button
	  	{
	  		// Compute new fractal min max values
        int w = pbact.get_width();
        int h = pbact.get_height();
        
        double end_x = event.x;
        double end_y = event.y;
        
        double kxmin = double.min(start_x, end_x) / w;
        double nxmin = lerp(kxmin, xmin, xmax);

        double kxmax = double.max(start_x, end_x) / w;
        double nxmax = lerp(kxmax, xmin, xmax);

        double kymin = double.min(start_y, end_y) / h;
        double nymin = lerp(kymin, ymin, ymax);

        double kymax = double.max(start_y, end_y) / h;
        double nymax = lerp(kymax, ymin, ymax);
        
        xmin = nxmin;
        xmax = nxmax;
        ymin = nymin;
        ymax = nymax;

        paint();
	   	}
        
        return true;
    }


    /*
     * Window size change handler
     */
    private void on_size_allocate (Allocation a)
    {
        pbact = new Gdk.Pixbuf (Gdk.Colorspace.RGB, true, 8, (int) a.width, (int) a.height);
        
        paint ();
    }

    /*
     * linear interpolation between two scalars by k
     */
    public static double lerp (double k, double a, double b)
    {
        return a + k * (b - a);
    }

    /*
     * nice paint method..
     */
    private void paint ()
    {
        julius.draw_julius(pbact, xmin, xmax, ymin, ymax, level);
        
		    img.set_from_pixbuf (pbact);
    }

    /*
     * Save file handler
     */
    private void on_save_clicked ()
    {
        var file_chooser = new FileChooserDialog ("Uložit soubor", this,
                FileChooserAction.SAVE,
                "Zrušit", ResponseType.CANCEL,
                "Uložit", ResponseType.ACCEPT);

        if (file_chooser.run () == ResponseType.ACCEPT)
        {
            try
            {
                pbact.save (file_chooser.get_filename (), "png");
            }
            catch (GLib.Error e)
            {
                Gtk.MessageDialog msg = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL,
                        Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "Nemohu zapsat do souboru");
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

        var okno = new App ();
        okno.show_all ();

        Gtk.main ();

        return 0;
    }
}
