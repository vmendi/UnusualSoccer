using System;
using System.Linq;
using System.Web;
using ServerCommon;
using ServerCommon.BDDModel;
using NLog;
using System.Diagnostics;


namespace HttpService
{
	public partial class MainService
	{
        private static readonly Logger Log = LogManager.GetLogger(typeof(MainService).FullName);
        private static readonly Logger LogPerf = LogManager.GetLogger(typeof(MainService).FullName + ".Perf");

        private SoccerDataModelDataContext CreateDataForRequest()
        {
            mContext = new SoccerDataModelDataContext();

            var sessionKey = GetSessionKeyFromRequest();

            mPlayer = (from s in mContext.Sessions
                       where s.FacebookSession == sessionKey
                       select s.Player).FirstOrDefault();

            if (mPlayer == null)
                throw new Exception("Invalid SessionKey: " + sessionKey);

            return mContext;
        }

        private string GetSessionKeyFromRequest()
        {
            HttpContext theCurrentHttp = HttpContext.Current;

            if (!theCurrentHttp.Request.QueryString.AllKeys.Contains("SessionKey"))
                throw new Exception("SessionKey is missing");

            return theCurrentHttp.Request.QueryString["SessionKey"];
        }

		public enum VALID_NAME
		{
			VALID,
            DUPLICATED,
			INAPPROPIATE,
			TOO_SHORT,
			WHITE_SPACE_TRIM,
			TOO_MANY_WHITESPACES,
			EMPTY
		}

		public bool HasTeam()
		{
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            bool bRet = false;

            using (mContext = new SoccerDataModelDataContext())
            {
                bRet = PrecompiledQueries.HasTeam.GetTeam.Invoke(mContext, GetSessionKeyFromRequest()) != null;
            }

            LogPerf.Info("HasTeam: " + ProfileUtils.ElapsedMicroseconds(stopwatch));

            return bRet;
		}

        public VALID_NAME ChangeName(string newName)
        {
            var ret = VALID_NAME.VALID;

            using (CreateDataForRequest())
            {
                if ((ret = IsNameValidInner(newName)) == VALID_NAME.VALID)
                {
                    mPlayer.Team.Name = newName;
                    mContext.SubmitChanges();
                }
            }

            return ret;
        }
                
		public VALID_NAME IsNameValid(string name)
		{
            using (CreateDataForRequest())
            {
                return IsNameValidInner(name);
            }
		}

        private VALID_NAME IsNameValidInner(string name)
        {
            VALID_NAME ret = VALID_NAME.VALID;

            if (name == "")
                ret = VALID_NAME.EMPTY;
            else
            if (name.Length <= 3)
                ret = VALID_NAME.TOO_SHORT;
            else
            if (IsNameInappropiate(name))
                ret = VALID_NAME.INAPPROPIATE;
            else
            if (HasNameWhitespacesAtStartOrEnd(name))
                ret = VALID_NAME.WHITE_SPACE_TRIM;
            else
            if (HasTooManyWhitespaces(name))
                ret = VALID_NAME.TOO_MANY_WHITESPACES;
            else
            {
                bool dup = (from t in mContext.Teams
                            where t.Name == name
                            select t).Count() > 0;
                if (dup)
                    ret = VALID_NAME.DUPLICATED;
            }
            
            return ret;
        }

		static private bool HasNameWhitespacesAtStartOrEnd(string name)
		{
			return name.StartsWith(" ") || name.EndsWith(" ");
		}

		static private bool HasTooManyWhitespaces(string name)
		{
            return name.Count(theChar => theChar == ' ') > 3;
		}

		static private bool IsNameInappropiate(string name)
		{
			String[] PROFANE_WORDS = { "puta", "puto", "coño", "coña", "conyo", "caca", "mierda", "joder", 
									   "gilipollas", "polla", "culo", "imbecil", "idiota", "tonto", "tonta",
									   "estupido", "estupida", };

			name = name.ToLower();
			name = name.Replace("á", "a");
			name = name.Replace("é", "e");
			name = name.Replace("í", "i");
			name = name.Replace("ó", "o");
			name = name.Replace("ú", "u");

			name = name.Replace("à", "a");
			name = name.Replace("è", "e");
			name = name.Replace("ì", "i");
			name = name.Replace("ò", "o");
			name = name.Replace("ù", "u");

			return PROFANE_WORDS.Any(word => name.Contains(word));
		}
		
		static private string PlayerToString(Player player)
		{
			return "Name: " + player.Name + " " + player.Surname + " FacebookID: " + player.FacebookID;
		}

		public void OnError(string msg)
		{
			Log.Error("CLIENT_ERROR:" + msg);
		}

		public int OnLiked()
		{
            // El mismo entrenamiento se ocupara de submitear cambios. La habilidad 1 tiene todos los requerimientos a 0, por lo que esta sola
            // llamada provocara su consecucion.
            TrainSpecial(1);
         
			return 1;
		}

		SoccerDataModelDataContext mContext = null;
		Player mPlayer = null;
	}
}