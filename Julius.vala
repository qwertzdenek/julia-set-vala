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
    private const int num = 44;
    private const float thresh = 16.0f;

    public double cx = -0.70176;
    public double cy = -0.3842;
    
    public uint8 r = 220;
    public uint8 g = 230;
    public uint8 b = 240;

    public int julia_count(double x, double y)
    {
        int count = 0;
        double fsq = 0.0;
        double tmp;

        while (count < num && fsq < thresh)
        {
            tmp = x;
            x = x * x - y * y + cx;
            y = 2 * tmp * y + cy;
            fsq = x * x + y * y;
            count++;
        }

        return count;
    }

    public void draw_julius(Gdk.Pixbuf pb, double xmin, double xmax, double ymin, double ymax)
    {
        // clean up Pixbuf
        pb.fill ((uint32) 0x000000ff);

        int w = pb.get_width();
        int h = pb.get_height();

        int count;
        double x, y;

        unowned uint8 *pixels = pb.get_pixels();
        int rowstride = pb.get_rowstride();
        uint8 *p;

        for (int i = 0; i < h; ++i)
        {
            y = ymin + (ymax - ymin) * i / (h - 1);
            for (int j = 0; j < w; ++j)
            {
                x = xmin + (xmax - xmin) * j / (w - 1);

                count = julia_count(x, y);

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
