using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;

namespace SoccerServer
{
    public class SaveJPG : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "text/plain";
            
            string uploadDir =  context.Server.MapPath("~") + "logs\\";
            string folder = context.Request.QueryString["folder"];

            if (folder != null)
            {
                string destDir = uploadDir + folder;

                if (!Directory.Exists(destDir))
                    Directory.CreateDirectory(destDir);

                // Because we name them by number, we search for the existing one with largest number
                var filesInDir = Directory.EnumerateFiles(destDir);
                int max = -1;
                
                if (filesInDir.Count() > 0)
                    max = filesInDir.Max(fileName =>
                    {
                        int ret = -1;
                        Int32.TryParse(Path.GetFileNameWithoutExtension(fileName), out ret);
                        return ret;
                    });

                Image theImage = Bitmap.FromStream(context.Request.InputStream);
                theImage.Save(Path.Combine(destDir, (max + 1).ToString() + ".jpg"), ImageFormat.Jpeg);
            }
        }

        public bool IsReusable { get { return true; } }
    }
}