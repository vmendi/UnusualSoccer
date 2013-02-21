using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using ServerCommon;

namespace SoccerServer.OpenGraph
{
    public class OpenGraph : IHttpHandler
    {
        // 0 = namespace
        // 1 = app_id
        // 2 = object    (skill)
        // 3 = canvasUrl (http://canvas.unusualsoccer.com/)
        // 4 = post id of the object (SpecialSkill1)
        // 5 = title
        // 6 = description
        // 7 = Img path (Imgs/Reporter.png)
        static string htmlSrc = @"
            <head prefix=""og: http://ogp.me/ns# fb: http://ogp.me/ns/fb# unusualsoccer: http://ogp.me/ns/fb/{0}#"">
            <meta property=""fb:app_id""         content=""{1}"" />
            <meta property=""og:type""           content=""{0}:{2}"" /> 
            <meta property=""og:url""            content=""{3}/OpenGraph/OpenGraph.html?id={4}"" /> 
            <meta property=""og:title""          content=""{5}"" /> 
            <meta property=""og:description""    content=""{6}"" /> 
            <meta property=""og:image""          content=""{3}{7}"" /> 
            ";

        class PostParams
        {
            public string OpenGraphType;         // El tipo de Object creado con la tool online de Open Graph
            public string Title;
            public string Description;
            public string ImageUrl;

            public PostParams(string type, string title, string desc, string img)
            {
                OpenGraphType = type; Title = title; Description = desc; ImageUrl = img;
            }
        }

        static Dictionary<string, PostParams> AllPosts = new Dictionary<string, PostParams>()
            { {"SpecialSkill1", new PostParams("skill", "Super Power", "I just got a new skill: SUPER POWER!", "Imgs/MensajeHabilidadSuperpotencia_en_US.jpg")},
              {"SpecialSkill2", new PostParams("skill", "Super Control", "", "")},
              {"SpecialSkill3", new PostParams("skill", "Catenaccio", "", "")},
              {"SpecialSkill4", new PostParams("skill", "Long Shot", "", "")},
              {"SpecialSkill5", new PostParams("skill", "Extra Time", "", "")},
              {"SpecialSkill6", new PostParams("skill", "One More Shot", "", "")},
              {"SpecialSkill7", new PostParams("skill", "Easy Control", "", "")},
              {"SpecialSkill8", new PostParams("skill", "Reveal Areas", "", "")},
              {"SpecialSkill9", new PostParams("skill", "God's hand", "", "")},
              {"SpecialSkill12", new PostParams("skill", "Safe Goal", "", "")},
              {"SpecialSkill13", new PostParams("skill", "Master Dribbling", "", "")},

              {"WinMatch", new PostParams("match", "Match", "Victory!", "Imgs/MensajeVictoria_en_US.jpg")}
            };

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "text/html";

            string id = context.Request.QueryString["id"];

            if (id != null)
            {
                var thePostParams = AllPosts[id];

                if (thePostParams != null)
                {
                    string result = FormatOutput(id, thePostParams);
                    context.Response.Write(result);
                }
                else
                {
                    // TODO: Unknown id, log error
                }
            }
        }

        private string FormatOutput(string postID, PostParams thePostParams)
        {
            return String.Format(htmlSrc, GetNamespace(),
                                          GlobalConfig.FacebookSettings.AppId,
                                          thePostParams.OpenGraphType,
                                          GlobalConfig.FacebookSettings.CanvasUrl,
                                          postID,
                                          thePostParams.Title,
                                          thePostParams.Description,
                                          thePostParams.ImageUrl);
        }

        // Siempre se puede obtener el nombre del namespace a partir del de la aplicacion, parece que es lo mismo que FB hace
        private string GetNamespace()
        {
            string canvasPage = GlobalConfig.FacebookSettings.CanvasPage;

            // El formato siempre es: http://apps.facebook.com/unusualsoccerlocal/
            return canvasPage.Substring(canvasPage.LastIndexOf("/", canvasPage.Length-2)+1).TrimEnd('/');
        }

        public bool IsReusable
        {
            get
            {
                return true;    // No crear instancias del handler por cada request
            }
        }
    }
}