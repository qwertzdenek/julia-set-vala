/*
 * Julius.vala
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

class Julius
{
    // *** Attributes ***

    /* count of iterations */
    private const float thresh = 16.0f;

	  public const int num = 44;

    /* actual complex constant F(z) = z^2 + c */
    public double cx = -0.70176;
    public double cy = -0.3842;

    /* basic color */
    public uint8 r = 220;
    public uint8 g = 230;
    public uint8 b = 240;

    /*
     * Draws Julia set
     * pb buffer to write to
     * .. fractal window
     */
    public void draw_julius(Gdk.Pixbuf pb, double xmin, double xmax, double ymin, double ymax, int level)
    {
        // clean up Pixbuf
        //pb.fill ((uint32) 0x000000ff);

        int w = pb.get_width();
        int h = pb.get_height();

        int count;
        double x, y;
        double zx, zy;
        double zx2, zy2;
        double fsq;

        unowned uint8 *pixels = pb.get_pixels();
        int rowstride = pb.get_rowstride();
        uint8 *p;

        double dx = (xmax - xmin) / (w - 1);
        double dy = (ymax - ymin) / (h - 1);

        y = ymin;
        for (int i = 0; i < h; ++i)
        {
            x = xmin;
            for (int j = 0; j < w; ++j)
            {
                // Julia count
                count = 0;
                fsq = 0.0;
                zx = x;
                zy = y;

                while (count < num && fsq < thresh)
                {
                    zx2 = zx * zx; // optimalisation
                    zy2 = zy * zy;
                    fsq = zx2 + zy2;
                    zy = 2.0 * zx * zy + cy;
                    zx = zx2 - zy2 + cx;
                    count++;
                }

                // draw pixel
                p = pixels + i * rowstride + j * 4;
                
                if (count == level)
                {
					p[0] = r;
					p[1] = g;
					p[2] = b;
					p[3] = 255;
				}
				else
				{
					p[0] = 0;
					p[1] = 0;
					p[2] = 0;
					p[3] = 255;
				}
                    
                x += dx;
            }

            y += dy;
        }
    }
}
