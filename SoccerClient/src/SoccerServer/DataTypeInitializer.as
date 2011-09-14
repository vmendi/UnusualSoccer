/*****************************************************************
*
*  To force the compiler to include all the generated complex types
*  into the compiled application, add the following line of code 
*  into the main function of your Flex application:
*
*  new SoccerServer.DataTypeInitializer();
*
******************************************************************/

package SoccerServer
{
	import SoccerServer.TransferModel.vo.TeamMatchStats;
	import SoccerServer.TransferModel.vo.PredefinedTeam;
	import SoccerServer.TransferModel.vo.RankingPage;
	import SoccerServer.TransferModel.vo.RankingTeam;
	import SoccerServer.TransferModel.vo.TeamDetails;
	import SoccerServer.TransferModel.vo.Team;
	import SoccerServer.TransferModel.vo.Ticket;
	import SoccerServer.TransferModel.vo.PendingTraining;
	import SoccerServer.TransferModel.vo.TrainingDefinition;
	import SoccerServer.TransferModel.vo.SoccerPlayer;
	import SoccerServer.TransferModel.vo.SpecialTraining;
	import SoccerServer.TransferModel.vo.SpecialTrainingDefinition;
	
	public class DataTypeInitializer
	{
		public function DataTypeInitializer()
		{
			new SoccerServer.TransferModel.vo.TeamMatchStats();	
			new SoccerServer.TransferModel.vo.PredefinedTeam();	
			new SoccerServer.TransferModel.vo.RankingPage();	
			new SoccerServer.TransferModel.vo.RankingTeam();	
			new SoccerServer.TransferModel.vo.TeamDetails();	
			new SoccerServer.TransferModel.vo.Team();	
			new SoccerServer.TransferModel.vo.Ticket();	
			new SoccerServer.TransferModel.vo.PendingTraining();	
			new SoccerServer.TransferModel.vo.TrainingDefinition();	
			new SoccerServer.TransferModel.vo.SoccerPlayer();	
			new SoccerServer.TransferModel.vo.SpecialTraining();	
			new SoccerServer.TransferModel.vo.SpecialTrainingDefinition();	
		}
	}  
}  
