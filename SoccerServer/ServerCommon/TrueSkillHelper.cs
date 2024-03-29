﻿using Moserware.Skills;

namespace ServerCommon
{
    public class TrueSkillHelper
    {
        //
        // http://dl.dropbox.com/u/1083108/Moserware/Skill/The%20Math%20Behind%20TrueSkill.pdf
        //
        public const double INITIAL_MEAN = 25.0;
        public const double INITIAL_SD = INITIAL_MEAN / 3;

        const double BETA = 10;                             // Distancia entre los 80%-20% (en cadena)
        const double DYNAMIC_FACTOR = INITIAL_MEAN / 100;   // Volatilidad de subida / bajada
        const double DRAW = 0.3;
        const double CONSERVATIVE_FACTOR = 3;

        public const double CUTOFF = 20;                           // Valor a partir del cual no queremos considerar el partido matchmakingable
        public const double MULTIPLIER = 100;                      // Para mostrarlo al usuario, multiplicamos el MyConservative        

        static public bool IsJustResult(Rating ratingPlayer1, Rating ratingPlayer2, int goalsPlayer1, int goalsPlayer2)
        {
            bool bRet = true;

            if (goalsPlayer1 > goalsPlayer2)
            {
                if (MyConservativeTrueSkill(ratingPlayer1) - MyConservativeTrueSkill(ratingPlayer2) > CUTOFF)
                    bRet = false;
            }
            else
                if (goalsPlayer1 < goalsPlayer2)
                {
                    if (MyConservativeTrueSkill(ratingPlayer2) - MyConservativeTrueSkill(ratingPlayer1) > CUTOFF)
                        bRet = false;
                }

            return bRet;
        }

        static public double MyConservativeTrueSkill(Rating player)
        {
            return player.Mean - (CONSERVATIVE_FACTOR * player.StandardDeviation);
        }

        static public void RecomputeRatings(ref Rating ratingPlayer1, ref Rating ratingPlayer2, int goalsPlayer1, int goalsPlayer2)
        {
            var calculator = new Moserware.Skills.TrueSkill.TwoPlayerTrueSkillCalculator();

            var player1 = new Moserware.Skills.Player(1);
            var player2 = new Moserware.Skills.Player(2);

            var team1 = new Moserware.Skills.Team(player1, ratingPlayer1);
            var team2 = new Moserware.Skills.Team(player2, ratingPlayer2);

            var gameInfo = new Moserware.Skills.GameInfo(INITIAL_MEAN, INITIAL_SD, BETA, DYNAMIC_FACTOR, DRAW);

            int rankingPlayer1 = 1;
            int rankingPlayer2 = 1;

            if (goalsPlayer1 > goalsPlayer2)
            {
                rankingPlayer1 = 1;
                rankingPlayer2 = 2;
            }
            else if (goalsPlayer1 < goalsPlayer2)
            {
                rankingPlayer1 = 2;
                rankingPlayer2 = 1;
            }

            var newRatings = calculator.CalculateNewRatings(gameInfo, Moserware.Skills.Teams.Concat(team1, team2), rankingPlayer1, rankingPlayer2);

            ratingPlayer1 = newRatings[player1];
            ratingPlayer2 = newRatings[player2];

            if (MyConservativeTrueSkill(ratingPlayer1) < 0)
                ratingPlayer1 = new Rating(ratingPlayer1.StandardDeviation * CONSERVATIVE_FACTOR, ratingPlayer1.StandardDeviation);

            if (MyConservativeTrueSkill(ratingPlayer2) < 0)
                ratingPlayer2 = new Rating(ratingPlayer2.StandardDeviation * CONSERVATIVE_FACTOR, ratingPlayer2.StandardDeviation);
        }
    }
}
