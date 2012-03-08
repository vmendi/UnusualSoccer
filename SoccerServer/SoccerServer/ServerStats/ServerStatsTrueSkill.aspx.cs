using System;
using Moserware.Skills;
using ServerCommon;

namespace SoccerServer.ServerStats
{
    public partial class ServerStatsTrueSkill : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            Rating ratingPlayer1 = new Rating(TrueSkillHelper.INITIAL_MEAN, TrueSkillHelper.INITIAL_SD);
            Rating ratingPlayer2 = new Rating(TrueSkillHelper.INITIAL_MEAN, TrueSkillHelper.INITIAL_SD);

            Rating reservePlayer = new Rating(TrueSkillHelper.INITIAL_MEAN, TrueSkillHelper.INITIAL_SD);

            Printa(ratingPlayer1, ratingPlayer2);

            /*
            for (int c = 0; c < 100; c++)
            {
                ratingPlayer2 = reservePlayer;

                for (int d = 0; d < 100; d++)
                {
                    if (IsJustResult(ratingPlayer1, ratingPlayer2, 1, 0))
                    {
                        RecomputeRatings(ref ratingPlayer1, ref ratingPlayer2, 1, 0);
                        Printa(ratingPlayer1, ratingPlayer2);
                    }
                    else
                    {
                        reservePlayer = new Rating(ratingPlayer1.Mean, ratingPlayer1.StandardDeviation);
                        d = 100; c = 100;
                    }
                }
            }

            //ratingPlayer2 = reservePlayer;

            for (int c = 0; c < 100; c++)
            {
                RecomputeRatings(ref ratingPlayer1, ref ratingPlayer2, 0, 1);
                Printa(ratingPlayer1, ratingPlayer2);
            }
             * */

            for (int c = 0; c < 10; c++)
            {
                for (int d = 0; d < 10; d++)
                {
                    if (!TrueSkillHelper.IsJustResult(ratingPlayer1, ratingPlayer2, 1, 0))
                        break;

                    TrueSkillHelper.RecomputeRatings(ref ratingPlayer1, ref ratingPlayer2, 1, 0);
                    Printa(ratingPlayer1, ratingPlayer2);
                }
                
                Rating swap = ratingPlayer1;
                ratingPlayer1 = ratingPlayer2;
                ratingPlayer2 = swap;
            }
        }

        private void Printa(Rating ratingPlayer1, Rating ratingPlayer2)
        {
            Response.Write(ratingPlayer1.ToString() + "<br/>");
            Response.Write(ratingPlayer2.ToString() + "<br/>");

            Response.Write(Math.Round(TrueSkillHelper.MyConservativeTrueSkill(ratingPlayer1)).ToString() + "<br/>");
            Response.Write(Math.Round(TrueSkillHelper.MyConservativeTrueSkill(ratingPlayer2)).ToString() + "<br/>");

            Response.Write("---------------------------------<br/>");
        }
    }
}