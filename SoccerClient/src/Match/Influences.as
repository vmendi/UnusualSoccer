package Match
{
	
	public final class Influences
	{
		static private function ShowAllInfluences() : void
		{
			var _Game : Game = MatchMain.Ref.Game;
			var _CurTeam : Team = _Game.CurrTeam;
			
			// Mostramos todas las influencias de pase al pie
			var friendCaps:Array = _Game.CurrTeam.CapsList;
			for each (var friend:Cap in friendCaps)
			{
				friend.SetInfluenceAspect(Enums.FriendColor, Cap.CapRadius + Ball.BallRadius + _CurTeam.RadiusPase);
				friend.ShowInfluence = true;
			}				
			
			// Mostramos todas las influencias de robo
			var enemyTeam:Team = _CurTeam.Opponent();
			var enemyCaps:Array = enemyTeam.CapsList;
			
			for each (var enemy:Cap in enemyCaps)
			{
				enemy.SetInfluenceAspect(Enums.EnemyColor, Cap.CapRadius + Ball.BallRadius + enemyTeam.RadiusSteal);
				enemy.ShowInfluence = true;
			}
		}
				
		//
		// Muestra los areas de influencia de las chapas que están en el radio de la pelota
		//
		static public function UpdateInfluences(remainingHits : int, remainingPasesAlPie : int) : void
		{
			var _Game : Game = MatchMain.Ref.Game; 
			var _CurTeam : Team = _Game.CurrTeam;
			
			// Determinamos si debemos mostrar "TODAS" las influencias (si el jugador local tiene la habilidad de mostrar radios)
			if (_CurTeam.IsUsingSkill(Enums.Verareas) && _CurTeam.IsLocalUser)
			{
				ShowAllInfluences();
				return;
			}
			
			// Si los subturnos o los pases al pie estan agotados, no mostramos ninguna influencia amiga.
			// Además, el pase al pie sólo empieza a ser posible cuando la chapa que lanza ha tocado la pelota.
			if (remainingHits != 0 && remainingPasesAlPie != 0 && _Game.TheGamePhysics.HasTouchedBall(_Game.TheGamePhysics.AttackingTeamShooterCap))
			{
				var potential:Array = _CurTeam.GetPotentialPaseAlPieForShooter(_Game.TheGamePhysics.AttackingTeamShooterCap);
				
				for each (var friend:Cap in potential)
				{
					friend.SetInfluenceAspect(Enums.FriendColor, Cap.CapRadius + Ball.BallRadius + _CurTeam.RadiusPase);
					friend.ShowInfluence = true;
				}
				
				// Apagamos inmediatamente las q ya no son potenciales
				for each(friend in _CurTeam.CapsList)
				{
					if (friend.ShowInfluence && potential.indexOf(friend) == -1)
						friend.ShowInfluence = false;
				}
			}
			
			// Mostramos las chapas enemigas que podrían robar la pelota o sobre las que podríamos perder la pelota
			// Si ninguna de nuestras chapas ha tocado la pelota, no se produce la perdida, asi que tampoco pintamos el area
			if (_Game.TheGamePhysics.HasTouchedBallAny(_CurTeam))
			{
				var enemyTeam:Team = _CurTeam.Opponent();
				var enemyCaps:Array = enemyTeam.GetCapsInsideCircle(_Game.TheBall.GetPos(), Cap.CapRadius + Ball.BallRadius + enemyTeam.RadiusSteal);
				
				for each (var enemy:Cap in enemyCaps)
				{
					enemy.SetInfluenceAspect(Enums.EnemyColor, Cap.CapRadius + Ball.BallRadius + enemyTeam.RadiusSteal);
					enemy.ShowInfluence = true;
				}
				
				for each(enemy in enemyTeam.CapsList )
				{
					if (enemy.ShowInfluence && enemyCaps.indexOf(enemy) == -1)
						enemy.ShowInfluence = false;
				}
			}
		}
	}
}