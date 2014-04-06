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
    private const int num = 44;
    private const float thresh = 16.0f;

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
    public void draw_julius(Gdk.Pixbuf pb, double xmin, double xmax, double ymin, double ymax)
    {
        // clean up Pixbuf
        pb.fill ((uint32) 0x000000ff);

        int w = pb.get_width();
        int h = pb.get_height();

        int count;
        double x, y;
        double x2, y2;
        double fsq = 0.0;
        double tmp;

        unowned uint8 *pixels = pb.get_pixels();
        int rowstride = pb.get_rowstride();
        uint8 *p;

        for (int i = 0; i < h; ++i)
        {
            y = ymin + (ymax - ymin) * i / (h - 1);
            for (int j = 0; j < w; ++j)
            {
                x = xmin + (xmax - xmin) * j / (w - 1);

                // Julia count
                count = 0;
                fsq = 0.0;

                while (count < num && fsq < thresh)
                {
                    x2 = x * x; // optimalisation
                    y2 = y * y;
                    x = x2 - y2 + cx;
                    y = 2 * x * y + cy;
                    fsq = x2 + y2;
                    count++;
                }

                // draw pixel
                p = pixels + i * rowstride + j * 4;
                if (count == num)
                {
                    p[0] = 0;
                    p[1] = 0;
                    p[2] = 0;
                    p[3] = 255;
                }
                else
                {
                    uint8 bg = bg_color(j, i, w, h);
                    double k = (double) count / num;

                    p[0] = App.lerp_u(1-Math.sqrt(k), bg, r);
                    p[1] = App.lerp_u(1-k, bg, g);
                    p[2] = App.lerp_u(k*k, bg, b);
                    p[3] = 255;
                }
            }
        }
    }

    /*
     * Calculate background color depending on coordinates
     * x, y coordinates
     * max, min of the canvas (maximum x and y respectively)
     */
    private uint8 bg_color(int x, int y, int maxx, int maxy)
    {
        int centerx = maxx / 2;
        int centery = maxy / 2;
        int maxd = centerx * centerx + centery * centery;

        int dx = x - centerx;
        int dy = y - centery;

        int dist = (dx * dx + dy* dy)*255;

        return (uint8) (255 - dist / maxd);
    }
}
