/*******************************************************************
* MainService.as
* Copyright (C) 2006-2010 Midnight Coders, Inc.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
* OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
* WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
********************************************************************/

    /***********************************************************************
    The generated code provides a simple mechanism for invoking methods
    on the HttpService.MainService class using WebORB. 
    You can add the code to your Flex Builder project and use the 
    class as shown below:

           import HttpService.MainService;
           import HttpService.MainServiceModel;

           [Bindable]
           var model:MainServiceModel = new MainServiceModel();
           var serviceProxy:MainService = new MainService( model );
           // make sure to substitute foo() with a method from the class
           serviceProxy.foo();
           
    Notice the model variable is shown in the example above as Bindable. 
    You can bind your UI components to the fields in the model object.
    ************************************************************************/
  
    package HttpService
    {
    import mx.rpc.remoting.RemoteObject;
    import mx.rpc.events.ResultEvent;
    import mx.rpc.events.FaultEvent;
    import mx.rpc.AsyncToken;
    import mx.rpc.IResponder;
    import mx.collections.ArrayCollection;

    
    import HttpService.TransferModel.vo.*;
        
    public class MainService
    {
      private var remoteObject:RemoteObject;
      private var model:MainServiceModel; 

      public function MainService( model:MainServiceModel = null )
      {
        remoteObject  = new RemoteObject("GenericDestination");
        remoteObject.source = "HttpService.MainService";
        
        remoteObject.AssignSkillPoints.addEventListener("result",AssignSkillPointsHandler);
        
        remoteObject.ChangeFormation.addEventListener("result",ChangeFormationHandler);
        
        remoteObject.ChangeName.addEventListener("result",ChangeNameHandler);
        
        remoteObject.CreateRequests.addEventListener("result",CreateRequestsHandler);
        
        remoteObject.CreateTeam.addEventListener("result",CreateTeamHandler);
        
        remoteObject.GetExtraRewardForMatch.addEventListener("result",GetExtraRewardForMatchHandler);
        
        remoteObject.GetItemForSale.addEventListener("result",GetItemForSaleHandler);
        
        remoteObject.HasTeam.addEventListener("result",HasTeamHandler);
        
        remoteObject.HealInjury.addEventListener("result",HealInjuryHandler);
        
        remoteObject.IsNameValid.addEventListener("result",IsNameValidHandler);
        
        remoteObject.OnError.addEventListener("result",OnErrorHandler);
        
        remoteObject.OnLiked.addEventListener("result",OnLikedHandler);
        
        remoteObject.RefreshGroupForTeam.addEventListener("result",RefreshGroupForTeamHandler);
        
        remoteObject.RefreshMatchStatsForTeam.addEventListener("result",RefreshMatchStatsForTeamHandler);
        
        remoteObject.RefreshRankingPage.addEventListener("result",RefreshRankingPageHandler);
        
        remoteObject.RefreshSeasonEndDateRemainingSeconds.addEventListener("result",RefreshSeasonEndDateRemainingSecondsHandler);
        
        remoteObject.RefreshSpecialTrainingDefinitions.addEventListener("result",RefreshSpecialTrainingDefinitionsHandler);
        
        remoteObject.RefreshTeam.addEventListener("result",RefreshTeamHandler);
        
        remoteObject.RefreshTeamDetails.addEventListener("result",RefreshTeamDetailsHandler);
        
        remoteObject.RefreshTeamPurchaseInitialInfo.addEventListener("result",RefreshTeamPurchaseInitialInfoHandler);
        
        remoteObject.RefreshTrainingDefinitions.addEventListener("result",RefreshTrainingDefinitionsHandler);
        
        remoteObject.SwapFormationPosition.addEventListener("result",SwapFormationPositionHandler);
        
        remoteObject.TargetProcessedRequests.addEventListener("result",TargetProcessedRequestsHandler);
        
        remoteObject.Train.addEventListener("result",TrainHandler);
        
        remoteObject.TrainSpecial.addEventListener("result",TrainSpecialHandler);
        
        remoteObject.addEventListener("fault", onFault);
        
        if( model == null )
            model = new MainServiceModel();
    
        this.model = model;

      }
      
      public function setCredentials( userid:String, password:String ):void
      {
        remoteObject.setCredentials( userid, password );
      }

      public function GetModel():MainServiceModel
      {
        return this.model;
      }


    
      public function AssignSkillPoints(soccerPlayerID:int,weight:int,sliding:int,power:int, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.AssignSkillPoints(soccerPlayerID,weight,sliding,power);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function ChangeFormation(newFormationName:String, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.ChangeFormation(newFormationName);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function ChangeName(newName:String, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.ChangeName(newName);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function CreateRequests(requestID:String,targets:ArrayCollection, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.CreateRequests(requestID,targets);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function CreateTeam(name:String,predefinedTeamNameID:String, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.CreateTeam(name,predefinedTeamNameID);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function GetExtraRewardForMatch(matchID:int, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.GetExtraRewardForMatch(matchID);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function GetItemForSale(orderInfoFromClient_itemID:String, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.GetItemForSale(orderInfoFromClient_itemID);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function HasTeam( responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.HasTeam();
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function HealInjury(soccerPlayerID:int, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.HealInjury(soccerPlayerID);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function IsNameValid(name:String, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.IsNameValid(name);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function OnError(msg:String, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.OnError(msg);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function OnLiked( responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.OnLiked();
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function RefreshGroupForTeam(facebookID:Number, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.RefreshGroupForTeam(facebookID);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function RefreshMatchStatsForTeam(facebookID:Number, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.RefreshMatchStatsForTeam(facebookID);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function RefreshRankingPage(pageIndex:int, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.RefreshRankingPage(pageIndex);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function RefreshSeasonEndDateRemainingSeconds( responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.RefreshSeasonEndDateRemainingSeconds();
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function RefreshSpecialTrainingDefinitions( responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.RefreshSpecialTrainingDefinitions();
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function RefreshTeam( responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.RefreshTeam();
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function RefreshTeamDetails(facebookID:Number, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.RefreshTeamDetails(facebookID);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function RefreshTeamPurchaseInitialInfo( responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.RefreshTeamPurchaseInitialInfo();
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function RefreshTrainingDefinitions( responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.RefreshTrainingDefinitions();
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function SwapFormationPosition(firstSoccerPlayerID:int,secondSoccerPlayerID:int, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.SwapFormationPosition(firstSoccerPlayerID,secondSoccerPlayerID);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function TargetProcessedRequests(request_ids:ArrayCollection, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.TargetProcessedRequests(request_ids);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function Train(trainingName:String, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.Train(trainingName);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
    
      public function TrainSpecial(specialTrainingDefinitionID:int, responder:IResponder = null ):void
      {
        var asyncToken:AsyncToken = remoteObject.TrainSpecial(specialTrainingDefinitionID);
        
        if( responder != null )
            asyncToken.addResponder( responder );

      }
         
      public virtual function AssignSkillPointsHandler(event:ResultEvent):void
      {
        
      }
         
      public virtual function ChangeFormationHandler(event:ResultEvent):void
      {
        
      }
         
      public virtual function ChangeNameHandler(event:ResultEvent):void
      {
        
          var returnValue:String = event.result as String;
          model.ChangeNameResult = returnValue;
        
      }
         
      public virtual function CreateRequestsHandler(event:ResultEvent):void
      {
        
      }
         
      public virtual function CreateTeamHandler(event:ResultEvent):void
      {
        
          var returnValue:Boolean = event.result as Boolean;
          model.CreateTeamResult = returnValue;
        
      }
         
      public virtual function GetExtraRewardForMatchHandler(event:ResultEvent):void
      {
        
          var returnValue:Boolean = event.result as Boolean;
          model.GetExtraRewardForMatchResult = returnValue;
        
      }
         
      public virtual function GetItemForSaleHandler(event:ResultEvent):void
      {
        
          var returnValue:ItemForSale = event.result as ItemForSale;
          model.GetItemForSaleResult = returnValue;
        
      }
         
      public virtual function HasTeamHandler(event:ResultEvent):void
      {
        
          var returnValue:Boolean = event.result as Boolean;
          model.HasTeamResult = returnValue;
        
      }
         
      public virtual function HealInjuryHandler(event:ResultEvent):void
      {
        
          var returnValue:Boolean = event.result as Boolean;
          model.HealInjuryResult = returnValue;
        
      }
         
      public virtual function IsNameValidHandler(event:ResultEvent):void
      {
        
          var returnValue:String = event.result as String;
          model.IsNameValidResult = returnValue;
        
      }
         
      public virtual function OnErrorHandler(event:ResultEvent):void
      {
        
      }
         
      public virtual function OnLikedHandler(event:ResultEvent):void
      {
        
          var returnValue:int = event.result as int;
          model.OnLikedResult = returnValue;
        
      }
         
      public virtual function RefreshGroupForTeamHandler(event:ResultEvent):void
      {
        
          var returnValue:CompetitionGroup = event.result as CompetitionGroup;
          model.RefreshGroupForTeamResult = returnValue;
        
      }
         
      public virtual function RefreshMatchStatsForTeamHandler(event:ResultEvent):void
      {
        
          var returnValue:TeamMatchStats = event.result as TeamMatchStats;
          model.RefreshMatchStatsForTeamResult = returnValue;
        
      }
         
      public virtual function RefreshRankingPageHandler(event:ResultEvent):void
      {
        
          var returnValue:RankingPage = event.result as RankingPage;
          model.RefreshRankingPageResult = returnValue;
        
      }
         
      public virtual function RefreshSeasonEndDateRemainingSecondsHandler(event:ResultEvent):void
      {
        
          var returnValue:int = event.result as int;
          model.RefreshSeasonEndDateRemainingSecondsResult = returnValue;
        
      }
         
      public virtual function RefreshSpecialTrainingDefinitionsHandler(event:ResultEvent):void
      {
        
          var returnValue:ArrayCollection = event.result as ArrayCollection;
          model.RefreshSpecialTrainingDefinitionsResult = returnValue;
        
      }
         
      public virtual function RefreshTeamHandler(event:ResultEvent):void
      {
        
          var returnValue:Team = event.result as Team;
          model.RefreshTeamResult = returnValue;
        
      }
         
      public virtual function RefreshTeamDetailsHandler(event:ResultEvent):void
      {
        
          var returnValue:TeamDetails = event.result as TeamDetails;
          model.RefreshTeamDetailsResult = returnValue;
        
      }
         
      public virtual function RefreshTeamPurchaseInitialInfoHandler(event:ResultEvent):void
      {
        
          var returnValue:TeamPurchaseInitialInfo = event.result as TeamPurchaseInitialInfo;
          model.RefreshTeamPurchaseInitialInfoResult = returnValue;
        
      }
         
      public virtual function RefreshTrainingDefinitionsHandler(event:ResultEvent):void
      {
        
          var returnValue:ArrayCollection = event.result as ArrayCollection;
          model.RefreshTrainingDefinitionsResult = returnValue;
        
      }
         
      public virtual function SwapFormationPositionHandler(event:ResultEvent):void
      {
        
      }
         
      public virtual function TargetProcessedRequestsHandler(event:ResultEvent):void
      {
        
          var returnValue:ArrayCollection = event.result as ArrayCollection;
          model.TargetProcessedRequestsResult = returnValue;
        
      }
         
      public virtual function TrainHandler(event:ResultEvent):void
      {
        
          var returnValue:PendingTraining = event.result as PendingTraining;
          model.TrainResult = returnValue;
        
      }
         
      public virtual function TrainSpecialHandler(event:ResultEvent):void
      {
        
      }
    
      public function onFault (event:FaultEvent):void
      {
        //Alert.show(event.fault.faultString, "Error");
      }
    }
  } 
  