using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Drawing;
namespace refImpl {
    class top:Form {
        PictureBox b;
        Bitmap bm;
        int pixX = 1920;
        int pixY = 1080;
#if true
        float x1 = -2*1920f / 1080f;
        float x2 = 2*1920f / 1080f;
        float y1 = -2;
        float y2 = 2;
#else
        float x1 = -0.654f; float y1 = 0.585f; float x2 = -0.48f; float y2 = 0.69f;

#endif
        public top() {

            this.SuspendLayout();
            this.b = new PictureBox();

            bm = new Bitmap(pixX, pixY);
            b.Image = bm;

            b.Width = (int)b.Image.PhysicalDimension.Width;
            b.Height = (int)b.Image.PhysicalDimension.Height;
            b.Location = new Point(0, 0);
            //pb.Click += closeCallback2;
            b.BackColor = Color.Transparent;

            this.Controls.Add(this.b);
            this.ClientSize = new System.Drawing.Size((int)b.Image.PhysicalDimension.Width, (int)b.Image.PhysicalDimension.Height);

            this.ResumeLayout();
            this.MouseWheel += this.Top_MouseWheel;
            b.MouseDown += this.Top_MouseClick;
            this.redraw();
        }

        void redraw() {
            int maxIter = 40;

#if true
            float maxXx = 0;
            float maxYy = 0;
            float maxXy = 0;
            float maxSum = 0;

            float dx = (x2 - x1) / (float)(pixX - 1);
            float dy = (y2 - y1) / (float)(pixY - 1);
            float yf = y1;
            for(int y = 0; y < pixY; ++y) {
                float xf = x1;
                for(int x = 0; x < pixX; ++x) {
                    float fracX = xf;
                    float fracY = yf;
                    int iter = 0;
                    while(iter < maxIter) {
                        float xx = fracX * fracX;
                        float yy = fracY * fracY;
                        float xy = fracX * fracY;
                        maxXx = Math.Max(xx, maxXx);
                        maxYy = Math.Max(yy, maxYy);
                        maxXy = Math.Max(xy, maxXy);
                        maxSum = Math.Max(xx+yy, maxSum);

                        if(xx + yy > 4) break;
                        fracX = xx - yy + xf;
                        fracY = 2 * xy + yf;
                        ++iter;
                    }
                    bm.SetPixel(x, y, iter % 2 == 0 ? Color.Black : Color.White);
                    xf += dx;
                } // for x
                yf += dy;
            } // for y
           // Console.WriteLine(maxXx + "\t" + maxYy + "\t" + maxXy + "\t" + maxSum);
#else
            int nFracBits = 13;
            float float2frac = (float)Math.Pow(2, nFracBits);
            int dx = (int)((x2 - x1) / (float)(pixX - 1) * float2frac);
            int dy = (int)((y2 - y1) / (float)(pixY - 1) * float2frac);

            int yf = (int)(float2frac * y1);
            for(int y = 0; y < pixY; ++y) {
                int xf = (int)(float2frac * x1);
                for(int x = 0; x < pixX; ++x) {
                    if((x == 320 && y == 240))
                        Console.WriteLine();
                    int fracX = xf;
                    int fracY = yf;
                    int iter = 0;
                    while(iter < maxIter) {
                        Int64 xx = (Int64)fracX * (Int64)fracX;
                        Int64 yy = (Int64)fracY * (Int64)fracY;
                        Int64 xy = (Int64)fracX * (Int64)fracY;
                        Int64 leftSide = ((xx + yy) >> nFracBits);
                        Int64 rightSide = (4 << nFracBits);
                        if(leftSide> rightSide) break;
                        fracX = (int)((xx - yy) >> nFracBits) + xf;
                        fracY = (int)((2 * xy) >> nFracBits) + yf;
                        ++iter;
                    }
                    bm.SetPixel(x, y, iter % 2 == 0 ? Color.Black : Color.White);
                    xf += dx;
                } // for x
                yf += dy;
            } // for y
#endif
        }

        private void Top_MouseWheel(object sender, MouseEventArgs e) {
            float f = 1.3f;
            if(e.Delta > 0)
                f = 1.0f / f;
            float mouseX = x1 + e.Location.X / ((float)pixX - 1) * (x2-x1);
            float mouseY = y1 + e.Location.Y / ((float)pixY - 1) * (y2-y1);

            x1 = mouseX + (x1 - mouseX) * f;
            y1 = mouseY + (y1 - mouseY) * f;
            x2 = mouseX + (x2 - mouseX) * f;
            y2 = mouseY + (y2 - mouseY) * f;

            redraw();
            this.Invalidate();
        }

        private void Top_MouseClick(object sender, MouseEventArgs e) {
            Console.WriteLine(String.Format("{0:F12}\t{1:F12}\t{2:F12}\t{3:F12}", x1, y1, x2, y2));
        }
    }

    static class Program {
        [STAThread]
        static void Main() {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new top());
        }
    }
}
