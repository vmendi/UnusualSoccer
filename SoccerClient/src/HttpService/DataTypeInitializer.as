/*****************************************************************
*
*  To force the compiler to include all the generated complex types
*  into the compiled application, add the following line of code 
*  into the main function of your Flex application:
*
*  new HttpService.DataTypeInitializer();
*
******************************************************************/

package HttpService
{
	import HttpService.TransferModel.vo.CompetitionGroup;
	import HttpService.TransferModel.vo.CompetitionGroupEntry;
	import HttpService.TransferModel.vo.TeamMatchStats;
	import HttpService.TransferModel.vo.RankingPage;
	import HttpService.TransferModel.vo.RankingTeam;
	import HttpService.TransferModel.vo.SpecialTrainingDefinition;
	import HttpService.TransferModel.vo.Team;
	import HttpService.TransferModel.vo.Ticket;
	import HttpService.TransferModel.vo.PendingTraining;
	import HttpService.TransferModel.vo.TrainingDefinition;
	import HttpService.TransferModel.vo.SoccerPlayer;
	import HttpService.TransferModel.vo.SpecialTraining;
	import HttpService.TransferModel.vo.TeamDetails;
	
	public class DataTypeInitializer
	{
		public function DataTypeInitializer()
		{
			new HttpService.TransferModel.vo.CompetitionGroup();	
			new HttpService.TransferModel.vo.CompetitionGroupEntry();	
			new HttpService.TransferModel.vo.TeamMatchStats();	
			new HttpService.TransferModel.vo.RankingPage();	
			new HttpService.TransferModel.vo.RankingTeam();	
			new HttpService.TransferModel.vo.SpecialTrainingDefinition();	
			new HttpService.TransferModel.vo.Team();	
			new HttpService.TransferModel.vo.Ticket();	
			new HttpService.TransferModel.vo.PendingTraining();	
			new HttpService.TransferModel.vo.TrainingDefinition();	
			new HttpService.TransferModel.vo.SoccerPlayer();	
			new HttpService.TransferModel.vo.SpecialTraining();	
			new HttpService.TransferModel.vo.TeamDetails();	
		}
	}  
}  